import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/services/api_service.dart';

class ReportsApiService {
  static const String _baseUrl = 'https://expense-api-gateway-01kd.onrender.com/reports';

  final ApiService _apiService;
  final http.Client _client = http.Client();

  ReportsApiService(this._apiService);

  String? get _accessToken => _apiService.accessToken;

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, String>? params]) {
    final uri = Uri.parse('$_baseUrl$path');
    if (params != null && params.isNotEmpty) {
      return uri.replace(queryParameters: params);
    }
    return uri;
  }

  Future<Map<String, dynamic>> _get(String path, [Map<String, String>? params]) async {
    final uri = _buildUri(path, params);
    debugPrint('ReportsApi GET: $uri');
    final response = await _client.get(uri, headers: _headers()).timeout(const Duration(seconds: 30));
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw Exception(data['message'] ?? 'Request failed with status ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getPersonalTransactions({
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
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (transactionType != null) params['transaction_type'] = transactionType;
    if (loanType != null) params['loan_type'] = loanType;
    if (paymentMode != null) params['payment_mode'] = paymentMode;
    if (category != null) params['category'] = category;
    if (name != null) params['name'] = name;
    if (search != null) params['search'] = search;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (includeDeleted != null) params['include_deleted'] = includeDeleted;
    if (sortBy != null) params['sort_by'] = sortBy;
    if (sortOrder != null) params['sort_order'] = sortOrder;
    return _get('/personal/transactions', params);
  }

  Future<Map<String, dynamic>> getExpenseByCategory({
    String? startDate,
    String? endDate,
    String? includeDeleted,
  }) async {
    final params = <String, String>{};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (includeDeleted != null) params['include_deleted'] = includeDeleted;
    return _get('/personal/category', params);
  }

  Future<Map<String, dynamic>> getPaymentModeReport({
    String? startDate,
    String? endDate,
    String? includeDeleted,
  }) async {
    final params = <String, String>{};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (includeDeleted != null) params['include_deleted'] = includeDeleted;
    return _get('/personal/payment-mode', params);
  }

  Future<Map<String, dynamic>> getBusinessTransactions({
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
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (businessId != null) params['business_id'] = businessId;
    if (transactionType != null) params['transaction_type'] = transactionType;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (includeDeleted != null) params['include_deleted'] = includeDeleted;
    if (sortBy != null) params['sort_by'] = sortBy;
    if (sortOrder != null) params['sort_order'] = sortOrder;
    return _get('/business/transactions', params);
  }

  Future<Map<String, dynamic>> getSalesReport({
    int page = 1,
    int limit = 20,
    String? businessId,
    String? startDate,
    String? endDate,
    String? includeDeleted,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (businessId != null) params['business_id'] = businessId;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (includeDeleted != null) params['include_deleted'] = includeDeleted;
    return _get('/business/sales', params);
  }

  Future<Map<String, dynamic>> getPurchaseReport({
    int page = 1,
    int limit = 20,
    String? businessId,
    String? startDate,
    String? endDate,
    String? includeDeleted,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (businessId != null) params['business_id'] = businessId;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (includeDeleted != null) params['include_deleted'] = includeDeleted;
    return _get('/business/purchases', params);
  }

  Future<Map<String, dynamic>> getExpenseReport({
    int page = 1,
    int limit = 20,
    String? businessId,
    String? startDate,
    String? endDate,
    String? includeDeleted,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (businessId != null) params['business_id'] = businessId;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (includeDeleted != null) params['include_deleted'] = includeDeleted;
    return _get('/business/expenses', params);
  }

  Future<Map<String, dynamic>> getPartySummary({String? businessId}) async {
    final params = <String, String>{};
    if (businessId != null) params['business_id'] = businessId;
    return _get('/party', params);
  }

  Future<Map<String, dynamic>> getTopCustomers({int limit = 10, String? businessId}) async {
    final params = <String, String>{'limit': limit.toString()};
    if (businessId != null) params['business_id'] = businessId;
    return _get('/top-customers', params);
  }

  Future<Map<String, dynamic>> getTopSuppliers({int limit = 10, String? businessId}) async {
    final params = <String, String>{'limit': limit.toString()};
    if (businessId != null) params['business_id'] = businessId;
    return _get('/top-suppliers', params);
  }

  Future<Map<String, dynamic>> getItemSales({
    String? businessId,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, String>{};
    if (businessId != null) params['business_id'] = businessId;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    return _get('/items/sales', params);
  }

  Future<Map<String, dynamic>> getItemPurchases({
    String? businessId,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, String>{};
    if (businessId != null) params['business_id'] = businessId;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    return _get('/items/purchases', params);
  }

  Future<Map<String, dynamic>> getInventory({String? businessId}) async {
    final params = <String, String>{};
    if (businessId != null) params['business_id'] = businessId;
    return _get('/inventory', params);
  }

  Future<Map<String, dynamic>> getGstSummary({
    String? businessId,
    String? startDate,
    String? endDate,
    String? includeDeleted,
  }) async {
    final params = <String, String>{};
    if (businessId != null) params['business_id'] = businessId;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (includeDeleted != null) params['include_deleted'] = includeDeleted;
    return _get('/gst', params);
  }

  Future<Map<String, dynamic>> getGstDetails({
    int page = 1,
    int limit = 20,
    String? businessId,
    String? transactionType,
    String? startDate,
    String? endDate,
    String? includeDeleted,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (businessId != null) params['business_id'] = businessId;
    if (transactionType != null) params['transaction_type'] = transactionType;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (includeDeleted != null) params['include_deleted'] = includeDeleted;
    return _get('/gst/details', params);
  }

  Future<Map<String, dynamic>> getProfitLoss({
    String? businessId,
    String? startDate,
    String? endDate,
    String? includeDeleted,
  }) async {
    final params = <String, String>{};
    if (businessId != null) params['business_id'] = businessId;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (includeDeleted != null) params['include_deleted'] = includeDeleted;
    return _get('/profit-loss', params);
  }

  Future<Map<String, dynamic>> getCashFlow({
    String? businessId,
    String? startDate,
    String? endDate,
    String? includeDeleted,
  }) async {
    final params = <String, String>{};
    if (businessId != null) params['business_id'] = businessId;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (includeDeleted != null) params['include_deleted'] = includeDeleted;
    return _get('/cash-flow', params);
  }

  Future<Map<String, dynamic>> getMonthlyTrend({
    String? businessId,
    String? startDate,
    String? endDate,
    String? includeDeleted,
  }) async {
    final params = <String, String>{};
    if (businessId != null) params['business_id'] = businessId;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (includeDeleted != null) params['include_deleted'] = includeDeleted;
    return _get('/monthly', params);
  }

  Future<Map<String, dynamic>> getDashboard({
    String? businessId,
    String? startDate,
    String? endDate,
    String? includeDeleted,
  }) async {
    final params = <String, String>{};
    if (businessId != null) params['business_id'] = businessId;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (includeDeleted != null) params['include_deleted'] = includeDeleted;
    return _get('/dashboard', params);
  }

  Future<Map<String, dynamic>> getHistory({
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
    String? includeDeleted,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (includeDeleted != null) params['include_deleted'] = includeDeleted;
    return _get('/history', params);
  }

  void dispose() {
    _client.close();
  }
}
