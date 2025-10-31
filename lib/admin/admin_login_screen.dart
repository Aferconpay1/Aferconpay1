import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/auth_service.dart';
import '../main.dart';
import '../widgets/support_fab.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _email = '';
  String _password = '';

  void _trySubmit() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (isValid) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        await Provider.of<AuthService>(context, listen: false).signInWithEmailPassword(_email, _password);
        // A navegação é gerida pelo AuthWrapper
      } catch (err) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(err.toString().replaceAll('Exception: ', '')), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: const SupportFab(),
      body: Stack(
        children: [
          _buildBackground(theme, isDarkMode),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 32),
                  _buildAuthCard(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(ThemeData theme, bool isDarkMode) {
    return ClipPath(
      clipper: _AdminWaveClipper(),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withAlpha(isDarkMode ? 180 : 255),
              theme.colorScheme.secondary.withAlpha(isDarkMode ? 220 : 255),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        const Icon(Iconsax.security_user, size: 80, color: AppColors.primaryGreen),
        const SizedBox(height: 16),
        Text(
          'Acesso Restrito',
          style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Exclusivo para administradores',
          style: theme.textTheme.titleMedium,
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildAuthCard(ThemeData theme) {
    return Card(
      elevation: 8,
      shadowColor: theme.shadowColor.withAlpha(25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('email'),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email de Admin', prefixIcon: Icon(Iconsax.direct)),
                validator: (value) => (value == null || !value.contains('@')) ? 'Email inválido.' : null,
                onSaved: (value) => _email = value!,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('password'),
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Iconsax.key)),
                validator: (value) => (value == null || value.length < 6) ? 'A senha deve ter pelo menos 6 caracteres.' : null,
                onSaved: (value) => _password = value!,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _trySubmit,
                  child: const Text('Entrar'),
                ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, curve: Curves.easeOutCubic);
  }
}

class _AdminWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.9, size.width * 0.5, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.5, size.width, size.height * 0.6);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
