import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TransactionPieChart extends StatelessWidget {
  final Map<String, int> distribution;

  const TransactionPieChart({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    final int creditCount = distribution['credit'] ?? 0;
    final int debitCount = distribution['debit'] ?? 0;
    final total = creditCount + debitCount;

    if (total == 0) {
      return const Center(
        child: Text(
          'Não há transações para exibir.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  color: Colors.greenAccent,
                  value: creditCount.toDouble(),
                  title: '${(creditCount / total * 100).toStringAsFixed(1)}%',
                  radius: 80,
                  titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                PieChartSectionData(
                  color: Colors.redAccent,
                  value: debitCount.toDouble(),
                  title: '${(debitCount / total * 100).toStringAsFixed(1)}%',
                  radius: 80,
                  titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Indicator(color: Colors.greenAccent, text: 'Crédito ($creditCount)'),
              const SizedBox(height: 8),
              _Indicator(color: Colors.redAccent, text: 'Débito ($debitCount)'),
            ],
          ),
        )
      ],
    );
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;

  const _Indicator({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        )
      ],
    );
  }
}
