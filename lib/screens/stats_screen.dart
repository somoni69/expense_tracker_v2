import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/local/database.dart';
import '../providers/expense_provider.dart';
import '../services/excel_service.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  Future<void> _importExcel(BuildContext context) async {
    try {
      final excelService = ExcelService();
      final newExpenses = await excelService.pickAndParseExcel();

      if (newExpenses.isNotEmpty) {
        if (context.mounted) {
          await Provider.of<ExpenseProvider>(
            context,
            listen: false,
          ).importExpensesBatch(newExpenses);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Успешно импортировано: ${newExpenses.length} записей',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);

    // 1. Оборачиваем ВСЁ в StreamBuilder, чтобы AppBar видел данные
    return StreamBuilder<List<Expense>>(
      stream: provider.expensesStream,
      builder: (context, snapshot) {
        final expenses = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Статистика'),
            actions: [
              // --- ЭКСПОРТ ---
              IconButton(
                icon: const Icon(Icons.share), // Иконка "Поделиться"
                tooltip: 'Экспорт в Excel',
                onPressed: () async {
                  if (expenses.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Список пуст')),
                    );
                    return;
                  }

                  // Получаем зарплату из провайдера
                  final salary = provider.salary;

                  // Передаем её в сервис
                  await ExcelService().exportToExcel(expenses, salary);
                },
              ),
              // --- ИМПОРТ ---
              IconButton(
                onPressed: () => _importExcel(context),
                icon: const Icon(Icons.upload_file),
                tooltip: 'Импорт из Excel',
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              final expenses = snapshot.data!;

              // Используем новый метод группировки
              final groupedData = provider.groupExpensesByMonth(expenses);

              if (groupedData.isEmpty) {
                return const Center(child: Text('Нет данных для статистики'));
              }

              // Подготовка данных для графика (берем последние 6 месяцев)
              final allMonths = groupedData.keys
                  .toList(); // ["Ноябрь 2025", "Октябрь 2025"...]
              // Разворачиваем, чтобы старые были слева
              final reversedMonths = allMonths.reversed.toList();
              // Берем последние 6
              final displayMonths = reversedMonths.length > 6
                  ? reversedMonths.sublist(reversedMonths.length - 6)
                  : reversedMonths;

              final barGroups = List.generate(displayMonths.length, (index) {
                final monthName = displayMonths[index];
                final monthExpenses = groupedData[monthName]!;
                // Считаем сумму для этого месяца
                final totalAmount = monthExpenses.fold(
                  0.0,
                  (sum, item) => sum + item.amount,
                );

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: totalAmount,
                      color: Theme.of(context).colorScheme.primary,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                      // Добавляем "тултип" (значение над столбиком)
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: provider.salary,
                        color: Colors.grey.withOpacity(0.1),
                      ),
                    ),
                  ],
                );
              });

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      "Динамика (последние 6 мес.)",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY:
                              displayMonths
                                  .map(
                                    (month) => groupedData[month]!.fold(
                                      0.0,
                                      (sum, item) => sum + item.amount,
                                    ),
                                  )
                                  .reduce((a, b) => a > b ? a : b) *
                              1.2,
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget:
                                    (double value, TitleMeta meta) {
                                      if (value.toInt() >= displayMonths.length)
                                        return const Text('');

                                      // Берем первые 3 буквы месяца (Ноя, Дек)
                                      final fullName =
                                          displayMonths[value.toInt()];
                                      final shortName = fullName
                                          .split(' ')[0]
                                          .substring(0, 3);

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          shortName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          barGroups: barGroups,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      color: Colors.blue.shade50,
                      child: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Экспортируйте данные, чтобы сохранить резервную копию или открыть в Excel на ПК.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
