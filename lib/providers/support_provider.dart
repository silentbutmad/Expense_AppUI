import 'package:flutter/material.dart';
import 'package:myapp/models/support_models.dart';
import 'package:myapp/services/api_service.dart';

class SupportProvider extends ChangeNotifier {
  final ApiService _apiService;

  SupportProvider(this._apiService);

  // ==================
  // VARIABLES
  // ==================

  // Tickets
  List<TicketModel> _tickets = [];
  List<TicketModel> get tickets => _tickets;

  // Ticket Details
  TicketModel? _selectedTicket;
  TicketModel? get selectedTicket => _selectedTicket;

  // Comments
  List<CommentModel> _comments = [];
  List<CommentModel> get comments => _comments;

  // FAQs
  List<FaqModel> _faqs = [];
  List<FaqModel> get faqs => _faqs;

  // Help Info
  HelpInfoModel? _helpInfo;
  HelpInfoModel? get helpInfo => _helpInfo;

  // Loading states
  bool _isLoadingTickets = false;
  bool get isLoadingTickets => _isLoadingTickets;

  bool _isLoadingTicketDetails = false;
  bool get isLoadingTicketDetails => _isLoadingTicketDetails;

  bool _isLoadingComments = false;
  bool get isLoadingComments => _isLoadingComments;

  bool _isLoadingFaqs = false;
  bool get isLoadingFaqs => _isLoadingFaqs;

  bool _isLoadingHelpInfo = false;
  bool get isLoadingHelpInfo => _isLoadingHelpInfo;

  bool _isCreatingTicket = false;
  bool get isCreatingTicket => _isCreatingTicket;

  bool _isAddingComment = false;
  bool get isAddingComment => _isAddingComment;

  // Error state
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ==================
  // API METHODS
  // ==================

  /// Get FAQs
  Future<void> getFaqs() async {
    _isLoadingFaqs = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final faqsData = await _apiService.getFaqs();
      _faqs = faqsData.map((faq) => FaqModel.fromJson(faq)).toList();
      _isLoadingFaqs = false;
      notifyListeners();
    } catch (e) {
      _isLoadingFaqs = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Create support ticket
  Future<bool> createTicket({
    required String title,
    required String description,
    required String issueType,
    required String priority,
  }) async {
    _isCreatingTicket = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userData = _apiService.userData;
      if (userData == null || userData['id'] == null) {
        throw Exception('User not authenticated');
      }

      final userId = userData['id'].toString();
      final ticketData = {
        'title': title,
        'description': description,
        'issueType': issueType,
        'priority': priority,
      };

      final response = await _apiService.createSupportTicket(ticketData);
      
      // Add the new ticket to the list
      if (response['data'] != null) {
        final newTicket = TicketModel.fromJson(response['data']);
        _tickets.insert(0, newTicket);
      }

      _isCreatingTicket = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isCreatingTicket = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get user tickets
  Future<void> getUserTickets(String userId) async {
    _isLoadingTickets = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ticketsData = await _apiService.getUserTickets(userId);
      _tickets = ticketsData.map((ticket) => TicketModel.fromJson(ticket)).toList();
      _isLoadingTickets = false;
      notifyListeners();
    } catch (e) {
      _isLoadingTickets = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Get ticket details by ID
  Future<void> getTicketDetails(String ticketId) async {
    _isLoadingTicketDetails = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ticketData = await _apiService.getTicketById(ticketId);
      _selectedTicket = TicketModel.fromJson(ticketData['data'] ?? ticketData);
      _isLoadingTicketDetails = false;
      notifyListeners();
    } catch (e) {
      _isLoadingTicketDetails = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Get comments for a ticket
  Future<void> getComments(String ticketId) async {
    _isLoadingComments = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final commentsData = await _apiService.getComments(ticketId);
      _comments = commentsData.map((comment) => CommentModel.fromJson(comment)).toList();
      _isLoadingComments = false;
      notifyListeners();
    } catch (e) {
      _isLoadingComments = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Add comment to ticket
  Future<bool> addComment(String ticketId, String message) async {
    _isAddingComment = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.addComment(ticketId, message);
      
      // Add the new comment to the list
      if (response['data'] != null) {
        final newComment = CommentModel.fromJson(response['data']);
        _comments.insert(0, newComment);
      }

      _isAddingComment = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isAddingComment = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get help center information
  Future<void> getHelpInfo() async {
    _isLoadingHelpInfo = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final helpInfoData = await _apiService.getHelpInfo();
      _helpInfo = HelpInfoModel.fromJson(helpInfoData['data'] ?? helpInfoData);
      _isLoadingHelpInfo = false;
      notifyListeners();
    } catch (e) {
      _isLoadingHelpInfo = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Refresh all support data
  Future<void> refreshAll(String userId) async {
    await Future.wait([
      getUserTickets(userId),
      getFaqs(),
      getHelpInfo(),
    ]);
  }

  /// Set selected ticket
  set selectedTicket(TicketModel? ticket) {
    _selectedTicket = ticket;
    notifyListeners();
  }

  /// Clear selected ticket
  void clearSelectedTicket() {
    _selectedTicket = null;
    _comments = [];
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==================
  // HELPER METHODS
  // ==================

  /// Get status color
  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'RESOLVED':
        return Colors.green;
      case 'CLOSED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// Get priority color
  Color getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'LOW':
        return Colors.green;
      case 'MEDIUM':
        return Colors.orange;
      case 'HIGH':
        return Colors.deepOrange;
      case 'CRITICAL':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Format date
  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Get issue type label
  String getIssueTypeLabel(String issueType) {
    switch (issueType.toUpperCase()) {
      case 'PAYMENT':
        return 'Payment';
      case 'LOGIN':
        return 'Login';
      case 'ACCOUNT':
        return 'Account';
      case 'EXPENSE':
        return 'Expense';
      case 'BUG':
        return 'Bug';
      case 'FEATURE_REQUEST':
        return 'Feature Request';
      case 'OTHER':
        return 'Other';
      default:
        return issueType;
    }
  }

  /// Get priority label
  String getPriorityLabel(String priority) {
    switch (priority.toUpperCase()) {
      case 'LOW':
        return 'Low';
      case 'MEDIUM':
        return 'Medium';
      case 'HIGH':
        return 'High';
      case 'CRITICAL':
        return 'Critical';
      default:
        return priority;
    }
  }

  /// Get status label
  String getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return 'Open';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'RESOLVED':
        return 'Resolved';
      case 'CLOSED':
        return 'Closed';
      default:
        return status;
    }
  }
}