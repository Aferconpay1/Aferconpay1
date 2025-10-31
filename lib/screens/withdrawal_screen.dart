
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/primary_button.dart';
import '../utils/validators.dart';
import '../screens/pin/set_pin_screen.dart';
import '../widgets/pin_verification_dialog.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _ibanController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isFormValid = false;
  bool _isLoading = false;
  bool _hasSufficientBalance = true;
  double _currentBalance = 0.0;
  double _amount = 0.0;
  double _fee = 0.0;
  double _total = 0.0;
  final _currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 2);
  final double _withdrawalFeePercentage = 0.10; // 10% fee

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onFormChanged);
    _ibanController.addListener(_onFormChanged);
    _nameController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (_isLoading) return;

    setState(() {
      _amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
      if (_amount > 0) {
        _fee = _amount * _withdrawalFeePercentage;
        _total = _amount + _fee;
      } else {
        _fee = 0.0;
        _total = 0.0;
      }
      _hasSufficientBalance = _total <= _currentBalance;
    });

    final isValid = (_formKey.currentState?.validate() ?? false) && _hasSufficientBalance;
    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _showConfirmationDialog() {
    if (!(_formKey.currentState?.validate() ?? false) || !_hasSufficientBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor, preencha todos os campos corretamente e garanta que tem saldo suficiente.')),
        );
        return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar Levantamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirme os detalhes do seu pedido de levantamento:'),
            const SizedBox(height: 20),
             _buildConfirmationRow('Nome do Titular:', _nameController.text),
            _buildConfirmationRow('IBAN:', 'AO06${_ibanController.text}'),
            const Divider(height: 24),
            _buildConfirmationRow('Montante a levantar:', _currencyFormat.format(_amount)),
            _buildConfirmationRow('Taxa de Serviço (10%):', _currencyFormat.format(_fee)),
            _buildConfirmationRow('Total a Debitar:', _currencyFormat.format(_total), isTotal: true),
            if (!_hasSufficientBalance)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Saldo insuficiente', 
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (context.mounted) Navigator.of(context).pop();
              _initiateSecureWithdrawal();
            },
            child: const Text('Confirmar Pedido'),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateSecureWithdrawal() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    final hasPin = await firestoreService.hasTransactionPin();
    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (!hasPin) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Por favor, defina um PIN de transação primeiro.'),
          backgroundColor: Colors.orange,
        ),
      );
      navigator.push(MaterialPageRoute(builder: (context) => const SetPinScreen()));
      return;
    }

    final pinVerified = await showPinVerificationDialog(context);
    if (!mounted) return;
    
    if (pinVerified == true) {
      await _processWithdrawal();
    }
  }

  Future<void> _processWithdrawal() async {
    if (!(_formKey.currentState?.validate() ?? false) || !_hasSufficientBalance) {
        return;
    }

    setState(() => _isLoading = true);

    try {
      final firestoreService = context.read<FirestoreService>();
      
      await firestoreService.submitWithdrawalRequest(
        amount: _amount,
        fullName: _nameController.text,
        iban: 'AO06${_ibanController.text}',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido de levantamento enviado com sucesso! Será processado em breve.'), backgroundColor: Colors.green),
      );
      context.pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")),
         backgroundColor: Theme.of(context).colorScheme.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildConfirmationRow(String label, String value, {bool isTotal = false}) {
    final theme = Theme.of(context);
    final valueStyle = isTotal 
        ? theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)
        : theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 16),
          Flexible(child: Text(value, style: valueStyle, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _ibanController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final user = Provider.of<UserModel?>(context);
    if (user != null && _currentBalance == 0.0) {
      _currentBalance = user.balance;
      _nameController.text = user.displayName;
    }

    return AbsorbPointer(
      absorbing: _isLoading,
      child: Stack(
        children: [
          Scaffold(
            appBar: const GradientAppBar(
              title: Text('Levantar Dinheiro'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Text(
                        'Saldo disponível: ${_currencyFormat.format(_currentBalance)}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                    ),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nome Completo do Titular', prefixIcon: Icon(Iconsax.user)),
                      validator: (value) => value == null || value.isEmpty ? 'Insira o nome completo.' : null,
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _ibanController,
                      decoration: const InputDecoration(
                        labelText: 'IBAN',
                        prefixText: 'AO06 ',
                        prefixIcon: Icon(Iconsax.card),
                        counterText: "",
                      ),
                      maxLength: 21,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Insira o IBAN.';
                        }
                        if (value.length != 21) {
                          return 'O IBAN deve conter exatamente 21 dígitos.';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(labelText: 'Montante a Levantar (Kz)', prefixIcon: Icon(Iconsax.money_send)),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                      validator: Validators.validateAmount,
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),

                    const SizedBox(height: 24),
                    
                    if (_amount > 0)
                      Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainer,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildConfirmationRow('Montante do Levantamento:', _currencyFormat.format(_amount)),
                              const SizedBox(height: 8),
                              _buildConfirmationRow('Taxa de Serviço (10%):', _currencyFormat.format(_fee)),
                              const Divider(height: 20),
                              _buildConfirmationRow('Total a Debitar:', _currencyFormat.format(_total), isTotal: true),
                              if (!_hasSufficientBalance && _amount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Text(
                                    'Saldo insuficiente para esta operação',
                                    style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                                  ),
                                ).animate().shake(hz: 8, duration: 200.ms),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1),

                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Rever & Confirmar',
                      onPressed: _isFormValid ? _showConfirmationDialog : null,
                      icon: Iconsax.send_2,
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
