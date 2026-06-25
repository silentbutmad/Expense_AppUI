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

  // Pagination state
  int _currentPage = 1;
  int get currentPage => _currentPage;
  int _totalPages = 1;
  int get totalPages => _totalPages;
  bool _hasMoreData = false;
  bool get hasMoreData => _hasMoreData;

  // Filter state
  String? _searchQuery;
  String? get searchQuery => _searchQuery;
  Map<String, String> _selectedFilters = {};
  Map<String, String> get selectedFilters => _selectedFilters;

  // Loading states
  bool _isLoadingTransactions = false;
  bool _isLoadingSummary = false;
  bool _isLoadingMore = false;
  bool get isLoadingTransactions => _isLoadingTransactions;
  bool get isLoadingSummary => _isLoadingSummary;
  bool get isLoadingMore => _isLoadingMore;

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
    _isLoadingTransactions = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final transactions = await _apiService.getTransactionsByPerson(name);
      _personalTransactions = List<Map<String, dynamic>>.from(transactions);
      _isLoadingTransactions = false;
      notifyListeners();
      return _personalTransactions;
    } catch (e) {
      _isLoadingTransactions = false;
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

  /// Fetch filtered personal transactions with pagination
  Future<void> fetchFilteredTransactions({
    Map<String, String>? filters,
    bool reset = true,
  }) async {
    if (reset) {
      _isLoadingTransactions = true;
      _currentPage = 1;
      _personalTransactions = [];
    } else {
      _isLoadingMore = true;
    }
    
    _errorMessage = null;
    // Only update filters if provided, otherwise keep existing filters
    if (filters != null) {
      _selectedFilters = filters;
    }
    notifyListeners();

    try {
      // For load more, use current page (which was already incremented)
      final pageToFetch = _currentPage;
      
      debugPrint('Fetching page: $pageToFetch, filters: $_selectedFilters');
      
      final response = await _apiService.getAllPersonalTransactionsWithFilters(
        filters: _buildFilterParams(pageToFetch),
      );

      final transactions = List<Map<String, dynamic>>.from(response['transactions'] ?? []);
      final total = response['total'] ?? 0;
      final page = response['page'] ?? 1;
      final limit = response['limit'] ?? 20;
      final totalPages = response['totalPages'] ?? 1;
      final hasNextPage = response['hasNextPage'] ?? false;

      debugPrint('Received page: $page, transactions: ${transactions.length}, hasNextPage: $hasNextPage');

      if (reset) {
        _personalTransactions = transactions;
      } else {
        _personalTransactions.addAll(transactions);
      }

      _currentPage = page;
      _totalPages = totalPages;
      _hasMoreData = hasNextPage;

      _isLoadingTransactions = false;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      _isLoadingTransactions = false;
      _isLoadingMore = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Load more transactions for infinite scroll
  Future<void> loadMoreTransactions() async {
    debugPrint('loadMoreTransactions called - hasMoreData: $_hasMoreData, isLoadingMore: $_isLoadingMore');
    if (_isLoadingMore || !_hasMoreData) {
      debugPrint('Skipping load more - isLoadingMore: $_isLoadingMore, hasMoreData: $_hasMoreData');
      return;
    }
    
    // Increment page before fetching
    _currentPage = _currentPage + 1;
    debugPrint('Loading page $_currentPage');
    
    await fetchFilteredTransactions(reset: false);
  }

  /// Update search query
  Future<void> updateSearchQuery(String? query) async {
    _searchQuery = query;
    if (query != null && query.isNotEmpty) {
      _selectedFilters['search'] = query;
    } else {
      _selectedFilters.remove('search');
    }
    await fetchFilteredTransactions();
  }

  /// Update a specific filter
  Future<void> updateFilter(String key, String? value) async {
    if (value != null && value.isNotEmpty) {
      _selectedFilters[key] = value;
    } else {
      _selectedFilters.remove(key);
    }
    await fetchFilteredTransactions();
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    _selectedFilters = {};
    _searchQuery = null;
    await fetchFilteredTransactions();
  }

  /// Build filter parameters for API call
  Map<String, String> _buildFilterParams([int? pageOverride]) {
    final params = <String, String>{};
    
    // Add pagination
    params['page'] = (pageOverride ?? _currentPage).toString();
    params['limit'] = '20';

    // Add filters
    for (final entry in _selectedFilters.entries) {
      if (entry.key != 'page' && entry.key != 'limit') {
        params[entry.key] = entry.value;
      }
    }

    return params;
  }

  /// Refresh all data (summary and transactions)
  Future<void> refreshAll() async {
    await fetchSummary();
    await fetchFilteredTransactions();
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