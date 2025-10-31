import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/primary_button.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _currentUserName = 'Utilizador';

  Future<void> _shareReceipt(Transaction transaction, String currentUserName) async {
    final pdfExportService = Provider.of<PdfExportService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    try {
      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('A gerar o seu comprovativo...'),
        duration: Duration(seconds: 2),
      ));
      await pdfExportService.generateAndShareSingleReceipt(transaction, currentUserName);
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Erro ao partilhar: ${e.toString()}'),
        backgroundColor: theme.colorScheme.error,
      ));
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
    final firestoreService = Provider.of<FirestoreService>(context);
    final theme = Theme.of(context);
    final userStream = firestoreService.userStream;
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 2);

    return Scaffold(
      appBar: const GradientAppBar(
        title: Text('Histórico de Transações'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.transactionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Ocorreu um erro ao carregar as transações.'));
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
                    Text(
                      'Ainda não realizou nenhuma transação.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          final transactions = snapshot.data!.docs.map((doc) => Transaction.fromFirestore(doc)).toList();

          return StreamBuilder<DocumentSnapshot>(
            stream: userStream,
            builder: (context, userSnapshot) {
              if (userSnapshot.hasData) {
                final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                _currentUserName = userData['displayName'] ?? 'Utilizador';
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
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
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd MMM yyyy, HH:mm').format(tx.timestamp),
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
        },
      ),
    );
  }
}
