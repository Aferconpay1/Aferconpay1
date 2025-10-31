import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/app_config.dart';
import '../main.dart';

class SupportFab extends StatelessWidget {
  const SupportFab({super.key});

  Future<void> _makePhoneCall(BuildContext context) async {
    final Uri launchUri = Uri(scheme: 'tel', path: AppConfig.supportPhoneNumber);
    if (!await launchUrl(launchUri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível realizar a chamada.')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final Uri launchUri = Uri.parse('https://wa.me/${AppConfig.supportPhoneNumber}?text=${Uri.encodeComponent(AppConfig.supportWhatsAppMessage)}');
     if (!await launchUrl(launchUri, mode: LaunchMode.externalApplication)) {
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
      }
    }
  }

  void _showSupportOptions(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primaryGreen.withAlpha((255 * 0.3).round())),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Contactar Apoio',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Precisa de ajuda? Fale connosco!',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              _buildSupportOption(
                context,
                icon: Iconsax.call,
                label: 'Ligar Agora',
                subtitle: AppConfig.supportPhoneNumberDisplay,
                onTap: () {
                  Navigator.pop(ctx);
                  _makePhoneCall(context);
                },
              ),
              const Divider(height: 32),
              _buildSupportOption(
                context,
                icon: Iconsax.message,
                label: 'Enviar Mensagem',
                subtitle: 'WhatsApp',
                onTap: () {
                   Navigator.pop(ctx);
                  _openWhatsApp(context);
                },
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.5, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildSupportOption(BuildContext context, {required IconData icon, required String label, required String subtitle, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, size: 32, color: AppColors.primaryGreen),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
              ],
            ),
            const Spacer(),
            const Icon(Iconsax.arrow_right_3, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showSupportOptions(context),
      icon: const Icon(Iconsax.support),
      label: const Text('Apoio'),
      tooltip: 'Contactar Apoio ao Cliente',
    ).animate().fadeIn(delay: 1000.ms).slideX(begin: 0.5, curve: Curves.easeOutCubic);
  }
}
