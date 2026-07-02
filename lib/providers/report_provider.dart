import 'package:flutter/material.dart';
import 'package:myapp/models/report_models.dart';
import 'package:myapp/services/reports_api_service.dart';

class ReportProvider with ChangeNotifier {
  final ReportsApiService _api;

  ReportProvider(this._api);

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Dashboard
  DashboardReport? _dashboard;
  DashboardReport? get dashboard => _dashboard;

  // Personal
  List<PersonalTransactionReport> _personalTransactions = [];
  List<CategoryReport> _categoryReports = [];
  List<PaymentModeReport> _paymentModeReports = [];
  PaginationInfo? _personalPagination;

  List<PersonalTransactionReport> get personalTransactions => _personalTransactions;
  List<CategoryReport> get categoryReports => _categoryReports;
  List<PaymentModeReport> get paymentModeReports => _paymentModeReports;
  PaginationInfo? get personalPagination => _personalPagination;

  // Business
  List<BusinessTransactionReport> _businessTransactions = [];
  List<SaleReport> _sales = [];
  List<PurchaseReport> _purchases = [];
  List<ExpenseReport> _businessExpenses = [];
  PaginationInfo? _businessPagination;
  PaginationInfo? _salesPagination;
  PaginationInfo? _purchasesPagination;
  PaginationInfo? _expensesPagination;

  List<BusinessTransactionReport> get businessTransactions => _businessTransactions;
  List<SaleReport> get sales => _sales;
  List<PurchaseReport> get purchases => _purchases;
  List<ExpenseReport> get businessExpenses => _businessExpenses;
  PaginationInfo? get businessPagination => _businessPagination;
  PaginationInfo? get salesPagination => _salesPagination;
  PaginationInfo? get purchasesPagination => _purchasesPagination;
  PaginationInfo? get expensesPagination => _expensesPagination;

  // Party
  List<PartySummary> _partySummaries = [];
  List<TopCustomer> _topCustomers = [];
  List<TopSupplier> _topSuppliers = [];

  List<PartySummary> get partySummaries => _partySummaries;
  List<TopCustomer> get topCustomers => _topCustomers;
  List<TopSupplier> get topSuppliers => _topSuppliers;

  // Items
  List<ItemSaleReport> _itemSales = [];
  List<ItemPurchaseReport> _itemPurchases = [];
  List<InventoryReport> _inventory = [];

  List<ItemSaleReport> get itemSales => _itemSales;
  List<ItemPurchaseReport> get itemPurchases => _itemPurchases;
  List<InventoryReport> get inventory => _inventory;

  // GST
  GstSummary? _gstSummary;
  List<GstDetail> _gstDetails = [];
  PaginationInfo? _gstPagination;

  GstSummary? get gstSummary => _gstSummary;
  List<GstDetail> get gstDetails => _gstDetails;
  PaginationInfo? get gstPagination => _gstPagination;

  // Financial
  ProfitLossReport? _profitLoss;
  List<CashFlowEntry> _cashFlow = [];
  List<MonthlyTrend> _monthlyTrends = [];

  ProfitLossReport? get profitLoss => _profitLoss;
  List<CashFlowEntry> get cashFlow => _cashFlow;
  List<MonthlyTrend> get monthlyTrends => _monthlyTrends;

  // History
  List<CombinedHistoryEntry> _history = [];
  PaginationInfo? _historyPagination;

  List<CombinedHistoryEntry> get history => _history;
  PaginationInfo? get historyPagination => _historyPagination;

  void _setLoading() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _done() {
    _isLoading = false;
    notifyListeners();
  }

  void _fail(String msg) {
    _isLoading = false;
    _error = msg;
    notifyListeners();
  }

  Future<void> fetchDashboard({
    String? businessId,
    String? startDate,
    String? endDate,
    String? includeDeleted,
  }) async {
    _setLoading();
    try {
      final res = await _api.getDashboard(
        businessId: businessId, startDate: startDate, endDate: endDate, includeDeleted: includeDeleted,
      );
      _dashboard = DashboardReport.fromJson(res['data'] ?? {});
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  Future<void> fetchPersonalTransactions({
    int page = 1,
    int limit = 20,
    String? transactionType,
    String? loanType,
    String? paymentMode,
    String? category,
    String? name,
    String? search,
    String? startDate,
    String? endDate,
    String? includeDeleted,
    String? sortBy,
    String? sortOrder,
  }) async {
    _setLoading();
    try {
      final res = await _api.getPersonalTransactions(
        page: page, limit: limit, transactionType: transactionType, loanType: loanType,
        paymentMode: paymentMode, category: category, name: name, search: search,
        startDate: startDate, endDate: endDate, includeDeleted: includeDeleted,
        sortBy: sortBy, sortOrder: sortOrder,
      );
      final data = (res['data'] as List?)?.map((j) => PersonalTransactionReport.fromJson(j)).toList() ?? [];
      final pagination = res['pagination'] != null ? PaginationInfo.fromJson(res['pagination']) : null;
      if (page == 1) {
        _personalTransactions = data;
      } else {
        _personalTransactions.addAll(data);
      }
      _personalPagination = pagination;
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  Future<void> fetchCategoryReports({
    String? startDate, String? endDate, String? includeDeleted,
  }) async {
    _setLoading();
    try {
      final res = await _api.getExpenseByCategory(startDate: startDate, endDate: endDate, includeDeleted: includeDeleted);
      _categoryReports = (res['data'] as List?)?.map((j) => CategoryReport.fromJson(j)).toList() ?? [];
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  Future<void> fetchPaymentModeReports({
    String? startDate, String? endDate, String? includeDeleted,
  }) async {
    _setLoading();
    try {
      final res = await _api.getPaymentModeReport(startDate: startDate, endDate: endDate, includeDeleted: includeDeleted);
      _paymentModeReports = (res['data'] as List?)?.map((j) => PaymentModeReport.fromJson(j)).toList() ?? [];
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  Future<void> fetchBusinessTransactions({
    int page = 1,
    int limit = 20,
    String? businessId,
    String? transactionType,
    String? startDate,
    String? endDate,
    String? includeDeleted,
    String? sortBy,
    String? sortOrder,
  }) async {
    _setLoading();
    try {
      final res = await _api.getBusinessTransactions(
        page: page, limit: limit, businessId: businessId, transactionType: transactionType,
        startDate: startDate, endDate: endDate, includeDeleted: includeDeleted,
        sortBy: sortBy, sortOrder: sortOrder,
      );
      final data = (res['data'] as List?)?.map((j) => BusinessTransactionReport.fromJson(j)).toList() ?? [];
      final pagination = res['pagination'] != null ? PaginationInfo.fromJson(res['pagination']) : null;
      if (page == 1) {
        _businessTransactions = data;
      } else {
        _businessTransactions.addAll(data);
      }
      _businessPagination = pagination;
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  Future<void> fetchSales({
    int page = 1,
    int limit = 20,
    String? businessId,
    String? startDate,
    String? endDate,
    String? includeDeleted,
  }) async {
    _setLoading();
    try {
      final res = await _api.getSalesReport(
        page: page, limit: limit, businessId: businessId, startDate: startDate, endDate: endDate, includeDeleted: includeDeleted,
      );
      final data = (res['data'] as List?)?.map((j) => SaleReport.fromJson(j)).toList() ?? [];
      final pagination = res['pagination'] != null ? PaginationInfo.fromJson(res['pagination']) : null;
      if (page == 1) {
        _sales = data;
      } else {
        _sales.addAll(data);
      }
      _salesPagination = pagination;
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  Future<void> fetchPurchases({
    int page = 1,
    int limit = 20,
    String? businessId,
    String? startDate,
    String? endDate,
    String? includeDeleted,
  }) async {
    _setLoading();
    try {
      final res = await _api.getPurchaseReport(
        page: page, limit: limit, businessId: businessId, startDate: startDate, endDate: endDate, includeDeleted: includeDeleted,
      );
      final data = (res['data'] as List?)?.map((j) => PurchaseReport.fromJson(j)).toList() ?? [];
      final pagination = res['pagination'] != null ? PaginationInfo.fromJson(res['pagination']) : null;
      if (page == 1) {
        _purchases = data;
      } else {
        _purchases.addAll(data);
      }
      _purchasesPagination = pagination;
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  Future<void> fetchBusinessExpenses({
    int page = 1,
    int limit = 20,
    String? businessId,
    String? startDate,
    String? endDate,
    String? includeDeleted,
  }) async {
    _setLoading();
    try {
      final res = await _api.getExpenseReport(
        page: page, limit: limit, businessId: businessId, startDate: startDate, endDate: endDate, includeDeleted: includeDeleted,
      );
      final data = (res['data'] as List?)?.map((j) => ExpenseReport.fromJson(j)).toList() ?? [];
      final pagination = res['pagination'] != null ? PaginationInfo.fromJson(res['pagination']) : null;
      if (page == 1) {
        _businessExpenses = data;
      } else {
        _businessExpenses.addAll(data);
      }
      _expensesPagination = pagination;
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  Future<void> fetchPartySummary({String? businessId}) async {
    _setLoading();
    try {
      final res = await _api.getPartySummary(businessId: businessId);
      _partySummaries = (res['data'] as List?)?.map((j) => PartySummary.fromJson(j)).toList() ?? [];
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  Future<void> fetchTopCustomers({int limit = 10, String? businessId}) async {
    _setLoading();
    try {
      final res = await _api.getTopCustomers(limit: limit, businessId: businessId);
      _topCustomers = (res['data'] as List?)?.map((j) => TopCustomer.fromJson(j)).toList() ?? [];
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  Future<void> fetchTopSuppliers({int limit = 10, String? businessId}) async {
    _setLoading();
    try {
      final res = await _api.getTopSuppliers(limit: limit, businessId: businessId);
      _topSuppliers = (res['data'] as List?)?.map((j) => TopSupplier.fromJson(j)).toList() ?? [];
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  Future<void> fetchItemSales({
    String? businessId, String? startDate, String? endDate,
  }) async {
    _setLoading();
    try {
      final res = await _api.getItemSales(businessId: businessId, startDate: startDate, endDate: endDate);
      _itemSales = (res['data'] as List?)?.map((j) => ItemSaleReport.fromJson(j)).toList() ?? [];
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  Future<void> fetchItemPurchases({
    String? businessId, String? startDate, String? endDate,
  }) async {
    _setLoading();
    try {
      final res = await _api.getItemPurchases(businessId: businessId, startDate: startDate, endDate: endDate);
      _itemPurchases = (res['data'] as List?)?.map((j) => ItemPurchaseReport.fromJson(j)).toList() ?? [];
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  Future<void> fetchInventory({String? businessId}) async {
    _setLoading();
    try {
      final res = await _api.getInventory(businessId: businessId);
      _inventory = (res['data'] as List?)?.map((j) => InventoryReport.fromJson(j)).toList() ?? [];
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  Future<void> fetchGstSummary({
    String? businessId, String? startDate, String? endDate, String? includeDeleted,
  }) async {
    _setLoading();
    try {
      final res = await _api.getGstSummary(businessId: businessId, startDate: startDate, endDate: endDate, includeDeleted: includeDeleted);
      _gstSummary = GstSummary.fromJson(res['data'] ?? {});
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  Future<void> fetchGstDetails({
    int page = 1,
    int limit = 20,
    String? businessId,
    String? transactionType,
    String? startDate,
    String? endDate,
    String? includeDeleted,
  }) async {
    _setLoading();
    try {
      final res = await _api.getGstDetails(
        page: page, limit: limit, businessId: businessId, transactionType: transactionType,
        startDate: startDate, endDate: endDate, includeDeleted: includeDeleted,
      );
      final data = (res['data'] as List?)?.map((j) => GstDetail.fromJson(j)).toList() ?? [];
      final pagination = res['pagination'] != null ? PaginationInfo.fromJson(res['pagination']) : null;
      if (page == 1) {
        _gstDetails = data;
      } else {
        _gstDetails.addAll(data);
      }
      _gstPagination = pagination;
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  Future<void> fetchProfitLoss({
    String? businessId, String? startDate, String? endDate, String? includeDeleted,
  }) async {
    _setLoading();
    try {
      final res = await _api.getProfitLoss(businessId: businessId, startDate: startDate, endDate: endDate, includeDeleted: includeDeleted);
      _profitLoss = ProfitLossReport.fromJson(res['data'] ?? {});
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  Future<void> fetchCashFlow({
    String? businessId, String? startDate, String? endDate, String? includeDeleted,
  }) async {
    _setLoading();
    try {
      final res = await _api.getCashFlow(businessId: businessId, startDate: startDate, endDate: endDate, includeDeleted: includeDeleted);
      _cashFlow = (res['data'] as List?)?.map((j) => CashFlowEntry.fromJson(j)).toList() ?? [];
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  Future<void> fetchMonthlyTrends({
    String? businessId, String? startDate, String? endDate, String? includeDeleted,
  }) async {
    _setLoading();
    try {
      final res = await _api.getMonthlyTrend(businessId: businessId, startDate: startDate, endDate: endDate, includeDeleted: includeDeleted);
      _monthlyTrends = (res['data'] as List?)?.map((j) => MonthlyTrend.fromJson(j)).toList() ?? [];
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  Future<void> fetchHistory({
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
    String? includeDeleted,
  }) async {
    _setLoading();
    try {
      final res = await _api.getHistory(page: page, limit: limit, startDate: startDate, endDate: endDate, includeDeleted: includeDeleted);
      final data = (res['data'] as List?)?.map((j) => CombinedHistoryEntry.fromJson(j)).toList() ?? [];
      final pagination = res['pagination'] != null ? PaginationInfo.fromJson(res['pagination']) : null;
      if (page == 1) {
        _history = data;
      } else {
        _history.addAll(data);
      }
      _historyPagination = pagination;
      _done();
    } catch (e) { _fail(e.toString()); }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
