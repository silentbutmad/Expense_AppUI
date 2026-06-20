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

  List<Expense> get personalExpenses =>
      _expenses.where((e) => e.contextType == ContextType.personal).toList();

  List<Expense> get businessExpenses =>
      _expenses.where((e) => e.contextType == ContextType.business).toList();

  List<Expense> getPersonalTransactionsByPerson(String personName) {
    return _expenses
        .where((e) =>
            e.contextType == ContextType.personal &&
            e.personName != null &&
            e.personName!.toLowerCase() == personName.toLowerCase())
        .toList();
  }

  double getTotalReceived() {
    return _expenses
        .where((e) =>
            e.contextType == ContextType.personal &&
            e.transactionType == TransactionType.received)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double getTotalPaid() {
    return _expenses
        .where((e) =>
            e.contextType == ContextType.personal &&
            e.transactionType == TransactionType.paid)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double getTotalByCategory(TransactionCategory category) {
    return _expenses
        .where((e) =>
            e.contextType == ContextType.personal &&
            e.transactionCategory == category)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double getPersonalBalance() {
    return getTotalReceived() - getTotalPaid();
  }

  double getGrandTotal() {
    return _expenses
        .where((e) => e.contextType == ContextType.personal)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  List<String> getUniquePersonNames() {
    final names = _expenses
        .where((e) =>
            e.contextType == ContextType.personal &&
            e.personName != null &&
            e.personName!.isNotEmpty)
        .map((e) => e.personName!)
        .toList();
    return names.toSet().toList();
  }

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
