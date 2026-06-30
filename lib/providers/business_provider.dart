import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/models/business_models.dart';
import 'package:myapp/services/api_service.dart';

class BusinessProvider extends ChangeNotifier {
  final ApiService _apiService;
  static const String _selectedBusinessIdKey = 'selected_business_id';

  BusinessProvider(this._apiService);

  // ==================
  // BUSINESS STATE
  // ==================
  List<BusinessModel> _businesses = [];
  List<BusinessModel> get businesses => _businesses;

  BusinessModel? _selectedBusiness;
  BusinessModel? get selectedBusiness => _selectedBusiness;

  // ==================
  // TRANSACTIONS STATE
  // ==================
  List<Map<String, dynamic>> _businessTransactions = [];
  List<Map<String, dynamic>> get businessTransactions => _businessTransactions;

  // ==================
  // ITEMS STATE
  // ==================
  List<CatalogItemModel> _catalogItems = [];
  List<CatalogItemModel> get catalogItems => _catalogItems;

  // ==================
  // PARTIES STATE
  // ==================
  List<PartyModel> _parties = [];
  List<PartyModel> get parties => _parties;

  // ==================
  // PAGINATION STATE
  // ==================
  int _currentPage = 1;

  // ==================
  // BUSINESS APIs
  // ==================

  /// Fetch all businesses for the current user
  Future<void> fetchBusinesses() async {
    _isLoadingBusinesses = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getAllBusinesses();
      final data = response is List
          ? response
          : (response['data'] as List? ?? response['businesses'] as List? ?? []);
      _businesses = data.map((json) => BusinessModel.fromJson(json)).toList();
      _isLoadingBusinesses = false;
      notifyListeners();
    } catch (e) {
      _isLoadingBusinesses = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Create a new business
  Future<bool> createBusiness(String name, {String? phone, String? email, String? gstin, String? address}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = {
        'business_name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (gstin != null) 'gstin': gstin,
        if (address != null) 'address': address,
      };
      final response = await _apiService.createBusiness(data);
      if (response['data'] != null) {
        final newBusiness = BusinessModel.fromJson(response['data']);
        _businesses.add(newBusiness);
        _selectedBusiness = newBusiness;
      }
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Set the selected business
  Future<void> selectBusiness(BusinessModel? business) async {
    _selectedBusiness = business;
    if (business != null) {
      await _saveSelectedBusinessId(business.business_id);
      fetchBusinessTransactions();
      fetchCatalogItems();
      fetchParties();
    } else {
      await _saveSelectedBusinessId(null);
      _businessTransactions = [];
      _catalogItems = [];
      _parties = [];
    }
    notifyListeners();
  }

  /// Save selected business ID to SharedPreferences
  Future<void> _saveSelectedBusinessId(String? businessId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (businessId != null) {
        await prefs.setString(_selectedBusinessIdKey, businessId);
      } else {
        await prefs.remove(_selectedBusinessIdKey);
      }
    } catch (e) {
      debugPrint('Error saving selected business: $e');
    }
  }

  /// Load last selected business ID from SharedPreferences
  Future<String?> getLastSelectedBusinessId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_selectedBusinessIdKey);
    } catch (e) {
      debugPrint('Error loading selected business: $e');
      return null;
    }
  }

  /// Restore last selected business
  Future<void> restoreLastSelectedBusiness() async {
    final businessId = await getLastSelectedBusinessId();
    if (businessId != null && _businesses.isNotEmpty) {
      final business = _businesses.firstWhere(
        (b) => b.business_id == businessId,
        orElse: () => _businesses.first,
      );
      _selectedBusiness = business;
      fetchBusinessTransactions();
      fetchCatalogItems();
      fetchParties();
      notifyListeners();
    }
  }

  // ==================
  // TRANSACTION APIs
  // ==================

  /// Fetch all business transactions
  Future<void> fetchBusinessTransactions({bool reset = true}) async {
    if (_selectedBusiness == null) {
      _businessTransactions = [];
      notifyListeners();
      return;
    }

    if (reset) {
      _isLoadingTransactions = true;
      _currentPage = 1;
    } else {
      _isLoadingMore = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final params = <String, String>{
        'page': _currentPage.toString(),
        'limit': '20',
        'business_id': _selectedBusiness!.business_id,
      };
      if (_transactionTypeFilter != null) params['transaction_type'] = _transactionTypeFilter!;
      if (_startDateFilter != null) params['start_date'] = _startDateFilter!;
      if (_endDateFilter != null) params['end_date'] = _endDateFilter!;

      final response = await _apiService.getAllBusinessTransactions(params);

      List<Map<String, dynamic>> transactions = [];
      int total = 0;
      int totalPages = 1;
      bool hasNextPage = false;

      if (response is Map<String, dynamic>) {
        if (response['data'] is List) {
          transactions = List<Map<String, dynamic>>.from(response['data']);
        } else if (response['transactions'] is List) {
          transactions = List<Map<String, dynamic>>.from(response['transactions']);
        }
        
        // Ensure __transaction_time is preserved in each transaction
        for (var tx in transactions) {
          // Prioritize __transaction_time, then transaction_time, then time
          if (tx['__transaction_time'] == null) {
            if (tx['transaction_time'] != null) {
              tx['__transaction_time'] = tx['transaction_time'];
            } else if (tx['time'] != null) {
              tx['__transaction_time'] = tx['time'];
            }
          }
        }
        if (response['pagination'] is Map) {
          final pagination = response['pagination'] as Map<String, dynamic>;
          total = (pagination['total'] as num?)?.toInt() ?? transactions.length;
          totalPages = (pagination['total_pages'] as num?)?.toInt() ?? 1;
          hasNextPage = _currentPage < totalPages;
        } else {
          total = transactions.length;
        }
      } else if (response is List) {
        transactions = List<Map<String, dynamic>>.from(response);
        total = transactions.length;
      }

      if (reset) {
        _businessTransactions = transactions;
      } else {
        _businessTransactions.addAll(transactions);
      }

      _totalPages = totalPages;
      _hasMoreData = hasNextPage;

      _isLoadingTransactions = false;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingTransactions = false;
      _isLoadingMore = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Load more transactions for infinite scroll
  Future<void> loadMoreTransactions() async {
    if (_isLoadingMore || !_hasMoreData) return;
    _currentPage++;
    await fetchBusinessTransactions(reset: false);
  }

  /// Add a new business transaction
  Future<bool> addBusinessTransaction(Map<String, dynamic> data) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {

      final response = await _apiService.addBusinessTransaction(data);
      
      if (response is Map<String, dynamic>) {
        final responseData = response['data'] ?? response;
        
      }
    
      
      _isSubmitting = false;
      await fetchBusinessTransactions();
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a business transaction
  Future<bool> deleteBusinessTransaction(String transactionId) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('BusinessProvider: Deleting transaction $transactionId');
      await _apiService.deleteBusinessTransaction(transactionId);
      debugPrint('BusinessProvider: Delete API call succeeded');
      _isSubmitting = false;
      await fetchBusinessTransactions();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('BusinessProvider: Delete failed - $e');
      _isSubmitting = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update a business transaction
  Future<bool> updateBusinessTransaction(String transactionId, Map<String, dynamic> data) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('BusinessProvider: Updating transaction $transactionId');
      debugPrint('BusinessProvider: Update data: $data');
      await _apiService.updateBusinessTransaction(transactionId, data);
      debugPrint('BusinessProvider: Update API call succeeded');
      _isSubmitting = false;
      await fetchBusinessTransactions();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('BusinessProvider: Update failed - $e');
      _isSubmitting = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================
  // CATALOG ITEM APIs
  // ==================

  /// Fetch catalog items for the selected business
  Future<void> fetchCatalogItems() async {
    if (_selectedBusiness == null) {
      _catalogItems = [];
      notifyListeners();
      return;
    }

    _isLoadingItems = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getAllItems(_selectedBusiness!.business_id);
      print("bus pro");
      final data = response is List
          ? response
          : (response['data'] as List? ?? response['items'] as List? ?? []);
      
      print("Raw API data: $data");
      
      _catalogItems = data.map((json) {
        final item = CatalogItemModel.fromJson(json);
        print("Parsed item: ${item.name}, price: ${item.price}");
        return item;
      }).toList();
      
      print("Total catalog items: ${_catalogItems.length}");
      if (_catalogItems.isNotEmpty) {
        print("First item: ${_catalogItems.first.name}, price: ${_catalogItems.first.price}");
      }
      
      _isLoadingItems = false;
      notifyListeners();
    } catch (e) {
      _isLoadingItems = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
    
  }

  /// Create a new catalog item
  Future<bool> createCatalogItem(Map<String, dynamic> data) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.createItem(data);
      if (response['data'] != null) {
        final newItem = CatalogItemModel.fromJson(response['data']);
        _catalogItems.add(newItem);
      }
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================
  // PARTY APIs
  // ==================

  /// Fetch parties for the selected business
  Future<void> fetchParties() async {
    if (_selectedBusiness == null) {
      _parties = [];
      notifyListeners();
      return;
    }

    _isLoadingParties = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getAllParties(_selectedBusiness!.business_id);
      final data = response is List
          ? response
          : (response['data'] as List? ?? response['parties'] as List? ?? []);
      _parties = data.map((json) => PartyModel.fromJson(json)).toList();
      _isLoadingParties = false;
      notifyListeners();
    } catch (e) {
      _isLoadingParties = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Create a new party
  Future<bool> createParty(Map<String, dynamic> data) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.createParty(data);
      if (response['data'] != null) {
        final newParty = PartyModel.fromJson(response['data']);
        _parties.add(newParty);
      }
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================
  // FILTER METHODS
  // ==================

  void setTransactionTypeFilter(String? type) {
    _transactionTypeFilter = type;
    fetchBusinessTransactions();
  }

  void setDateFilter(String? startDate, String? endDate) {
    _startDateFilter = startDate;
    _endDateFilter = endDate;
    fetchBusinessTransactions();
  }

  void clearFilters() {
    _transactionTypeFilter = null;
    _startDateFilter = null;
    _endDateFilter = null;
    fetchBusinessTransactions();
  }

  // ==================
  // REFRESH ALL
  // ==================

  Future<void> refreshAll() async {
    await fetchBusinesses();
    if (_selectedBusiness != null) {
      await Future.wait([
        fetchBusinessTransactions(),
        fetchCatalogItems(),
        fetchParties(),
      ]);
    }
  }

  // ==================
  // ERROR HANDLING
  // ==================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  int get currentPage => _currentPage;
  int _totalPages = 1;
  int get totalPages => _totalPages;
  bool _hasMoreData = false;
  bool get hasMoreData => _hasMoreData;

  // ==================
  // LOADING STATES
  // ==================
  bool _isLoadingBusinesses = false;
  bool get isLoadingBusinesses => _isLoadingBusinesses;

  bool _isLoadingTransactions = false;
  bool get isLoadingTransactions => _isLoadingTransactions;

  bool _isLoadingItems = false;
  bool get isLoadingItems => _isLoadingItems;

  bool _isLoadingParties = false;
  bool get isLoadingParties => _isLoadingParties;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  // ==================
  // ERROR STATE
  // ==================
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ==================
  // FILTER STATE
  // ==================
  String? _transactionTypeFilter;
  String? _startDateFilter;
  String? _endDateFilter;
}
