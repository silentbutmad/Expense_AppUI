import 'package:flutter/material.dart';
import 'package:myapp/models/expense_model.dart';
import 'package:myapp/services/api_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ApiService _apiService;

  // Personal transactions from backend (raw maps)
  List<Map<String, dynamic>> _personalTransactions = [];
  List<Map<String, dynamic>> get personalTransactions => _personalTransactions;

  // Summary from backend
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? get summary => _summary;

  // Loading states
  bool _isLoadingTransactions = false;
  bool _isLoadingSummary = false;
  bool get isLoadingTransactions => _isLoadingTransactions;
  bool get isLoadingSummary => _isLoadingSummary;

  // Error states
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Legacy list for backward compatibility (derived from backend)
  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;

  ExpenseProvider(this._apiService);

  // =========================
  // BACKEND-DRIVEN METHODS
  // =========================

  /// Fetch summary from backend
  Future<void> fetchSummary() async {
    _isLoadingSummary = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getSummary();
      
      // 🔍 DEBUG: Print raw response from backend
      debugPrint('===== BACKEND SUMMARY RESPONSE =====');
      debugPrint('Raw response: $response');
      debugPrint('Response type: ${response.runtimeType}');
      if (response is Map) {
        debugPrint('Response keys: ${response.keys.toList()}');
        debugPrint('Response values: $response');
      }
      debugPrint('=====================================');
      
      // Support both response formats:
      // { total_income, total_expense, total_loan, net_balance }
      // { success: true, data: { total_income, ... } }
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        _summary = response['data'] as Map<String, dynamic>?;
        debugPrint('Extracted summary from data field: $_summary');
      } else {
        _summary = response as Map<String, dynamic>?;
        debugPrint('Using response directly as summary: $_summary');
      }
      
      debugPrint('Final summary stored: $_summary');
      _isLoadingSummary = false;
      notifyListeners();
    } catch (e) {
      _isLoadingSummary = false;
      _errorMessage = e.toString();
      debugPrint('Error fetching summary: $e');
      notifyListeners();
    }
  }

  /// Fetch all personal transactions from backend
  Future<void> fetchPersonalTransactions() async {
    _isLoadingTransactions = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final transactions = await _apiService.getAllPersonalTransactions();
      _personalTransactions = List<Map<String, dynamic>>.from(transactions);
      _isLoadingTransactions = false;
      notifyListeners();
    } catch (e) {
      _isLoadingTransactions = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Fetch transactions by person name
  Future<List<Map<String, dynamic>>> fetchTransactionsByPerson(String name) async {
    try {
      final transactions = await _apiService.getTransactionsByPerson(name);
      return List<Map<String, dynamic>>.from(transactions);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Fetch transaction by ID
  Future<Map<String, dynamic>?> fetchTransactionById(String id) async {
    try {
      final transaction = await _apiService.getTransactionById(id);
      return transaction as Map<String, dynamic>;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Add personal transaction
  Future<bool> addPersonalTransaction(Map<String, dynamic> transactionData) async {
    try {
      await _apiService.addPersonalTransaction(transactionData);
      // Refresh data after adding
      await refreshAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update transaction
  Future<bool> updateTransaction(String id, Map<String, dynamic> data) async {
    try {
      await _apiService.updateTransaction(id, data);
      // Refresh data after updating
      await refreshAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete transaction (soft delete)
  Future<bool> deleteTransaction(String id) async {
    try {
      await _apiService.deleteTransaction(id);
      // Refresh data after deleting
      await refreshAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Send reminder
  Future<bool> sendReminder(String transactionId, String channel) async {
    try {
      await _apiService.sendReminder(transactionId, channel);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Refresh all data (summary and transactions)
  Future<void> refreshAll() async {
    await Future.wait([
      fetchSummary(),
      fetchPersonalTransactions(),
    ]);
  }

  // =========================
  // HELPER METHODS FOR UI
  // =========================

  /// Get summary value with fallback
  double getSummaryValue(String key, {double fallback = 0.0}) {
    if (_summary == null) return fallback;
    final value = _summary![key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  /// Get total balance
  double get totalBalance => getSummaryValue('net_balance');

  /// Get total income
  double get totalIncome => getSummaryValue('total_income');

  /// Get total expense
  double get totalExpense => getSummaryValue('total_expense');

  /// Get total loan amount
  double get totalLoan => getSummaryValue('total_loan');

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // =========================
  // LEGACY METHODS FOR BACKWARD COMPATIBILITY
  // =========================

  /// Get personal expenses (legacy - returns empty list, use personalTransactions instead)
  List<Expense> get personalExpenses => _expenses.where((e) => e.contextType == ContextType.personal).toList();

  /// Get business expenses (legacy)
  List<Expense> get businessExpenses => _expenses.where((e) => e.contextType == ContextType.business).toList();

  /// Get total received (legacy - uses summary)
  double getTotalReceived() {
    return _expenses
        .where((e) =>
            e.contextType == ContextType.personal &&
            e.transactionType == TransactionType.received)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Get total paid (legacy - uses summary)
  double getTotalPaid() {
    return _expenses
        .where((e) =>
            e.contextType == ContextType.personal &&
            e.transactionType == TransactionType.paid)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Get total by category (legacy - uses summary)
  double getTotalByCategory(TransactionCategory category) {
    // Map category to summary key
    switch (category) {
      case TransactionCategory.income:
        return totalIncome;
      case TransactionCategory.expense:
        return totalExpense;
      case TransactionCategory.loan:
        return totalLoan;
    }
  }

  /// Get personal balance (legacy)
  double getPersonalBalance() {
    return getTotalReceived() - getTotalPaid();
  }

  /// Get grand total (legacy)
  double getGrandTotal() {
    return _expenses
        .where((e) => e.contextType == ContextType.personal)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Get unique person names (legacy)
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

  /// Get personal transactions by person (legacy)
  List<Expense> getPersonalTransactionsByPerson(String personName) {
    return _expenses
        .where((e) =>
            e.contextType == ContextType.personal &&
            e.personName != null &&
            e.personName!.toLowerCase() == personName.toLowerCase())
        .toList();
  }

  /// Add expense (legacy - for other screens)
  void addExpense(Expense expense) {
    _expenses.add(expense);
    notifyListeners();
  }

  /// Add income (legacy - for add_income_screen)
  void addIncome(double amount) {
    // This is legacy, in backend-driven app this would be handled by API
    // For now, we'll just notify listeners
    notifyListeners();
  }

  /// Get filtered income (legacy - for reports_screen)
  double getFilteredIncome(DateTime startDate, DateTime endDate) {
    // Legacy method - returns 0 in backend-driven app
    // The reports screen should be updated to use backend APIs
    return 0.0;
  }
}