import 'package:flutter/material.dart';
import 'package:myapp/models/expense_model.dart';

class ExpenseProvider with ChangeNotifier {
  final List<Expense> _expenses = [];
  double _income = 0.0;

  List<Expense> get expenses => _expenses;
  double get totalExpenses =>
      _expenses.fold(0, (sum, item) => sum + item.amount);
  double get totalIncome => _income;

  void addExpense(Expense expense) {
    _expenses.add(expense);
    notifyListeners();
  }

  void addIncome(double amount) {
    _income += amount;
    notifyListeners();
  }
}
