import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/auth_service.dart';
import '../main.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  bool _canResendEmail = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Start a timer to automatically check for email verification status
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      // This check will trigger the redirect in main.dart if the status changes
      context.read<AuthService>().checkVerificationStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    if (!_canResendEmail || _isSending) return;

    setState(() {
      _isSending = true;
      _canResendEmail = false;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    const successColor = AppColors.primaryGreen;

    try {
      await context.read<AuthService>().resendVerificationEmail();
      scaffoldMessenger.showSnackBar(
        // ignore: prefer_const_constructors
        SnackBar(
          content: const Text('Um novo e-mail de verificação foi enviado!'),
          backgroundColor: successColor,
        ),
      );
      // Prevent spamming the resend button
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted) {
          setState(() => _canResendEmail = true);
        }
      });
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: errorColor,
        ),
      );
      if (mounted) {
        setState(() => _canResendEmail = true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifique o seu E-mail'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Iconsax.verify,
                size: 100,
                color: AppColors.primaryGreen,
              ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 32),
              Text(
                'Confirme o seu E-mail',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Enviámos um link de verificação para o seu endereço de e-mail. Por favor, clique nesse link para ativar a sua conta.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: _isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Iconsax.send_1),
                label: Text(_isSending ? 'A Enviar...' : 'Reenviar E-mail'),
                onPressed: _resendEmail,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
              const SizedBox(height: 16),
              TextButton.icon(
                 icon: const Icon(Iconsax.logout),
                label: const Text('Voltar ao Login (Cancelar)'),
                onPressed: () => authService.signOut(),
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              ),
               const SizedBox(height: 40),
              const Row(
                children: [
                  Icon(Iconsax.timer_1, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta página irá atualizar-se automaticamente assim que a verificação for concluída.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
