
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../services/firestore_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../main.dart'; // For AppColors
import '../models/user_model.dart';
import '../screens/pin/set_pin_screen.dart';
import '../widgets/pin_verification_dialog.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isSearching = false;
  bool _isTransferring = false;
  Map<String, dynamic>? _foundRecipient;
  bool _hasSufficientBalance = true;
  double _currentBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_validateBalance);
  }

  void _validateBalance() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount > _currentBalance) {
      if (_hasSufficientBalance) {
        setState(() => _hasSufficientBalance = false);
      }
    } else {
      if (!_hasSufficientBalance) {
        setState(() => _hasSufficientBalance = true);
      }
    }
  }

  Future<void> _searchRecipient() async {
    if (_identifierController.text.isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundRecipient = null;
    });

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final recipient = await firestoreService.findRecipient(_identifierController.text);
      if (!mounted) return;

      if (recipient == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Nenhum utilizador encontrado com este email ou telemóvel.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        setState(() => _foundRecipient = recipient);
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erro na pesquisa: ${e.toString().replaceAll("Exception: ", "")}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _submitTransfer() async {
    if (!_formKey.currentState!.validate() || _foundRecipient == null || !_hasSufficientBalance) {
      return;
    }

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

    setState(() => _isTransferring = true);

    try {
      final recipientId = _foundRecipient!['uid'];
      final amount = double.parse(_amountController.text);
      final note = _noteController.text;

      await firestoreService.transferFunds(recipientId, amount, note);
      
      if (!mounted) return;

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Transferência para ${_foundRecipient!['displayName']} realizada com sucesso!'),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      router.go('/home');

    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isTransferring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 2);

    final user = Provider.of<UserModel?>(context);
    if (user != null) {
      _currentBalance = user.balance;
    }

    return Scaffold(
      appBar: const GradientAppBar(title: Text('Transferir Dinheiro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchStep(theme),
              if (_foundRecipient != null)
                _buildPaymentStep(theme, currencyFormatter).animate().fadeIn(duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchStep(ThemeData theme) {
    return Column(
      children: [
        TextFormField(
          controller: _identifierController,
          decoration: InputDecoration(
            labelText: 'Email ou Telemóvel do Destinatário',
            prefixIcon: const Icon(Iconsax.user_search),
            suffixIcon: _isSearching
                ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(icon: const Icon(Iconsax.search_normal_1), onPressed: _searchRecipient, tooltip: 'Procurar'),
          ),
          keyboardType: TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Insira um email ou telemóvel.';
            return null;
          },
          onFieldSubmitted: (_) => _searchRecipient(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPaymentStep(ThemeData theme, NumberFormat currencyFormatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 32),
        Center(
          child: Column(
            children: [
              const CircleAvatar(radius: 32, child: Icon(Iconsax.user, size: 32)),
              const SizedBox(height: 12),
              Text(_foundRecipient!['displayName'], style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text(_foundRecipient!['email'], style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Saldo disponível: ${currencyFormatter.format(_currentBalance)}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
          ),
        ),
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Valor (Kz)',
            prefixIcon: const Icon(Iconsax.money_send),
            errorText: !_hasSufficientBalance ? 'Saldo insuficiente' : null,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Insira um valor.';
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) return 'O valor deve ser positivo.';
            if (amount > _currentBalance) return 'Saldo insuficiente.';
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _noteController,
          decoration: const InputDecoration(labelText: 'Nota (Opcional)', prefixIcon: Icon(Iconsax.edit)),
          maxLength: 50,
        ),
        const SizedBox(height: 32),
        _isTransferring
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
                icon: const Icon(Iconsax.send_1, color: Colors.white),
                label: const Text('Confirmar Transferência'),
                onPressed: _isTransferring || !_hasSufficientBalance ? null : _submitTransfer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
              ),
      ],
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _amountController.removeListener(_validateBalance);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
