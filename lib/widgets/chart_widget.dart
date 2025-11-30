import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/local/database.dart';

class ExpenseChart extends StatelessWidget {
  final Map<CategoryType, double> categoryTotals;

  const ExpenseChart({super.key, required this.categoryTotals});

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Нет данных для графика')),
      );
    }

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: _generateSections(),
        ),
      ),
    );
  }

  List<PieChartSectionData> _generateSections() {
    final List<PieChartSectionData> sections = [];

    categoryTotals.forEach((category, amount) {
      sections.add(
        PieChartSectionData(
          color: _getCategoryColor(category),
          value: amount,
          title: '${amount.toStringAsFixed(0)} с.',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });
    return sections;
  }

  Color _getCategoryColor(CategoryType category) {
    switch (category) {
      case CategoryType.food:
        return Colors.orange;
      case CategoryType.transport:
        return Colors.blue;
      case CategoryType.shopping:
        return Colors.purple;
      case CategoryType.bills:
        return Colors.red;
      case CategoryType.entertainment:
        return Colors.green;
      case CategoryType.other:
        return Colors.grey;
    }
  }
}
