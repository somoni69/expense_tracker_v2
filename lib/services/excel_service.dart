import 'dart:io';
import 'package:drift/drift.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../data/local/database.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ExcelService {
  Future<void> exportToExcel(
    List<Expense> expenses,
    double monthlyIncome,
  ) async {
    final excel = Excel.createExcel();

    // Удаляем дефолтный лист "Sheet1", мы создадим свои
    excel.delete('Sheet1');

    // 1. Группируем данные (используем логику, аналогичную провайдеру)
    // Дублируем логику группировки здесь или передаем уже сгруппированные данные.
    // Для надежности сгруппируем тут же:
    expenses.sort((a, b) => b.date.compareTo(a.date));
    final Map<String, List<Expense>> grouped = {};
    for (var e in expenses) {
      final key = DateFormat('LLLL yyyy', 'ru').format(e.date);
      final capitalized = key[0].toUpperCase() + key.substring(1);
      if (!grouped.containsKey(capitalized)) grouped[capitalized] = [];
      grouped[capitalized]!.add(e);
    }

    // 2. Создаем стиль для ЗАГОЛОВКОВ (BOLD)
    final headerStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.blue200, // Немного цвета для красоты
    );

    // 3. Пробегаемся по каждому месяцу и создаем лист
    for (var monthName in grouped.keys) {
      final sheet = excel[monthName]; // Создаем лист с именем месяца
      final monthExpenses = grouped[monthName]!;

      // --- ЗАГОЛОВКИ (Жирные) ---
      final headerRow = ['Название', 'Сумма (с.)', 'Дата', 'Категория'];

      sheet.appendRow(headerRow.map((e) => TextCellValue(e)).toList());

      // Применяем стиль к первой строке (A1, B1, C1, D1)
      for (int i = 0; i < headerRow.length; i++) {
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
                .cellStyle =
            headerStyle;
      }

      // --- ДАННЫЕ ---
      double totalExpense = 0;
      for (var expense in monthExpenses) {
        totalExpense += expense.amount;
        sheet.appendRow([
          TextCellValue(expense.title),
          DoubleCellValue(expense.amount),
          TextCellValue(DateFormat('dd.MM.yyyy').format(expense.date)),
          TextCellValue(expense.category.name.toUpperCase()),
        ]);
      }

      // --- ИТОГИ МЕСЯЦА (Отступаем строчку) ---
      sheet.appendRow([TextCellValue('')]); // Пустая строка

      // Стиль для итогов
      final summaryStyle = CellStyle(
        bold: true,
        fontFamily: getFontFamily(FontFamily.Calibri),
      );

      // Доход
      sheet.appendRow([
        TextCellValue('Доход (ЗП):'),
        DoubleCellValue(monthlyIncome),
      ]);
      sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: 0,
                  rowIndex: sheet.maxRows - 1,
                ),
              )
              .cellStyle =
          summaryStyle;

      // Расход
      sheet.appendRow([
        TextCellValue('Всего расходов:'),
        DoubleCellValue(totalExpense),
      ]);
      sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: 0,
                  rowIndex: sheet.maxRows - 1,
                ),
              )
              .cellStyle =
          summaryStyle;

      // Остаток
      double balance = monthlyIncome - totalExpense;
      sheet.appendRow([TextCellValue('Остаток:'), DoubleCellValue(balance)]);

      // Красим остаток: Если минус — красный, плюс — зеленый (в Excel это сложно через либу, просто сделаем Bold)
      sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: 0,
                  rowIndex: sheet.maxRows - 1,
                ),
              )
              .cellStyle =
          summaryStyle;
      sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: 1,
                  rowIndex: sheet.maxRows - 1,
                ),
              )
              .cellStyle =
          summaryStyle;
    }

    // 4. Сохраняем
    final fileBytes = excel.save();
    if (fileBytes != null) {
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/Финансы_Отчет.xlsx";
      final file = File(path);
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles([
        XFile(path),
      ], text: 'Финансовый отчет по месяцам');
    }
  }

  // Метод возвращает список готовых к записи объектов или выбрасывает ошибку
  Future<List<ExpensesCompanion>> pickAndParseExcel() async {
    // 1. Выбор файла
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null) return []; // Пользователь отменил выбор

    final File file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();
    final Excel excel = Excel.decodeBytes(bytes);

    final List<ExpensesCompanion> parsedExpenses = [];

    // 2. Читаем первый лист
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];

    if (sheet == null) throw Exception('Excel файл пуст');

    // Пропускаем заголовок (первая строка), начинаем с 1
    for (var i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.isEmpty) continue;

      // ОЖИДАЕМЫЙ ФОРМАТ:
      // Колонка A (0): Название
      // Колонка B (1): Сумма
      // Колонка C (2): Дата (дд.мм.гггг)
      // Колонка D (3): Категория (опционально, иначе "other")

      try {
        // --- ПАРСИНГ НАЗВАНИЯ ---
        final titleCell = row[0]?.value;
        if (titleCell == null) continue;
        final title = titleCell.toString();

        // --- ПАРСИНГ СУММЫ (ИСПРАВЛЕНО) ---
        final amountCell = row[1]?.value;
        double amount = 0.0;

        if (amountCell is double) {
          amount = amountCell as double;
        } else if (amountCell is int) {
          amount = (amountCell as int).toDouble();
        } else if (amountCell != null) {
          // Превращаем в строку
          String amountStr = amountCell.toString();

          // 1. Удаляем пробелы (иногда Excel пишет "1 000")
          // \u00A0 - это неразрывный пробел, который тоже бывает в Excel
          amountStr = amountStr.replaceAll(' ', '').replaceAll('\u00A0', '');

          // 2. Заменяем запятую на точку
          amountStr = amountStr.replaceAll(',', '.');

          // 3. Парсим
          amount = double.tryParse(amountStr) ?? 0.0;
        }

        // --- ПАРСИНГ ДАТЫ ---
        final dateCell = row[2];
        DateTime date = DateTime.now();

        if (dateCell?.value is DateTime) {
          date =
              dateCell!.value as DateTime; // Excel сам может хранить как дату
        } else if (dateCell?.value is String) {
          // Пытаемся прочитать текстовую дату "25.11.2025"
          try {
            date = DateFormat('dd.MM.yyyy').parse(dateCell!.value as String);
          } catch (_) {}
        }

        // --- ПАРСИНГ КАТЕГОРИИ (Улучшенный) ---
        // 1. Получаем строку, убираем пробелы по краям и делаем маленькими буквами
        String catStr = row[3]?.value?.toString() ?? '';
        catStr = catStr.trim().toLowerCase();

        CategoryType category = CategoryType.other; // По умолчанию "Другое"

        // 2. Проверяем по ключевым словам (Русский + Английский)

        // ЕДА (Food)
        if (catStr.contains('food') ||
            catStr.contains('ед') ||
            catStr.contains('продукт') ||
            catStr.contains('кушат')) {
          category = CategoryType.food;
        }
        // ТРАНСПОРТ (Transport)
        else if (catStr.contains('transport') ||
            catStr.contains('транс') ||
            catStr.contains('taxi') ||
            catStr.contains('такси') ||
            catStr.contains('auto') ||
            catStr.contains('авто')) {
          category = CategoryType.transport;
        }
        // ПОКУПКИ (Shopping)
        else if (catStr.contains('shop') ||
            catStr.contains('покуп') ||
            catStr.contains('одежд') ||
            catStr.contains('вещ')) {
          category = CategoryType.shopping;
        }
        // СЧЕТА (Bills)
        else if (catStr.contains('bill') ||
            catStr.contains('счет') ||
            catStr.contains('коммун') ||
            catStr.contains('связь') ||
            catStr.contains('интернет')) {
          category = CategoryType.bills;
        }
        // РАЗВЛЕЧЕНИЯ (Entertainment) - Вот то, чего не хватало!
        else if (catStr.contains('entertain') ||
            catStr.contains('развлеч') ||
            catStr.contains('кино') ||
            catStr.contains('кафе') ||
            catStr.contains('fun')) {
          category = CategoryType.entertainment;
        }

        // Собираем объект
        parsedExpenses.add(
          ExpensesCompanion(
            title: Value(title),
            amount: Value(amount),
            date: Value(date),
            category: Value(category),
          ),
        );
      } catch (e) {
        print('Ошибка в строке $i: $e');
        // Можно пропустить строку и идти дальше
      }
    }

    return parsedExpenses;
  }
}
