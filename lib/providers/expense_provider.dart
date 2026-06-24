import 'package:flutter/material.dart';
import 'package:myapp/services/api_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ApiService _apiService;

  // ==================
  // VARIABLES
  // ==================

  // Personal transactions from backend
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

  // Error state
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ==================
  // CONSTRUCTOR
  // ==================

  ExpenseProvider(this._apiService);

  // ==================
  // API METHODS
  // ==================

  /// Fetch summary from backend
  Future<void> fetchSummary() async {
    _isLoadingSummary = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getSummary();

      // Support both response formats:
      // { total_income, total_expense, total_loan, net_balance }
      // { success: true, data: { total_income, ... } }
      if (response is Map && response.containsKey('data')) {
        _summary = response['data'] as Map<String, dynamic>?;
      } else {
        _summary = response as Map<String, dynamic>?;
      }

      _isLoadingSummary = false;
      notifyListeners();
    } catch (e) {
      _isLoadingSummary = false;
      _errorMessage = e.toString();
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
      await refreshAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Send reminder for transaction
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

  // ==================
  // HELPER METHODS
  // ==================

  /// Get summary value with type conversion and fallback
  double getSummaryValue(String key, {double fallback = 0.0}) {
    if (_summary == null) return fallback;
    final value = _summary![key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  /// Get total balance from summary
  double get totalBalance => getSummaryValue('net_balance');

  /// Get total income from summary
  double get totalIncome => getSummaryValue('total_income');

  /// Get total expense from summary
  double get totalExpense => getSummaryValue('total_expense');

  /// Get total loan amount from summary
  double get totalLoan => getSummaryValue('total_loan');

  // ==================
  // ERROR HANDLING
  // ==================

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}