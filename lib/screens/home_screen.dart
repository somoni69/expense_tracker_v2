import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../data/local/database.dart';
import '../providers/expense_provider.dart';
import '../widgets/chart_widget.dart';
import '../widgets/add_expense_sheet.dart';
import '../screens/stats_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // (Методы иконок и цветов остаются те же)
  IconData _getCategoryIcon(CategoryType type) {
    switch (type) {
      case CategoryType.food:
        return Icons.fastfood;
      case CategoryType.transport:
        return Icons.directions_car;
      case CategoryType.shopping:
        return Icons.shopping_bag;
      case CategoryType.bills:
        return Icons.receipt;
      case CategoryType.entertainment:
        return Icons.movie;
      case CategoryType.other:
        return Icons.more_horiz;
    }
  }

  Color _getCategoryColor(CategoryType type) {
    switch (type) {
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

  void _showSalaryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ваш доход в этом месяце'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Например: 3000',
            suffixText: 'с.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null) {
                Provider.of<ExpenseProvider>(
                  context,
                  listen: false,
                ).setSalary(amount);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  // Обновили метод: теперь он может принимать расход для редактирования
  void _showAddModal(BuildContext context, {Expense? expenseToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddExpenseSheet(expenseToEdit: expenseToEdit),
    );
  }

  // Метод удаления с подтверждением
  void _confirmDelete(BuildContext context, Expense item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: Text('Вы точно хотите удалить "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<ExpenseProvider>(
                context,
                listen: false,
              ).deleteExpense(item);
              Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои расходы'),
        actions: [
          // Кнопка Статистики (ведет на новый экран)
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Статистика',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (ctx) => const StatsScreen()));
            },
          ),
          // Кнопка Зарплаты
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Установить бюджет',
            onPressed: () => _showSalaryDialog(context),
          ),
        ],
      ),

      // УБРАЛИ FloatingActionButton!
      body: StreamBuilder<List<Expense>>(
        stream: provider.expensesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final expenses = snapshot.data!;
          final totals = provider.calculateCategoryTotals(expenses);

          final salary = provider.salary;
          final spent = provider.calculateTotalSpent(expenses);
          final balance = provider.calculateBalance(expenses);

          return Column(
            children: [
              // 1. БАЛАНС
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBalanceItem(
                            context,
                            'Доход',
                            salary,
                            Colors.green,
                          ),
                          _buildBalanceItem(
                            context,
                            'Расход',
                            spent,
                            Colors.red,
                          ),
                          _buildBalanceItem(
                            context,
                            'Остаток',
                            balance,
                            Colors.blue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (expenses.isNotEmpty)
                        ExpenseChart(categoryTotals: totals),
                    ],
                  ),
                ),
              ),

              // 2. СПИСОК (Больше нет свайпов)
              Expanded(
                child: expenses.isEmpty
                    ? const Center(child: Text('Пока нет расходов'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          bottom: 80,
                        ), // Отступ, чтобы кнопка не закрыла список
                        itemCount: expenses.length,
                        itemBuilder: (ctx, i) {
                          final item = expenses[i];
                          return Card(
                            // Оборачиваем в Card для красоты
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getCategoryColor(
                                  item.category,
                                ).withOpacity(0.2),
                                child: Icon(
                                  _getCategoryIcon(item.category),
                                  color: _getCategoryColor(item.category),
                                ),
                              ),
                              title: Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat('dd MMM yyyy').format(item.date),
                              ),

                              // --- ВОТ ТУТ НОВЫЕ ИКОНКИ ---
                              trailing: Row(
                                mainAxisSize: MainAxisSize
                                    .min, // Чтобы иконки не заняли всю ширину
                                children: [
                                  // Сумма
                                  Text(
                                    '${item.amount.toStringAsFixed(0)} с.',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Редактировать
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blueGrey,
                                    ),
                                    onPressed: () => _showAddModal(
                                      context,
                                      expenseToEdit: item,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    style: const ButtonStyle(
                                      tapTargetSize: MaterialTapTargetSize
                                          .shrinkWrap, // Компактная кнопка
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Удалить
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () =>
                                        _confirmDelete(context, item),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    style: const ButtonStyle(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // 3. БОЛЬШАЯ КНОПКА ВНИЗУ
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () => _showAddModal(context),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'ДОБАВИТЬ РАСХОД',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBalanceItem(
    BuildContext context,
    String label,
    double amount,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          '${amount.toStringAsFixed(0)} с.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
