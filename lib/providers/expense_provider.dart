import 'package:flutter/material.dart';
import 'package:myapp/models/expense_model.dart';

class ExpenseProvider with ChangeNotifier {
  final List<Expense> _expenses = [];
  double _income = 0.0;
  final List<Map<String, dynamic>> _incomeHistory = [];

  List<Expense> get expenses => _expenses;
  double get totalExpenses =>
      _expenses.fold(0.0, (sum, item) => sum + item.amount);
  double get totalIncome => _income;
  List<Map<String, dynamic>> get incomeHistory => _incomeHistory;

  void addExpense(Expense expense) {
    _expenses.add(expense);
    notifyListeners();
  }

  void addIncome(double amount) {
    _income += amount;
    _incomeHistory.add({
      'amount': amount,
      'date': DateTime.now(),
    });
    notifyListeners();
  }

  double getFilteredIncome(DateTime startDate, DateTime endDate) {
    return _incomeHistory
        .where((entry) {
          final date = entry['date'] as DateTime;
          return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
              date.isBefore(endDate.add(const Duration(days: 1)));
        })
        .fold(0.0, (sum, entry) => sum + (entry['amount'] as double));
  }
}
