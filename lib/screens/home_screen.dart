import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../main.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../providers/notification_provider.dart';
import '../widgets/primary_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isExporting = false;
  bool _showBalance = true;
  String _currentUserName = 'Utilizador';

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Bom dia';
    }
    if (hour < 18) {
      return 'Boa tarde';
    }
    return 'Boa noite';
  }

  Future<void> _exportTransactions() async {
    if (_isExporting) return;

    final pdfExportService = Provider.of<PdfExportService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);

    setState(() => _isExporting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
      ),
    );

    try {
      await pdfExportService.generateAndShareStatement();
      if (navigator.canPop()) navigator.pop();
    } catch (e) {
      if (navigator.canPop()) navigator.pop();
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Erro ao gerar o PDF: ${e.toString()}'),
        backgroundColor: theme.colorScheme.error,
      ));
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _shareReceipt(
      Transaction transaction, String currentUserName) async {
    final pdfExportService =
        Provider.of<PdfExportService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    if (mounted) {
      setState(() => _isExporting = true);
    }

    try {
      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('A gerar o seu comprovativo...'),
        duration: Duration(seconds: 2),
      ));
      await pdfExportService.generateAndShareSingleReceipt(
          transaction, currentUserName);
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Erro ao partilhar: ${e.toString()}'),
        backgroundColor: theme.colorScheme.error,
      ));
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showTransactionDetails(Transaction tx) {
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 2);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isCredit = tx.type == TransactionType.credit;
        final color = isCredit ? Colors.green.shade600 : theme.colorScheme.error;
        final amountPrefix = isCredit ? '+' : '-';

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                tx.description,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('dd MMMM yyyy, HH:mm').format(tx.timestamp),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '$amountPrefix ${currencyFormat.format(tx.amount)}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow(theme, 'Tipo:', tx.type.name.toUpperCase()),
              _buildDetailRow(theme, 'ID da Transação:', tx.id ?? 'N/A'),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Partilhar Comprovativo',
                onPressed: () {
                   Navigator.of(context).pop(); 
                  _shareReceipt(tx, _currentUserName);
                },
                icon: Iconsax.share,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Flexible(child: Text(value, style: theme.textTheme.bodyMedium, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final notificationProvider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: GradientAppBar(
        title: const Text('Afercon Pay'),
        actions: [
          IconButton(
              icon: const Icon(Iconsax.document_download),
              onPressed: _exportTransactions,
              tooltip: 'Exportar Extrato'),
          IconButton(
              icon: const Icon(Iconsax.message_question),
              onPressed: () => context.push('/faq'),
              tooltip: 'FAQ'),
          Badge(
            isLabelVisible: notificationProvider.hasUnreadNotifications,
            child: IconButton(
              icon: const Icon(Iconsax.notification),
              onPressed: () {
                notificationProvider.markAllAsRead();
                context.push('/notifications');
              },
              tooltip: 'Notificações',
            ),
          ),
          IconButton(
              icon: const Icon(Iconsax.user),
              onPressed: () => context.push('/profile'),
              tooltip: 'Meu Perfil'),
          IconButton(
              icon: Icon(themeProvider.themeMode == ThemeMode.dark
                  ? Iconsax.sun_1
                  : Iconsax.moon),
              onPressed: () => themeProvider.toggleTheme(),
              tooltip: 'Mudar Tema'),
          IconButton(
              icon: const Icon(Iconsax.logout),
              onPressed: _logout,
              tooltip: 'Sair'),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _isExporting,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildQuickActions(context),
              _buildTransactionListHeader(),
              _buildTransactionList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final firestoreService = Provider.of<FirestoreService>(context);
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: firestoreService.userStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator()));
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final balance = (userData['balance'] ?? 0.0) as double;
        _currentUserName = userData['displayName'] ?? 'Utilizador';

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_getGreeting()}, $_currentUserName',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold))
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideX(begin: -0.2),
              const SizedBox(height: 12),
              _buildBalanceCard(theme, balance)
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .scale(begin: const Offset(0.9, 0.9)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(ThemeData theme, double balance) {
    return Card(
      elevation: 10,
      shadowColor: theme.colorScheme.primary.withAlpha(100),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            gradient: LinearGradient(
          colors: [theme.colorScheme.primary, AppColors.secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Saldo Disponível',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.white70)),
                IconButton(
                  icon: Icon(
                      _showBalance ? Iconsax.eye_slash : Iconsax.eye,
                      color: Colors.white,
                      size: 24),
                  onPressed: () => setState(() => _showBalance = !_showBalance),
                  tooltip:
                      _showBalance ? 'Ocultar Saldo' : 'Mostrar Saldo',
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: 300.ms,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _showBalance
                  ? Text(
                      NumberFormat.currency(locale: 'pt_PT', symbol: 'Kz')
                          .format(balance),
                      key: const ValueKey('balance_visible'),
                      style: theme.textTheme.displaySmall?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold))
                  : Text('********',
                      key: const ValueKey('balance_hidden'),
                      style: theme.textTheme.displaySmall?.copyWith(
                          color: Colors.white, letterSpacing: 1.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 10.0),
            child: Text(
              'Ações Rápidas',
              style:
                  theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 350.ms),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primaryGreen.withAlpha(128), width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withAlpha(25),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 0.9,
                children: [
                  _buildQuickActionButton(Iconsax.scan_barcode, 'Receber QR',
                      '/receive',
                      delay: 400.ms),
                  _buildQuickActionButton(
                      Iconsax.scan, 'Pagar QR', '/scan', delay: 450.ms),
                  _buildQuickActionButton(
                      Iconsax.send_2, 'Transferir', '/transfer', delay: 500.ms),
                  _buildQuickActionButton(Iconsax.money_remove, 'Levantar',
                      '/withdraw',
                      delay: 550.ms),
                  _buildQuickActionButton(
                      Iconsax.money_add, 'Depositar', '/deposit', delay: 600.ms),
                  _buildQuickActionButton(Iconsax.wallet_check, 'Créditos',
                      '/credit-center',
                      delay: 650.ms),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, String route,
      {required Duration delay}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGreen.withAlpha(25),
            ),
            child: Icon(icon, size: 24, color: AppColors.primaryGreen),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionListHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Atividade Recente',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold))
              .animate()
              .fadeIn(delay: 700.ms),
          TextButton(
            onPressed: () => context.push('/history'),
            child: const Text('Ver Tudo'),
          )
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final firestoreService = Provider.of<FirestoreService>(context);
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 2);

    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.transactionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text(
                  'Ocorreu um erro ao carregar as transações: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.note_remove, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Nenhuma transação ainda.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        final transactions = snapshot.data!.docs
            .map((doc) => Transaction.fromFirestore(doc))
            .take(3)
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80.0),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final isCredit = tx.type == TransactionType.credit;
            final color = isCredit ? Colors.green.shade600 : theme.colorScheme.error;
            final icon = isCredit ? Iconsax.arrow_down : Iconsax.arrow_up_3;
            final amountPrefix = isCredit ? '+' : '-';

            return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                elevation: 1.0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(color: Colors.grey.shade300, width: 0.5),
                ),
                child: InkWell(
                    borderRadius: BorderRadius.circular(12.0),
                    onTap: () => _showTransactionDetails(tx),
                    child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                        children: [
                            CircleAvatar(
                            backgroundColor: color.withAlpha(26),
                            child: Icon(icon, color: color, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                Text(
                                    tx.description,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    DateFormat('dd MMM yyyy, HH:mm').format(tx.timestamp),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant),
                                ),
                                ],
                            ),
                            ),
                            const SizedBox(width: 12),
                             Text(
                          '$amountPrefix ${currencyFormat.format(tx.amount)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        ],
                        ),
                    ),
                ),
                ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: -0.1, duration: 400.ms);
          },
        );
      },
    );
  }
}
