import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '_transaction_line_chart.dart';
import '_transaction_pie_chart.dart'; // Import the new pie chart widget

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obtém o FirestoreService a partir do Provider
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _dashboardData = _fetchDashboardData(firestoreService);
  }

  Future<Map<String, dynamic>> _fetchDashboardData(FirestoreService firestoreService) async {
    try {
      final usersCount = await firestoreService.getUsersCount();
      final transactionsCount = await firestoreService.getTotalTransactionsCount();
      final totalVolume = await firestoreService.getTotalVolume();
      final dailyVolume = await firestoreService.getDailyTransactionVolume();
      final transactionDistribution = await firestoreService.getTransactionDistribution();

      return {
        'usersCount': usersCount,
        'transactionsCount': transactionsCount,
        'totalVolume': totalVolume,
        'dailyVolume': dailyVolume,
        'transactionDistribution': transactionDistribution,
      };
    } catch (e) {
      // Rethrow the exception to be caught by the FutureBuilder
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 0);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _dashboardData = _fetchDashboardData(firestoreService);
              });
            },
            tooltip: 'Atualizar Dados',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erro ao carregar dados do dashboard: ${snapshot.error}'),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: () => setState(() { _dashboardData = _fetchDashboardData(firestoreService); }), child: const Text('Tentar Novamente'))
                ],
              ),
            );
          }

          final data = snapshot.data ?? {};
          final usersCount = data['usersCount'] ?? 0;
          final transactionsCount = data['transactionsCount'] ?? 0;
          final totalVolume = data['totalVolume'] ?? 0.0;
          final dailyVolume = data['dailyVolume'] as Map<DateTime, double>? ?? {};
          final transactionDistribution = data['transactionDistribution'] as Map<String, int>? ?? {'credit': 0, 'debit': 0};

          return RefreshIndicator(
            onRefresh: () async {
                 setState(() {
                    _dashboardData = _fetchDashboardData(firestoreService);
                 });
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visão Geral',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _SummaryCard(
                        title: 'Total Usuários',
                        value: usersCount.toString(),
                        icon: Icons.people_outline,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 16),
                      _SummaryCard(
                        title: 'Total Transações',
                        value: transactionsCount.toString(),
                        icon: Icons.receipt_long_outlined,
                        color: Colors.orangeAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                   _SummaryCard(
                      title: 'Volume Total Transacionado',
                      value: currencyFormat.format(totalVolume),
                      icon: Icons.monetization_on_outlined,
                      color: Colors.green,
                      isFullWidth: true,
                    ),
                  const SizedBox(height: 32),
                  Text(
                    'Análise de Transações',
                     style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: Card(
                       elevation: 4,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                       child: Padding(
                         padding: const EdgeInsets.all(16.0),
                         child: TransactionLineChart(dailyVolume: dailyVolume),
                       ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 250,
                    child: Card(
                       elevation: 4,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                       child: Padding(
                         padding: const EdgeInsets.all(16.0),
                         child: TransactionPieChart(distribution: transactionDistribution),
                       ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// A more styled summary card
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isFullWidth;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: 4,
      shadowColor: color.withAlpha((255 * 0.4).round()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
                colors: [color.withAlpha((255 * 0.7).round()), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
            )
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );

    if (isFullWidth) {
      return card;
    }
    
    return Expanded(child: card);
  }
}
