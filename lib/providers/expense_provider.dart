import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:shared_preferences/shared_preferences.dart'; // 1. Импорт
import '../data/local/database.dart';
import '../locator.dart';
import 'package:intl/intl.dart';

class ExpenseProvider extends ChangeNotifier {
  final AppDatabase _db = getIt<AppDatabase>();
  
  // Переменная для зарплаты
  double _salary = 0.0;
  double get salary => _salary;

  Stream<List<Expense>> get expensesStream => _db.watchAllExpenses();

  ExpenseProvider() {
    _loadSalary(); // Загружаем зарплату при старте
  }

  Future<void> updateExpense(Expense updatedExpense) {
    // В Drift метод updateExpense автоматически найдет запись по ID и заменит её
    return _db.update(_db.expenses).replace(updatedExpense);
  }

  // Загрузка зарплаты из памяти телефона
  Future<void> _loadSalary() async {
    final prefs = await SharedPreferences.getInstance();
    _salary = prefs.getDouble('user_salary') ?? 0.0;
    notifyListeners();
  }

  // Установка новой зарплаты
  Future<void> setSalary(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_salary', amount);
    _salary = amount;
    notifyListeners();
  }

  Future<void> addExpense(String title, double amount, CategoryType category, DateTime date) {
    return _db.insertExpense(
      ExpensesCompanion(
        title: drift.Value(title),
        amount: drift.Value(amount),
        category: drift.Value(category),
        date: drift.Value(date),
      ),
    );
  }

  Future<void> deleteExpense(Expense expense) {
    return _db.deleteExpense(expense);
  }

  Map<CategoryType, double> calculateCategoryTotals(List<Expense> expenses) {
    final Map<CategoryType, double> totals = {};
    for (var expense in expenses) {
      if (totals.containsKey(expense.category)) {
        totals[expense.category] = totals[expense.category]! + expense.amount;
      } else {
        totals[expense.category] = expense.amount;
      }
    }
    return totals;
  }
  
  // Считаем общие расходы
  double calculateTotalSpent(List<Expense> expenses) {
    return expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Считаем остаток (Зарплата - Расходы)
  double calculateBalance(List<Expense> expenses) {
    final spent = calculateTotalSpent(expenses);
    return _salary - spent;
  }

  Map<String, double> calculateMonthlyTotals(List<Expense> expenses) {
    final Map<String, double> monthlyTotals = {};

    // Сортируем по дате, чтобы месяцы шли по порядку
    expenses.sort((a, b) => a.date.compareTo(b.date));

    for (var expense in expenses) {
      // Формат ключа: "Nov" или "11.2025"
      final monthKey = DateFormat('MMM', 'ru').format(expense.date); 
      
      if (monthlyTotals.containsKey(monthKey)) {
        monthlyTotals[monthKey] = monthlyTotals[monthKey]! + expense.amount;
      } else {
        monthlyTotals[monthKey] = expense.amount;
      }
    }
    // Оставляем только последние 6 месяцев, чтобы график не был бесконечным
    if (monthlyTotals.length > 6) {
      final keys = monthlyTotals.keys.toList();
      final last6 = keys.sublist(keys.length - 6);
      final Map<String, double> result = {};
      for (var k in last6) {
        result[k] = monthlyTotals[k]!;
      }
      return result;
    }
    
    return monthlyTotals;
  }

  // --- 2. МАССОВЫЙ ИМПОРТ (Для Excel) ---
  Future<void> importExpensesBatch(List<ExpensesCompanion> newExpenses) async {
    await _db.batch((batch) {
      batch.insertAll(_db.expenses, newExpenses);
    });
    notifyListeners();
  }

  Map<String, List<Expense>> groupExpensesByMonth(List<Expense> expenses) {
    final Map<String, List<Expense>> grouped = {};

    // Сортируем: сначала новые
    expenses.sort((a, b) => b.date.compareTo(a.date));

    for (var expense in expenses) {
      // Ключ: "Ноябрь 2025"
      final monthKey = DateFormat('LLLL yyyy', 'ru').format(expense.date);
      // Делаем первую букву заглавной (ноябрь -> Ноябрь)
      final capitalizedKey = monthKey[0].toUpperCase() + monthKey.substring(1);

      if (!grouped.containsKey(capitalizedKey)) {
        grouped[capitalizedKey] = [];
      }
      grouped[capitalizedKey]!.add(expense);
    }
    return grouped;
  }
}
