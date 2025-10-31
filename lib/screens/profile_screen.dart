import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/pdf_export_service.dart';
import '../main.dart'; // Para aceder ao ThemeProvider

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestoreService.userStream,
        builder: (context, snapshot) {
          final userData = snapshot.hasData && snapshot.data!.data() != null 
              ? snapshot.data!.data() as Map<String, dynamic> 
              : <String, dynamic>{};
          final bool isAdmin = userData['isAdmin'] ?? false;

          return CustomScrollView(
            slivers: [
              _ProfileHeader(userData: userData),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _SettingsHub(isAdmin: isAdmin).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> userData;

  const _ProfileHeader({required this.userData});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    final theme = Theme.of(context);
    final isVerified = user?.emailVerified ?? false;

    return SliverAppBar(
      expandedHeight: 420.0, // Altura ajustada
      pinned: true,
      stretch: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryGreen.withAlpha(204), // 80% opacity
                    AppColors.secondaryBlue.withAlpha(230), // 90% opacity
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ).animate().fadeIn(duration: 600.ms),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: theme.colorScheme.surface,
                      child: Icon(Iconsax.user, size: 60, color: theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userData['displayName'] ?? user?.displayName ?? 'Utilizador',
                    style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _InfoTile(icon: Iconsax.direct_right, text: user?.email ?? 'E-mail não disponível'),
                      if (isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Iconsax.verify,
                            color: Colors.lightBlueAccent,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoTile(icon: Iconsax.call, text: userData['phoneNumber'] ?? 'Telefone não informado'),
                        const SizedBox(height: 10),
                        _InfoTile(icon: Iconsax.calendar, text: userData['dob'] ?? 'Data de nasc. não informada'),
                        const SizedBox(height: 10),
                        _InfoTile(icon: Iconsax.global, text: userData['country'] ?? 'País não informado'),
                        const SizedBox(height: 10),
                        _InfoTile(icon: Iconsax.map, text: userData['province'] ?? 'Província não informada'),
                      ],
                    ),
                  )
                ],
              ),
            ).animate().slideY(begin: 0.5, delay: 200.ms, duration: 500.ms, curve: Curves.easeOut).fadeIn(),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}


class _SettingsHub extends StatelessWidget {
  final bool isAdmin;
  const _SettingsHub({required this.isAdmin});

  Future<void> _signOut(BuildContext context) async {
    await context.read<AuthService>().signOut();
  }
  
  void _showExportDialog(BuildContext context) {
    final pdfService = context.read<PdfExportService>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Exportar Extrato'),
              content: Text(isLoading 
                  ? 'A gerar o seu extrato em PDF...' 
                  : 'Deseja gerar e partilhar o seu extrato de transações?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                if (!isLoading)
                  FilledButton(
                    onPressed: () async {
                      setState(() => isLoading = true);
                      try {
                        await pdfService.generateAndShareStatement();
                         if(context.mounted) { Navigator.of(context).pop(); }
                      } catch (e) {
                         if(context.mounted) { Navigator.of(context).pop(); }
                         if(context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao gerar PDF: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: const Text('Exportar'),
                  )
                else const CircularProgressIndicator(),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Definições e Segurança', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              if (isAdmin)
                _SettingsTile(
                  icon: Iconsax.security_user,
                  title: 'Painel de Administração',
                  onTap: () => context.go('/admin/dashboard'),
                ),
              _SettingsTile(
                icon: Iconsax.edit,
                title: 'Gerir Conta',
                onTap: () { /* Navegar para ecrã de edição de perfil se existir ou mostrar um dialog */ },
              ),
              _SettingsTile(
                icon: Iconsax.key,
                title: 'Segurança',
                onTap: () => context.go('/change-password'),
              ),
              _SettingsTile(
                icon: Iconsax.document_download,
                title: 'Exportar Extrato',
                onTap: () => _showExportDialog(context),
              ),
               _SettingsTile(
                icon: Iconsax.document_text,
                title: 'Termos e Condições',
                onTap: () => context.go('/terms'),
              ),
              _SettingsTile(
                icon: Iconsax.shield_tick,
                title: 'Política de Privacidade',
                onTap: () => context.go('/privacy-policy'),
              ),
              SwitchListTile(
                secondary: Icon(isDarkMode ? Iconsax.moon : Iconsax.sun_1, color: Theme.of(context).colorScheme.primary),
                title: const Text('Modo Escuro'),
                value: isDarkMode,
                onChanged: (value) => themeProvider.toggleTheme(),
              ),
              _SettingsTile(
                icon: Iconsax.logout_1,
                title: 'Terminar Sessão',
                onTap: () => _signOut(context),
                isDestructive: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsTile({required this.icon, required this.title, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: isDestructive ? null : const Icon(Iconsax.arrow_right_3, size: 18),
      onTap: onTap,
    );
  }
}
