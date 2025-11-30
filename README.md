# 💰 Finance Pro (Expense Tracker)

![Flutter](https://img.shields.io/badge/Flutter-3.19-%2302569B?logo=flutter)
![Drift](https://img.shields.io/badge/Database-Drift_(SQLite)-%2300599C?logo=sqlite)
![Analytics](https://img.shields.io/badge/Analytics-FL_Chart-%23ff4081)
![Excel](https://img.shields.io/badge/Integration-Excel_Import%2FExport-%23217346?logo=microsoft-excel)

Продвинутый инструмент для управления личными финансами. Приложение позволяет не только фиксировать расходы, но и анализировать бюджет, строить графики и интегрироваться с Excel-таблицами.

> 🌍 **Локализация:** Поддержка валюты (Сомони - с.) и форматов дат СНГ.

---

## 🚀 Ключевые возможности

### 📊 Глубокая Аналитика
* **Круговая диаграмма (Pie Chart):** Наглядное распределение трат по категориям (Еда, Транспорт, Развлечения и др.).
* **Динамика по месяцам (Bar Chart):** Столбчатая диаграмма последних 6 месяцев.
* **Контроль бюджета:** Визуальное сравнение расходов с установленным уровнем дохода (Зарплата).

### 🗄️ Мощная работа с данными (Excel)
* **Умный Импорт:** Алгоритм автоматически распознает категории расходов из Excel-файла по ключевым словам (на русском и английском). Поддерживает различные форматы чисел (запятая/точка).
* **Профессиональный Экспорт:** Генерация `.xlsx` отчета. Данные автоматически разбиваются на отдельные листы (Tabs) по месяцам, с форматированием и подсчетом итогового остатка.

### 💾 Технологии и Архитектура
* **Локальная БД:** Использование **Drift (SQLite)** для надежного хранения данных без интернета.
* **Архитектура:** Clean Architecture с использованием **Provider** для управления состоянием и **GetIt** для внедрения зависимостей (DI).
* **UX/UI:** Удобная шторка ввода (Modal Bottom Sheet), защита от случайного удаления, цветовое кодирование категорий.

## 🛠️ Технический стек

* **Core:** Flutter, Dart
* **Database:** `drift`, `sqlite3_flutter_libs`
* **State Management:** `provider`
* **DI:** `get_it`
* **Charts:** `fl_chart`
* **Files:** `excel`, `file_picker`, `share_plus`, `path_provider`
* **Utils:** `intl`

---

## 📸 Скриншоты

| Главный экран | Ввод данных | Аналитика |
|:---:|:---:|:---:|
| ![Screenshot_20251130-233725](https://github.com/user-attachments/assets/879a9626-7252-4b61-8dee-68f0e48cd0c0) | ![Screenshot_20251130-233758](https://github.com/user-attachments/assets/107542ef-2981-4e19-809c-e662893c46d9) | ![Screenshot_20251130-233848](https://github.com/user-attachments/assets/3d665bbf-2141-4a06-b333-410668d991dc) |

---

## 📂 Структура проекта

```text
lib/
├── data/
│   └── local/             # Drift Database & Tables
├── providers/
│   └── expense_provider.dart # Business Logic (CRUD, Calculations)
├── services/
│   └── excel_service.dart    # Logic for parsing and generating Excel
├── screens/
│   ├── home_screen.dart      # Main list & Balance card
│   └── stats_screen.dart     # Charts & Import/Export actions
├── widgets/
│   ├── add_expense_sheet.dart # Custom Modal Bottom Sheet
│   └── chart_widget.dart      # Reusable Chart Components
├── locator.dart              # Dependency Injection Setup
└── main.dart                 # Entry Point
