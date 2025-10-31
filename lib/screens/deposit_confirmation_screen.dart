import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/gradient_app_bar.dart';

class DepositConfirmationScreen extends StatelessWidget {
  final double amount;
  final String reference;

  static const String aferconIban = 'AO06 0055 0000 39513329101 67';
  static const String aferconBeneficiary = 'Afercon, Lda';
  static const String whatsappNumber = '+244945100502';

  const DepositConfirmationScreen({super.key, required this.amount, required this.reference});

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado para a área de transferência!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final message = 'Olá Afercon Pay, segue o meu comprovativo de depósito.\n\nReferência: $reference\nMontante: ${NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz').format(amount)}';
    final whatsappUrl = Uri.parse("https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Não foi possível abrir o WhatsApp.';
      }
    } catch (e) {
      if (!context.mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 2);

    return Scaffold(
      appBar: const GradientAppBar(title: Text('Confirmar Depósito'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Iconsax.task_square, size: 60, color: Colors.green).animate().scale(delay: 100.ms),
              const SizedBox(height: 16),
              Text(
                'Referência Gerada com Sucesso!',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              Text(
                'Use os dados abaixo para fazer a transferência e envie-nos o comprovativo para acelerar a confirmação.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 32),

              // --- Detalhes da Transferência ---
              _buildDetailsCard(context, theme, currencyFormat).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),
              
              // --- Botão WhatsApp ---
              ElevatedButton.icon(
                icon: const Icon(Iconsax.send_1, size: 20),
                label: const Text('Enviar Comprovativo via WhatsApp'),
                onPressed: () => _launchWhatsApp(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 16),

              // --- Botão Voltar ao Início ---
              OutlinedButton.icon(
                icon: const Icon(Iconsax.home, size: 20),
                label: const Text('Voltar ao Início'),
                onPressed: () => context.go('/home'),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, ThemeData theme, NumberFormat currencyFormat) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildInfoRow(context, theme, Iconsax.money_send, 'Valor a Transferir', currencyFormat.format(amount)),
            const Divider(height: 24),
            _buildInfoRow(context, theme, Iconsax.document_code, 'Referência (no descritivo)', reference, canCopy: true),
            const Divider(height: 24),
            _buildInfoRow(context, theme, Iconsax.card, 'IBAN do Beneficiário', aferconIban, canCopy: true),
             const Divider(height: 24),
            _buildInfoRow(context, theme, Iconsax.user, 'Nome do Beneficiário', aferconBeneficiary),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, ThemeData theme, IconData icon, String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (canCopy)
            IconButton(
              icon: const Icon(Iconsax.copy, size: 20),
              onPressed: () => _copyToClipboard(context, value, label),
              tooltip: 'Copiar',
            ),
        ],
      ),
    );
  }
}
