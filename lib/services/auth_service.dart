import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import './secure_storage_service.dart';
import './notification_service.dart';
import './firestore_service.dart';
import 'dart:developer' as developer;

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  emailNotVerified,
}

class EmailNotVerifiedException implements Exception {
  final String message;
  EmailNotVerifiedException(this.message);
  @override
  String toString() => message;
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;
  final SecureStorageService _storageService;
  late final FirestoreService _firestoreService;

  User? _user;
  bool _isAdmin = false;
  AuthStatus _status = AuthStatus.uninitialized;
  String? _lastEmail;
  String? _lastPassword;
  bool _isLoading = false;
  bool _isInitialAuthCheck = true;

  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
    SecureStorageService? storageService,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService ?? NotificationService(),
        _storageService = storageService ?? SecureStorageService() {
    _firestoreService = FirestoreService(authService: this);
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
  if (kIsWeb) {
    await _onAuthStateChanged(_auth.currentUser);
  } else {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isLoggedIn') ?? false) {
      _status = AuthStatus.authenticated;
      notifyListeners();
      await _onAuthStateChanged(_auth.currentUser);
    } else {
      await _onAuthStateChanged(null);
    }
  }
}

  User? get currentUser => _user;
  bool get isAdmin => _isAdmin;
  AuthStatus get status => _status;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (_isInitialAuthCheck) {
      setLoading(true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      if (user == null) {
        _user = null;
        _isAdmin = false;
        _status = AuthStatus.unauthenticated;
        await prefs.setBool('isLoggedIn', false);
      } else {
        await user.reload();
        final freshUser = _auth.currentUser;

        if (freshUser == null) {
          _user = null;
          _isAdmin = false;
          _status = AuthStatus.unauthenticated;
          await prefs.setBool('isLoggedIn', false);
        } else if (!freshUser.emailVerified) {
          _user = freshUser;
          _isAdmin = false;
          _status = AuthStatus.emailNotVerified;
           await prefs.setBool('isLoggedIn', false);
        } else {
          _user = freshUser;
          final doc = await _firestore.collection('users').doc(freshUser.uid).get();
          _isAdmin = doc.data()?['isAdmin'] == true;

          if (!_isAdmin) {
            await _notificationService.init();
          }

          if (_lastEmail != null && _lastPassword != null) {
            await _storageService.saveCredentials(_lastEmail!, _lastPassword!);
            final token = await _notificationService.getFCMToken();
            if (token != null) {
              await _firestoreService.addFcmToken(token);
            }
            _lastEmail = null;
            _lastPassword = null;
          }
          _status = AuthStatus.authenticated;
          await prefs.setBool('isLoggedIn', true);
        }
      }
    } catch (e, s) {
        developer.log(
            'Error in _onAuthStateChanged', 
            error: e, 
            stackTrace: s, 
            name: 'AuthService'
        );
        _user = null;
        _isAdmin = false;
        _status = AuthStatus.unauthenticated;
    } finally {
        if (_isInitialAuthCheck) {
          setLoading(false);
          _isInitialAuthCheck = false;
        }
        notifyListeners();
    }
  }

  Future<void> checkVerificationStatus() async {
    final user = _auth.currentUser;
    if (user == null || _status == AuthStatus.authenticated) return;

    try {
        await user.reload();
        final freshUser = _auth.currentUser;

        if (freshUser != null && freshUser.emailVerified && _status == AuthStatus.emailNotVerified) {
            developer.log('Email has been verified. Updating auth status.', name: 'AuthService');
            await _onAuthStateChanged(freshUser);
        }
    } catch(e, s) {
        developer.log(
            'Error during checkVerificationStatus', 
            name: 'AuthService', 
            error: e,
            stackTrace: s
        );
    }
  }

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'Utilizador não encontrado. Por favor, faça o login novamente.';
    }
    if (user.emailVerified) {
      throw 'O seu e-mail já foi verificado.';
    }

    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        throw 'Foi enviado um e-mail recentemente. Por favor, aguarde alguns minutos antes de tentar novamente.';
      }
      throw 'Ocorreu um erro ao reenviar o e-mail.';
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      _lastEmail = email;
      _lastPassword = password;
      
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      if (_status == AuthStatus.emailNotVerified) {
         throw EmailNotVerifiedException('Por favor, verifique o seu e-mail.');
      }

    } on FirebaseAuthException catch (e) {
      _lastEmail = null;
      _lastPassword = null;
      developer.log(
        'Firebase auth error: ${e.code}',
        name: 'AuthService.signIn',
        error: e,
      );
      throw Exception(_mapAuthError(e.code));
    } catch (e) {
       _lastEmail = null;
       _lastPassword = null;
       rethrow;
    }
  }

  Future<void> signInAsAdmin(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (doc.data()?['isAdmin'] != true) {
        await _auth.signOut();
        throw Exception('Este utilizador não tem permissões de administrador.');
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUpWithEmailPassword(
    String email,
    String password,
    String fullName,
    String phoneNumber,
    String dob,
    String country,
    String province,
  ) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception("A criação do utilizador falhou.");
      
      _lastEmail = email; 
      await user.sendEmailVerification();

      final token = await _notificationService.getFCMToken();

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'displayName': fullName,
        'phoneNumber': phoneNumber,
        'dob': dob,
        'country': country,
        'province': province,
        'balance': 0.0,
        'createdAt': Timestamp.now(),
        'isAdmin': false,
        'fcmTokens': token != null ? [token] : [],
      });

      await user.updateDisplayName(fullName);

    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  Future<void> signOut() async {
    final token = await _notificationService.getFCMToken();
    if (token != null && _user != null) {
      await _firestoreService.removeFcmToken(token);
    }
    await _storageService.deleteCredentials();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    _lastEmail = null;
    _lastPassword = null;
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'user-not-found') {
        throw Exception(_mapAuthError(e.code));
      }
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Nenhum utilizador autenticado.');

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    try {
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      await _storageService.saveCredentials(user.email!, newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'O formato do e-mail é inválido.';
      case 'user-not-found':
        return 'Nenhum utilizador encontrado com este e-mail.';
      case 'wrong-password':
        return 'A palavra-passe está incorreta.';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso.';
      case 'weak-password':
        return 'A palavra-passe é muito fraca. Tente uma mais forte.';
      case 'requires-recent-login':
        return 'Esta operação é sensível e requer autenticação recente. Por favor, faça o login novamente antes de tentar.';
      case 'invalid-credential':
         return 'As credenciais fornecidas são inválidas ou o e-mail não foi verificado.';
      default:
        return 'Ocorreu um erro de autenticação. Por favor, verifique as suas credenciais.';
    }
  }
}
