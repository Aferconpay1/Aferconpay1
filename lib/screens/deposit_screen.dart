import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../services/firestore_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/primary_button.dart';
import '../utils/validators.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      final isValid = _formKey.currentState?.validate() ?? false;
      if (_isFormValid != isValid) {
        setState(() {
          _isFormValid = isValid;
        });
      }
    });
  }

  Future<void> _generateReference() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final firestoreService = context.read<FirestoreService>();

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      final reference = await firestoreService.createDepositRequest(amount: amount);

      if (!mounted) return;
      context.push(
        '/deposit-confirmation',
        extra: {
          'amount': amount,
          'reference': reference,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar referência: ${e.toString().replaceAll("Exception: ", "")}'), 
          backgroundColor: Theme.of(context).colorScheme.error
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

 @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AbsorbPointer(
      absorbing: _isLoading,
      child: Stack(
        children: [
          Scaffold(
            appBar: const GradientAppBar(
              title: Text('Depositar Dinheiro'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Insira o montante que deseja carregar na sua conta.',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(labelText: 'Montante a Depositar (Kz)', prefixIcon: Icon(Iconsax.money_recive)),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                      validator: Validators.validateAmount,
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
                    const SizedBox(height: 40),
                    PrimaryButton(
                      text: 'Gerar Referência',
                      onPressed: _isFormValid ? _generateReference : null,
                      icon: Iconsax.document_code,
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                     const SizedBox(height: 24),
                    _buildInfoPanel(theme),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withAlpha(80)),
      ),
      color: theme.colorScheme.surface.withAlpha(150),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Iconsax.information, color: theme.colorScheme.secondary, size: 28),
            const SizedBox(height: 12),
            Text(
              'Após gerar a referência, deverá fazer uma transferência bancária para o IBAN da Afercon Pay e enviar o comprovativo para o nosso WhatsApp.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}
