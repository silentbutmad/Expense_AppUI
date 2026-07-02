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

  // Per-section error states
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _ticketsError;
  String? get ticketsError => _ticketsError;

  String? _faqsError;
  String? get faqsError => _faqsError;

  String? _helpInfoError;
  String? get helpInfoError => _helpInfoError;

  // ==================
  // API METHODS
  // ==================

  /// Get FAQs
  Future<void> getFaqs() async {
    _isLoadingFaqs = true;
    _faqsError = null;
    notifyListeners();

    try {
      final faqsData = await _apiService.getFaqs();
      _faqs = faqsData.map((faq) => FaqModel.fromJson(faq)).toList();
      _isLoadingFaqs = false;
      notifyListeners();
    } catch (e) {
      _isLoadingFaqs = false;
      _faqsError = e.toString();
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
      // Check if user is authenticated (has access token)
      // Backend will extract user_id from JWT token, not from request body
      if (!_apiService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

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
  Future<void> getUserTickets({
    String? status,
    String? priority,
    String? issueType,
    int page = 1,
    int limit = 10,
  }) async {
    _isLoadingTickets = true;
    _ticketsError = null;
    notifyListeners();

    try {
      debugPrint('Fetching tickets with filters: status=$status, priority=$priority, issueType=$issueType');
      final response = await _apiService.getUserTickets(
        status: status,
        priority: priority,
        issueType: issueType,
        page: page,
        limit: limit,
      );
      
      debugPrint('API Response: $response');
      final ticketsList = response['tickets'] as List<dynamic>? ?? [];
      debugPrint('Tickets list length: ${ticketsList.length}');
      
      _tickets = ticketsList.map((ticket) {
        debugPrint('Parsing ticket: $ticket');
        return TicketModel.fromJson(ticket);
      }).toList();
      
      debugPrint('Total tickets in provider: ${_tickets.length}');
    } catch (e) {
      _ticketsError = e.toString();
      // Keep existing tickets on error instead of clearing them
      debugPrint('Error fetching tickets: $e');
    } finally {
      _isLoadingTickets = false;
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

  /// Check if current user can comment on ticket
  bool canUserComment(String ticketUserId) {
    try {
    
      
      String? currentUserId;
      
      
      // Try to get user ID from userData first
      final currentUser = _apiService.userData;
      
      
      if (currentUser != null) {
        
        // Try multiple possible field names for user ID
        currentUserId = currentUser['id']?.toString() ?? 
                        currentUser['userId']?.toString() ?? 
                        currentUser['user_id']?.toString() ??
                        currentUser['_id']?.toString();
        
        
      }
      
      // If userData is null or doesn't have user ID, allow comment
      // Backend will do the actual authorization check
      
      final canComment = currentUserId == ticketUserId;
    
      
      return canComment;
    } catch (e) {
      debugPrint('Error in canUserComment: $e');
      // On error, allow the comment - backend will validate
      return true;
    }
  }

  /// Add comment to ticket
  Future<bool> addComment(String ticketId, String message) async {
    // Check if user can comment on this ticket
    if (_selectedTicket == null) {
      _errorMessage = 'Ticket not found';
      notifyListeners();
      return false;
    }

    if (!canUserComment(_selectedTicket!.userId)) {
      _errorMessage = 'Access denied. You can only comment on your own tickets.';
      notifyListeners();
      return false;
    }

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
    _helpInfoError = null;
    notifyListeners();

    try {
      final helpInfoData = await _apiService.getHelpInfo();
      _helpInfo = HelpInfoModel.fromJson(helpInfoData);
      print ("-------------------------------------------hi");
      print(helpInfo?.email);
    
      _isLoadingHelpInfo = false;

      notifyListeners();
    } catch (e) {
      _isLoadingHelpInfo = false;
      _helpInfoError = e.toString();
      _helpInfo = null;
      notifyListeners();
    }
  }

  /// Refresh all support data
  Future<void> refreshAll() async {
    await Future.wait([
      getUserTickets(),
      getFaqs(),
      getHelpInfo(),
    ]);
  }

  /// Load public support data (FAQs, help info) - no auth required
  Future<void> loadPublicData() async {
    await Future.wait([
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

  /// Clear all error messages
  void clearError() {
    _errorMessage = null;
    _ticketsError = null;
    _faqsError = null;
    _helpInfoError = null;
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