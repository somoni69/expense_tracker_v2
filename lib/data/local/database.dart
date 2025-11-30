import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

enum CategoryType { food, transport, shopping, bills, entertainment, other }

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 50)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  IntColumn get category => intEnum<CategoryType>()();
}

@DriftDatabase(tables: [Expenses])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Stream<List<Expense>> watchAllExpenses() {
    return (select(
      expenses,
    )..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();
  }

  Future<int> insertExpense(ExpensesCompanion expense) {
    return into(expenses).insert(expense);
  }

  Future<int> deleteExpense(Expense expense) {
    return delete(expenses).delete(expense);
  }

  Future<int> deleteExpenseById(int id) {
    return (delete(expenses)..where((tbl) => tbl.id.equals(id))).go();
  }
}

  LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'finance.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

