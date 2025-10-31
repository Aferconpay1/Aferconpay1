
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/pdf_export_service.dart';
import 'services/secure_storage_service.dart';
import 'providers/notification_provider.dart';
import 'models/user_model.dart';
import 'widgets/main_scaffold.dart';

// Screens
import 'auth/auth_screen.dart';
import 'auth/reset_password_screen.dart';
import 'auth/verify_email_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/receive_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/deposit_screen.dart';
import 'screens/deposit_confirmation_screen.dart';
import 'screens/withdrawal_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/transfer_screen.dart';
import 'screens/credit_center_screen.dart';
import 'screens/payment_confirmation_screen.dart';
import 'admin/admin_login_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/terms_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/faq_screen.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
    await NotificationService().init();

    runApp(const AferconPayApp());
  } catch (e) {
    runApp(StartupErrorScreen(errorMessage: e.toString()));
  }
}

class AppColors {
  static const Color primaryGreen = Color(0xFF2ECC71);
  static const Color secondaryBlue = Color(0xFF3498DB);
  static const Color darkText = Color(0xFF1C1C1C);
  static const Color lightGrayBackground = Color(0xFFF4F6F7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1C1C1C);
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class AferconPayApp extends StatelessWidget {
  const AferconPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => SecureStorageService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ProxyProvider<AuthService, FirestoreService>(
          update: (context, authService, previous) => FirestoreService(authService: authService),
        ),
        StreamProvider<UserModel?>(
          create: (context) => context.read<FirestoreService>().userStream.map((snapshot) {
            return snapshot.exists ? UserModel.fromFirestore(snapshot) : null;
          }),
          initialData: null,
        ),
        ChangeNotifierProxyProvider<FirestoreService, NotificationProvider>(
          create: (context) => NotificationProvider(Provider.of<FirestoreService>(context, listen: false)),
          update: (context, firestoreService, previous) => NotificationProvider(firestoreService),
        ),
        ProxyProvider<FirestoreService, PdfExportService>(
          update: (context, firestoreService, previous) => PdfExportService(firestoreService: firestoreService),
        ),
      ],
      child: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    if (authService.status == AuthStatus.uninitialized) {
      return const MaterialApp(
        home: SplashScreen(),
        debugShowCheckedModeBanner: false,
      );
    }

    return const MainAppRouter();
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
            child: Container(
              color: Colors.black.withAlpha((255 * 0.2).round()),
              child: const Center(
                child: CircularProgressIndicator(
                   valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                   strokeWidth: 5.0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class MainAppRouter extends StatelessWidget {
  const MainAppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final GoRouter router = GoRouter(
      refreshListenable: authService,
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
        GoRoute(path: '/reset-password', builder: (context, state) => const ResetPasswordScreen()),
        GoRoute(path: '/verify-email', builder: (context, state) => const VerifyEmailScreen()),
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        GoRoute(path: '/receive', builder: (context, state) => const ReceiveScreen()),
        GoRoute(path: '/scan', builder: (context, state) => const ScanScreen()),
        GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
        GoRoute(path: '/deposit', builder: (context, state) => const DepositScreen()),
        GoRoute(
          path: '/deposit-confirmation',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return DepositConfirmationScreen(amount: extra['amount'], reference: extra['reference']);
          },
        ),
        GoRoute(path: '/withdraw', builder: (context, state) => const WithdrawalScreen()),
        GoRoute(path: '/change-password', builder: (context, state) => const ChangePasswordScreen()),
        GoRoute(path: '/transfer', builder: (context, state) => const TransferScreen()),
        GoRoute(path: '/credit-center', builder: (context, state) => const CreditCenterScreen()),
        GoRoute(path: '/terms', builder: (context, state) => const TermsScreen()),
        GoRoute(path: '/privacy-policy', builder: (context, state) => const PrivacyPolicyScreen()),
        GoRoute(path: '/faq', builder: (context, state) => const FaqScreen()),
        GoRoute(
          path: '/payment-confirmation',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return PaymentConfirmationScreen(recipientData: extra['recipientData'], amount: extra['amount']);
          },
        ),
        GoRoute(path: '/admin/login', builder: (context, state) => const AdminLoginScreen()),
        GoRoute(path: '/admin/dashboard', builder: (context, state) => const AdminPanelScreen()),
        ShellRoute(
          builder: (context, state, child) => MainScaffold(child: child),
          routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
            GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
          ],
        ),
      ],
       redirect: (BuildContext context, GoRouterState state) {
        final authStatus = authService.status;
        final location = state.matchedLocation;

        if (authStatus == AuthStatus.uninitialized) {
          return location == '/' ? null : '/';
        }

        final isLoggedIn = authStatus == AuthStatus.authenticated;
        final guestRoutes = ['/auth', '/reset-password', '/admin/login'];
        final isGuestLocation = guestRoutes.contains(location);

        if (authStatus == AuthStatus.emailNotVerified) {
          return location == '/verify-email' ? null : '/verify-email';
        }
        
        if (isLoggedIn) {
          if (location == '/' || isGuestLocation || location == '/verify-email') {
            return '/home';
          }
        } 
        else {
          if (location == '/') {
            return '/auth';
          }
          if (!isGuestLocation && location != '/verify-email') {
             return '/auth';
          }
        }

        return null;
      },
    );

    final notoSansTextTheme = GoogleFonts.notoSansTextTheme(
      ThemeData(brightness: Brightness.light).textTheme,
    ).copyWith(
      titleLarge: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.darkText),
      bodyMedium: GoogleFonts.notoSans(fontWeight: FontWeight.normal, fontSize: 15, color: AppColors.darkText),
      labelLarge: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 18, color: AppColors.white),
      headlineMedium: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.white),
      displayLarge: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 48, color: AppColors.primaryGreen),
    );
    
    final notoSansDarkTextTheme = GoogleFonts.notoSansTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ).copyWith(
      titleLarge: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.white),
      bodyMedium: GoogleFonts.notoSans(fontWeight: FontWeight.normal, fontSize: 15, color: AppColors.lightGrayBackground),
      labelLarge: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 18, color: AppColors.white),
      headlineMedium: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.white),
      displayLarge: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 48, color: AppColors.primaryGreen),
    );

    final lightTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.lightGrayBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primaryGreen,
        onPrimary: AppColors.white,
        secondary: AppColors.secondaryBlue,
        onSecondary: AppColors.white,
        error: Colors.redAccent,
        onError: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.darkText,
      ),
      textTheme: notoSansTextTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        titleTextStyle: notoSansTextTheme.headlineMedium,
        foregroundColor: AppColors.white, 
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryBlue,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 6,
          shadowColor: Colors.black45,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          textStyle: notoSansTextTheme.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.white,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      ),
       inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightGrayBackground),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.secondaryBlue, width: 2),
        ),
        filled: true,
        fillColor: AppColors.white,
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primaryGreen,
        onPrimary: AppColors.white,
        secondary: AppColors.secondaryBlue,
        onSecondary: AppColors.white,
        error: Colors.redAccent,
        onError: AppColors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.lightGrayBackground,
      ),
      textTheme: notoSansDarkTextTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        titleTextStyle: notoSansDarkTextTheme.headlineMedium,
        foregroundColor: AppColors.white,
      ),
      elevatedButtonTheme: lightTheme.elevatedButtonTheme,
      cardTheme: CardThemeData(
        elevation: 6,
        shadowColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.darkSurface,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkSurface),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.secondaryBlue, width: 2),
        ),
        filled: true,
        fillColor: AppColors.darkSurface,
      ),
    );

    return MaterialApp.router(
      title: 'Afercon Pay',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return LoadingOverlay(
          isLoading: context.watch<AuthService>().isLoading,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}


class StartupErrorScreen extends StatelessWidget {
  final String errorMessage;
  const StartupErrorScreen({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Ocorreu um erro crítico ao iniciar a aplicação:\n\n$errorMessage',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
