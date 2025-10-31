
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../main.dart';
import '../widgets/gradient_app_bar.dart';
import '../screens/pin/set_pin_screen.dart';
import '../widgets/pin_verification_dialog.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> recipientData;
  final double? amount;

  const PaymentConfirmationScreen({
    super.key,
    required this.recipientData,
    this.amount,
  });

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  late final TextEditingController _amountController;
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  double _currentBalance = 0.0;
  bool _hasSufficientBalance = false;
  final _currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.amount != null ? widget.amount!.toStringAsFixed(2) : '',
    );
    _amountController.addListener(_validateBalance);
  }

  void _validateBalance() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    setState(() {
      _hasSufficientBalance = amount > 0 && amount <= _currentBalance;
    });
  }

  Future<void> _processPayment() async {
    _validateBalance();
    if (!_formKey.currentState!.validate() || !_hasSufficientBalance) return;

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);

    final hasPin = await firestoreService.hasTransactionPin();
    if (!mounted) return;

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

    if (pinVerified != true) {
      return;
    }

    setState(() => _isProcessing = true);

    final amount = double.parse(_amountController.text);
    final recipientId = widget.recipientData['uid'];

    try {
      await firestoreService.processPayment(recipientId, amount);

      if (!mounted) return;
      final formattedAmount = NumberFormat('#,##0.00', 'pt_PT').format(amount);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Pagamento de Kz $formattedAmount realizado com sucesso!'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );
      router.go('/home');
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipientName = widget.recipientData['displayName'] ?? 'Utilizador Desconhecido';
    final recipientPhotoUrl = widget.recipientData['photoURL'];

    final user = Provider.of<UserModel?>(context);
    if (user != null) {
        _currentBalance = user.balance;
        _validateBalance();
    }

    return Scaffold(
      appBar: const GradientAppBar(title: Text('Confirmar Pagamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Você está a enviar para:', style: theme.textTheme.titleLarge).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              _buildRecipientCard(theme, recipientName, recipientPhotoUrl).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
              const SizedBox(height: 24),
              _buildBalanceDisplay(theme).animate().fadeIn(delay: 350.ms),
              const SizedBox(height: 16),
              _buildAmountFormField(theme).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 32),
              _buildConfirmButton(theme).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceDisplay(ThemeData theme) {
    return Text(
      'Saldo disponível: ${_currencyFormat.format(_currentBalance)}',
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
    );
  }

  Widget _buildRecipientCard(ThemeData theme, String name, String? photoUrl) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null ? const Icon(Iconsax.user, size: 30) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountFormField(ThemeData theme) {
    return TextFormField(
      controller: _amountController,
      readOnly: widget.amount != null,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
      decoration: InputDecoration(
        labelText: 'Montante a Pagar',
        suffixText: 'Kz',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        errorText: _amountController.text.isNotEmpty && !_hasSufficientBalance ? 'Saldo insuficiente' : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Por favor, insira um montante.';
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) return 'Insira um montante válido.';
        if (amount > _currentBalance) return 'Saldo insuficiente.';
        return null;
      },
    );
  }

  Widget _buildConfirmButton(ThemeData theme) {
    final isButtonDisabled = _isProcessing || !_hasSufficientBalance;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: _isProcessing ? const SizedBox.shrink() : const Icon(Iconsax.send_1, color: Colors.white),
        label: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : Text('Confirmar e Pagar', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: isButtonDisabled ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isButtonDisabled ? Colors.grey.shade400 : AppColors.primaryGreen,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.removeListener(_validateBalance);
    _amountController.dispose();
    super.dispose();
  }
}
