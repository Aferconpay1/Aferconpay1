import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import 'custom_button.dart';
import 'custom_text_field.dart';

Future<bool?> showPinVerificationDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const PinVerificationDialog();
    },
  );
}

class PinVerificationDialog extends StatefulWidget {
  const PinVerificationDialog({super.key});

  @override
  State<PinVerificationDialog> createState() => _PinVerificationDialogState();
}

class _PinVerificationDialogState extends State<PinVerificationDialog> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  Future<void> _verifyPin() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final isValid = await firestoreService.verifyTransactionPin(_pinController.text);

      if (!mounted) return;

      if (isValid) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorText = 'PIN incorreto. Tente novamente.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Ocorreu um erro. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verificação de Segurança'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Introduza o seu PIN de 6 dígitos para continuar.'),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _pinController,
            labelText: 'PIN de Transação',
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            errorText: _errorText,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        if (_isLoading)
          const CircularProgressIndicator()
        else
          CustomButton(
            text: 'Confirmar',
            onPressed: _verifyPin,
          ),
      ],
    );
  }
}
