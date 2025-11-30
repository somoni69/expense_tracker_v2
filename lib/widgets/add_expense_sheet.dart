import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/local/database.dart';
import '../providers/expense_provider.dart';

class AddExpenseSheet extends StatefulWidget {
  // Добавляем параметр: если он не null, значит мы РЕДАКТИРУЕМ
  final Expense? expenseToEdit;

  const AddExpenseSheet({super.key, this.expenseToEdit});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  CategoryType _selectedCategory = CategoryType.food;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Если нам передали расход для редактирования — заполняем поля
    if (widget.expenseToEdit != null) {
      final e = widget.expenseToEdit!;
      _titleController.text = e.title;
      _amountController.text = e.amount.toString();
      _selectedCategory = e.category;
      _selectedDate = e.date;
    }
  }

  // ... (методы _getCategoryIcon и _getCategoryColor оставляем те же, скопируй их)
  IconData _getCategoryIcon(CategoryType type) {
    switch (type) {
      case CategoryType.food: return Icons.fastfood;
      case CategoryType.transport: return Icons.directions_car;
      case CategoryType.shopping: return Icons.shopping_bag;
      case CategoryType.bills: return Icons.receipt;
      case CategoryType.entertainment: return Icons.movie;
      case CategoryType.other: return Icons.more_horiz;
    }
  }

  Color _getCategoryColor(CategoryType type) {
    switch (type) {
      case CategoryType.food: return Colors.orange;
      case CategoryType.transport: return Colors.blue;
      case CategoryType.shopping: return Colors.purple;
      case CategoryType.bills: return Colors.red;
      case CategoryType.entertainment: return Colors.green;
      case CategoryType.other: return Colors.grey;
    }
  }

  Future<void> _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitData() {
    final enteredTitle = _titleController.text;
    final enteredAmount = double.tryParse(_amountController.text);

    if (enteredTitle.isEmpty || enteredAmount == null || enteredAmount <= 0) {
      return;
    }

    final provider = Provider.of<ExpenseProvider>(context, listen: false);

    if (widget.expenseToEdit != null) {
      // --- РЕДАКТИРОВАНИЕ ---
      // Создаем копию старого объекта с новыми данными
      final updatedExpense = widget.expenseToEdit!.copyWith(
        title: enteredTitle,
        amount: enteredAmount,
        category: _selectedCategory,
        date: _selectedDate,
      );
      provider.updateExpense(updatedExpense);
    } else {
      // --- СОЗДАНИЕ НОВОГО ---
      provider.addExpense(
        enteredTitle,
        enteredAmount,
        _selectedCategory,
        _selectedDate,
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    // Меняем заголовок в зависимости от режима
    final isEditing = widget.expenseToEdit != null;

    return LayoutBuilder(builder: (ctx, constraints) {
      return SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, keyboardSpace + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                isEditing ? 'Редактировать расход' : 'Новый расход',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // ... (весь код полей ввода остаётся таким же, как в прошлом шаге)
              // Скопируй сюда Row с Названием/Суммой и Row с Категорией/Датой
              // Я не дублирую его, чтобы не спамить, он идентичен
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _titleController,
                      maxLength: 50,
                      decoration: const InputDecoration(
                        labelText: 'Название',
                        hintText: 'Например: Такси',
                        border: OutlineInputBorder(),
                        counterText: "",
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Сумма',
                        suffixText: ' с.', // Валюта
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<CategoryType>(
                      value: _selectedCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Категория',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      ),
                      items: CategoryType.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Icon(_getCategoryIcon(category), size: 18, color: _getCategoryColor(category)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  category.name.toUpperCase(),
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: _presentDatePicker,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 58,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('dd.MM.yy').format(_selectedDate)),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _submitData,
                    icon: const Icon(Icons.save),
                    label: const Text('Сохранить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}