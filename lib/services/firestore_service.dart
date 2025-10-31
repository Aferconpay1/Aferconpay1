import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'auth_service.dart';
import '../models/loan_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
  final AuthService _authService;

  FirestoreService({required AuthService authService}) : _authService = authService;

  String? get _uid => _authService.currentUser?.uid;

  // --- Funções do PIN de Transação ---

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> hasTransactionPin() async {
    if (_uid == null) return false;
    final doc = await _db.collection('users').doc(_uid).get();
    return doc.exists && doc.data()!.containsKey('transactionPinHash');
  }

  Future<void> setTransactionPin(String pin) async {
    if (_uid == null) throw Exception('Utilizador não autenticado.');
    if (pin.length != 6) throw Exception('O PIN deve ter 6 dígitos.');

    final hashedPin = _hashPin(pin);
    await _db.collection('users').doc(_uid).update({
      'transactionPinHash': hashedPin,
    });
  }

  Future<bool> verifyTransactionPin(String pin) async {
    if (_uid == null) throw Exception('Utilizador não autenticado.');
    if (pin.length != 6) return false;

    final doc = await _db.collection('users').doc(_uid).get();
    if (!doc.exists || !doc.data()!.containsKey('transactionPinHash')) {
      throw Exception('PIN de transação não definido.');
    }

    final storedHash = doc.data()!['transactionPinHash'];
    final hashedPin = _hashPin(pin);

    return storedHash == hashedPin;
  }

  // --- Outros Métodos ---

  Future<void> addFcmToken(String token) async {
    if (_uid == null || token.isEmpty) return;
    await _db.collection('users').doc(_uid).set({
      'fcmTokens': FieldValue.arrayUnion([token])
    }, SetOptions(merge: true));
  }

  Future<void> removeFcmToken(String token) async {
    if (_uid == null || token.isEmpty) return;
    await _db.collection('users').doc(_uid).set({
      'fcmTokens': FieldValue.arrayRemove([token])
    }, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getUser(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  Stream<DocumentSnapshot> get userStream {
    if (_uid == null) return const Stream.empty();
    return _db.collection('users').doc(_uid).snapshots();
  }

  Future<Map<String, dynamic>> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('Utilizador não encontrado.');
    final data = doc.data()!;
    data['uid'] = doc.id;
    return data;
  }

  Future<Map<String, dynamic>?> findRecipient(String identifier) async {
    if (identifier.isEmpty) return null;

    QuerySnapshot query;
    if (identifier.contains('@')) {
      query = await _db.collection('users').where('email', isEqualTo: identifier).limit(1).get();
    } else {
      query = await _db.collection('users').where('phoneNumber', isEqualTo: identifier).limit(1).get();
    }

    if (query.docs.isEmpty) {
      return null;
    }

    final recipientDoc = query.docs.first;
    return {
      'uid': recipientDoc.id,
      'displayName': recipientDoc.get('displayName'),
      'email': recipientDoc.get('email'),
    };
  }

  Stream<QuerySnapshot> get transactionsStream {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(_uid)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  Stream<QuerySnapshot> get notificationsStream {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    if (_uid == null) throw Exception('Usuário não autenticado para atualizar dados.');
    await _db.collection('users').doc(_uid).set(data, SetOptions(merge: true));
  }

  Future<void> markNotificationAsRead(String notificationId) async {
     if (_uid == null) throw Exception('Usuário não autenticado.');
     await _db.collection('users').doc(_uid).collection('notifications').doc(notificationId).update({'isRead': true});
  }

  Future<String> createDepositRequest({required double amount}) async {
    if (_uid == null) throw Exception('Utilizador não autenticado.');
    if (amount <= 0) throw Exception('O montante a depositar deve ser positivo.');

    final userDoc = await _db.collection('users').doc(_uid).get();
    if (!userDoc.exists) throw Exception('Utilizador não encontrado.');
    final userName = (userDoc.data() as Map<String, dynamic>)['displayName'] ?? 'Nome não encontrado';

    final reference = (100000000 + (DateTime.now().millisecondsSinceEpoch % 900000000)).toString();

    await _db.collection('deposit_requests').add({
      'userId': _uid,
      'userName': userName,
      'amount': amount,
      'reference': reference,
      'requestDate': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    return reference;
  }

  Future<void> submitWithdrawalRequest({required double amount, required String fullName, required String iban}) async {
    if (_uid == null) throw Exception('Utilizador não autenticado.');
    if (amount <= 0) throw Exception('O montante do levantamento deve ser positivo.');

    final callable = _functions.httpsCallable('createWithdrawalRequest');
    try {
      await callable.call({
        'amount': amount,
        'fullName': fullName,
        'iban': iban,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Ocorreu um erro ao submeter o pedido de levantamento.');
    } catch (e) {
      throw Exception('Ocorreu um erro inesperado. Tente novamente.');
    }
  }

  Future<void> submitCreditRequest({required double creditAmount, required String reason}) async {
    if (_uid == null) throw Exception('Utilizador não autenticado.');
    if (creditAmount <= 0) throw Exception('O montante do crédito deve ser positivo.');

    final callable = _functions.httpsCallable('requestCredit');
    try {
      await callable.call({
        'creditAmount': creditAmount,
        'reason': reason,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Ocorreu um erro ao submeter o pedido de crédito.');
    } catch (e) {
      throw Exception('Ocorreu um erro inesperado. Tente novamente mais tarde.');
    }
  }

  Stream<QuerySnapshot> getCreditRequestsStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('credit_requests')
        .where('userId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getPendingLoanRequests() {
    return _db
        .collection('loans')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots();
  }

  Future<void> approveLoan(String loanId, String userId, double amount) async {
    final loanRef = _db.collection('loans').doc(loanId);
    final userRef = _db.collection('users').doc(userId);
    final userTransactionRef = userRef.collection('transactions').doc();

    await _db.runTransaction((transaction) async {
      final loanSnapshot = await transaction.get(loanRef);
      final userSnapshot = await transaction.get(userRef);

      if (!loanSnapshot.exists) throw Exception('Pedido de crédito não encontrado.');
      if (!userSnapshot.exists) throw Exception('Utilizador associado ao crédito não foi encontrado.');

      transaction.update(loanRef, {
        'status': LoanStatus.approved.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final currentBalance = (userSnapshot.data()!['balance'] ?? 0.0).toDouble();
      transaction.update(userRef, {'balance': currentBalance + amount});

      transaction.set(userTransactionRef, {
        'amount': amount,
        'description': 'Crédito Aprovado',
        'type': 'credit',
        'timestamp': FieldValue.serverTimestamp(),
        'relatedUserId': 'system',
      });
    });
  }

    Future<void> rejectLoan(String loanId) async {
    final loanRef = _db.collection('loans').doc(loanId);
    await loanRef.update({
      'status': LoanStatus.rejected.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> processPayment(String recipientId, double amount) async {
    if (_uid == null) throw Exception('Utilizador não autenticado.');
    if (amount <= 0) throw Exception('O montante deve ser positivo.');

    final callable = _functions.httpsCallable('processQrTransaction');
    try {
      await callable.call({
        'recipientId': recipientId,
        'amount': amount,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Erro ao processar pagamento: ${e.message}');
    }
  }

  Future<void> transferFunds(String recipientId, double amount, String note) async {
    if (_uid == null) throw Exception('Utilizador não autenticado.');
    if (amount <= 0) throw Exception('O montante deve ser positivo.');

    final callable = _functions.httpsCallable('transferFunds');
    try {
      await callable.call({
        'recipientId': recipientId,
        'amount': amount,
        'note': note,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Erro na transferência: ${e.message}');
    }
  }

  Stream<QuerySnapshot> getPendingDepositRequests() {
    return _db
        .collection('deposit_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestDate', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getPendingWithdrawalRequests() {
    return _db
        .collection('withdrawal_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestDate', descending: true)
        .snapshots();
  }

  Future<void> approveDeposit(String requestId, String userId, double amount) async {
    final userRef = _db.collection('users').doc(userId);
    final requestRef = _db.collection('deposit_requests').doc(requestId);

    await _db.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      if (!userSnapshot.exists) throw Exception('User not found');
      final currentBalance = (userSnapshot.data()!['balance'] ?? 0.0).toDouble();
      transaction.update(userRef, {'balance': currentBalance + amount});
      transaction.update(requestRef, {'status': 'approved', 'processedDate': FieldValue.serverTimestamp()});
    });
  }

  Future<void> rejectDeposit(String requestId, String userId) async {
    final requestRef = _db.collection('deposit_requests').doc(requestId);
    await requestRef.update({'status': 'rejected', 'processedDate': FieldValue.serverTimestamp()});
  }

  Future<void> markWithdrawalAsCompleted(String requestId, String userId, double amount) async {
    final requestRef = _db.collection('withdrawal_requests').doc(requestId);
    await requestRef.update({'status': 'completed', 'processedDate': FieldValue.serverTimestamp()});
  }

  Future<int> getUsersCount() async {
    final aggregateQuery = _db.collection('users').count();
    final aggregateSnapshot = await aggregateQuery.get();
    return aggregateSnapshot.count ?? 0;
  }

  Future<int> getTotalTransactionsCount() async {
    final snapshot = await _db.collectionGroup('transactions').get();
    return snapshot.size;
  }

  Future<double> getTotalVolume() async {
     final snapshot = await _db.collectionGroup('transactions').get();
    if (snapshot.docs.isEmpty) return 0.0;

    double total = 0.0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return total / 2;
  }

  Future<Map<DateTime, double>> getDailyTransactionVolume({int days = 30}) async {
    Map<DateTime, double> dailyVolume = {};
    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      dailyVolume[date] = 0.0;
    }

    final startPeriod = now.subtract(Duration(days: days));
    final snapshot = await _db
        .collectionGroup('transactions')
        .where('timestamp', isGreaterThanOrEqualTo: startPeriod)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final timestamp = (data['timestamp'] as Timestamp).toDate();
      final amount = (data['amount'] as num).toDouble();
      final day = DateTime(timestamp.year, timestamp.month, timestamp.day);

      if (dailyVolume.containsKey(day)) {
        dailyVolume[day] = (dailyVolume[day] ?? 0.0) + amount;
      }
    }
    dailyVolume.updateAll((key, value) => value / 2);
    return dailyVolume;
  }

  Future<Map<String, int>> getTransactionDistribution() async {
    final snapshot = await _db.collectionGroup('transactions').get();
    if (snapshot.docs.isEmpty) {
      return {'credit': 0, 'debit': 0};
    }

    int creditCount = 0;
    int debitCount = 0;
    for (var doc in snapshot.docs) {
      final type = doc.data()['type'] as String?;
      if (type == 'credit') {
        creditCount++;
      } else if (type == 'debit') {
        debitCount++;
      }
    }
    return {'credit': creditCount, 'debit': debitCount};
  }
}
