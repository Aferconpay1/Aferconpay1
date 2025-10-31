import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../main.dart';
import '../auth/auth_screen.dart'; // For the clipper
import '../widgets/support_fab.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _email = '';

  void _trySubmit() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (isValid) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        await Provider.of<AuthService>(context, listen: false).sendPasswordResetEmail(_email);
        
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Email de recuperação enviado! Verifique a sua caixa de entrada.'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        context.pop();

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
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: isDarkMode ? Colors.white : AppColors.darkText),
          ),
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
      clipper: AuthWaveClipper(),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGreen.withAlpha(isDarkMode ? 180 : 255),
              AppColors.secondaryBlue,
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
        Image.asset(
          'assets/afercon.logo.png',
          height: 100, // Adjust height as needed
        ),
        const SizedBox(height: 24),
        Text(
          'Recuperar Senha',
          style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Insira o seu email para receber o link',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
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
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Iconsax.direct)),
                validator: (value) => (value == null || !value.contains('@')) ? 'Email inválido.' : null,
                onSaved: (value) => _email = value!,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _trySubmit,
                  child: const Text('Enviar Email de Recuperação'),
                ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, curve: Curves.easeOutCubic);
  }
}
