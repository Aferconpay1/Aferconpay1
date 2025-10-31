import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionLineChart extends StatelessWidget {
  final Map<DateTime, double> dailyVolume;

  const TransactionLineChart({super.key, required this.dailyVolume});

  @override
  Widget build(BuildContext context) {
    final sortedDays = dailyVolume.keys.toList()..sort();
    if (sortedDays.isEmpty) {
      return const Center(
        child: Text(
          'Não há dados suficientes para exibir o gráfico.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final List<FlSpot> spots = sortedDays.map((day) {
      final index = sortedDays.indexOf(day);
      return FlSpot(index.toDouble(), dailyVolume[day]!);
    }).toList();

    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz', decimalDigits: 0);
    final theme = Theme.of(context);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.withAlpha(25), strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: Colors.grey.withAlpha(25), strokeWidth: 1);
          },
        ),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              // interval: (sortedDays.length / 5).ceil().toDouble(),
              // getTitlesWidget: (value, meta) {
              //     if (value.toInt() >= sortedDays.length) return Container();
              //     final date = sortedDays[value.toInt()];
              //     return Padding(
              //       padding: const EdgeInsets.only(top: 8.0),
              //       child: Text(DateFormat('dd/MM').format(date), style: const TextStyle(fontSize: 10)),
              //     );
              // },
            ),
          ),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withAlpha(51))),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withAlpha(51),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                 if (spot.spotIndex >= sortedDays.length) return null;
                 final date = sortedDays[spot.spotIndex];
                 return LineTooltipItem(
                    '${currencyFormat.format(spot.y)}\n',
                    const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    children: [TextSpan(text: DateFormat('dd MMM yyyy').format(date), style: const TextStyle(color: Colors.white70))]
                 );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
