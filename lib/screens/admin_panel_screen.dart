import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';

import '../services/firestore_service.dart';
import '../widgets/gradient_app_bar.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: Text('Painel de Administração')),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(icon: Icon(Iconsax.clock), text: 'Créditos'),
                Tab(icon: Icon(Iconsax.money_recive), text: 'Depósitos'),
                Tab(icon: Icon(Iconsax.money_send), text: 'Levantamentos'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildLoanRequestsList(context),
                  _buildDepositRequestsList(context),
                  _buildWithdrawalRequestsList(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanRequestsList(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getPendingLoanRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhum pedido de crédito pendente.'));
        }

        final requests = snapshot.data!.docs;

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final data = request.data() as Map<String, dynamic>;
            final loanId = request.id;
            final userId = data['userId'] as String;
            final amount = (data['amount'] as num).toDouble();
            final term = (data['termInMonths'] as num).toInt();
            final requestedAt = (data['requestedAt'] as Timestamp).toDate();
            
            return LoanRequestCard(
                loanId: loanId,
                userId: userId,
                amount: amount,
                term: term,
                requestedAt: requestedAt,
            );
          },
        );
      },
    );
  }

    Widget _buildDepositRequestsList(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getPendingDepositRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhum pedido de depósito pendente.'));
        }

        final requests = snapshot.data!.docs;

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final data = request.data() as Map<String, dynamic>;
            final requestId = request.id;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('Utilizador: ${data['userName']}'),
                subtitle: Text('Montante: ${NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz').format(data['amount'])} - Ref: ${data['reference']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => firestoreService.approveDeposit(requestId, data['userId'], data['amount']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => firestoreService.rejectDeposit(requestId, data['userId']),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

    Widget _buildWithdrawalRequestsList(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 2);
    
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getPendingWithdrawalRequests(),
      builder: (context, snapshot) {
         if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhum pedido de levantamento pendente.'));
        }

        final requests = snapshot.data!.docs;

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final data = request.data() as Map<String, dynamic>;
            final requestId = request.id;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('Para: ${data['ibanHolderName']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Debitado: ${currencyFormat.format(data['totalDebited'])}'),
                    Text('IBAN: ${data['iban']}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.blueAccent),
                  tooltip: 'Marcar como Concluído',
                  onPressed: () {
                     firestoreService.markWithdrawalAsCompleted(
                      requestId, 
                      data['userId'], 
                      data['totalDebited']
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class LoanRequestCard extends StatelessWidget {
  final String loanId;
  final String userId;
  final double amount;
  final int term;
  final DateTime requestedAt;

  const LoanRequestCard({
    super.key,
    required this.loanId,
    required this.userId,
    required this.amount,
    required this.term,
    required this.requestedAt,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: firestoreService.getUser(userId),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const Text('A carregar dados do utilizador...');
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                return Text(
                  userData['displayName'] ?? 'Utilizador Desconhecido',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                );
              },
            ),
            const SizedBox(height: 8),
            Text('ID do Utilizador: $userId', style: Theme.of(context).textTheme.bodySmall),
            const Divider(height: 24),
            _buildInfoRow(context, Iconsax.money_4, 'Montante', currencyFormat.format(amount)),
            _buildInfoRow(context, Iconsax.calendar_1, 'Prazo', '$term meses'),
            _buildInfoRow(context, Iconsax.clock, 'Data do Pedido', dateFormat.format(requestedAt)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Iconsax.close_circle, color: Colors.red),
                  label: const Text('Rejeitar', style: TextStyle(color: Colors.red)),
                  onPressed: () => _showConfirmationDialog(context, false),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Iconsax.tick_circle, color: Colors.white),
                  label: const Text('Aprovar'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () => _showConfirmationDialog(context, true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, bool isApproving) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isApproving ? 'Aprovar Crédito' : 'Rejeitar Crédito'),
          content: Text('Tem a certeza que deseja ${isApproving ? "aprovar" : "rejeitar"} este pedido de crédito?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: isApproving ? Colors.green : Colors.red),
              child: const Text('Confirmar'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  if (isApproving) {
                    await firestoreService.approveLoan(loanId, userId, amount);
                  } else {
                    await firestoreService.rejectLoan(loanId);
                  }
                  if (!context.mounted) return;
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Operação bem sucedida!"),
                    backgroundColor: Colors.green,
                  ));
                } catch (e) {
                  if (!context.mounted) return;
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Falha na operação: $e"),
                    backgroundColor: Colors.red,
                  ));
                }
              },
            ),
          ],
        );
      },
    );
  }
}
