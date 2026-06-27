import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:myapp/providers/expense_provider.dart';
import 'package:provider/provider.dart';

class PersonalTabContent extends StatefulWidget {
  const PersonalTabContent({super.key});

  @override
  State<PersonalTabContent> createState() => _PersonalTabContentState();
}

class _PersonalTabContentState extends State<PersonalTabContent> with WidgetsBindingObserver {
  bool _isFirstBuild = true;
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when returning to this screen
    if (!_isFirstBuild) {
      _loadData();
    }
    _isFirstBuild = false;
  }
  // Filter state
  String _selectedFilter = 'All';
  final List<String> _filterOptions = const [
    'All',
    'Income',
    'Expense',
    'Loan',
    'Borrow',
    'Lent',
    'Cash',
    'Online',
    'Category',
    'Date Range',
  ];

  // Search state with debounce
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _currentSearchQuery = '';

  // Date range filter
  DateTime? _startDate;
  DateTime? _endDate;

  // Selected person for filtered view
  String? _selectedPersonName;

  // Scroll controller for infinite scroll
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      debugPrint('Scroll detected - hasMoreData: ${provider.hasMoreData}, isLoadingMore: ${provider.isLoadingMore}');
      provider.loadMoreTransactions();
    }
  }

  Future<void> _loadData() async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    await provider.refreshAll();
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  void _onSearchChanged(String value) {
    // Cancel previous debounce
    _searchDebounce?.cancel();
    
    setState(() {
      _currentSearchQuery = value;
    });

    // Debounce search for 500ms
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      provider.updateSearchQuery(value.isEmpty ? null : value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentSearchQuery = '';
    });
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    provider.updateSearchQuery(null);
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });

    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final filters = <String, String>{};

    // Map UI filter to backend filter
    switch (filter) {
      case 'Income':
        filters['transaction_type'] = 'INCOME';
        break;
      case 'Expense':
        filters['transaction_type'] = 'EXPENSE';
        break;
      case 'Loan':
        filters['transaction_type'] = 'LOAN';
        break;
      case 'Borrow':
        filters['transaction_type'] = 'LOAN';
        filters['loan_type'] = 'BORROW';
        break;
      case 'Lent':
        filters['transaction_type'] = 'LOAN';
        filters['loan_type'] = 'LENT';
        break;
      case 'Cash':
        filters['payment_mode'] = 'CASH';
        break;
      case 'Online':
        filters['payment_mode'] = 'ONLINE';
        break;
      case 'Category':
        // Category filter would need a sub-filter picker
        // For now, we'll show all or prompt user
        _showCategoryPicker(provider);
        return;
      case 'Date Range':
        _selectDateRange(provider);
        return;
      case 'All':
      default:
        // No filters - will fetch all
        break;
    }

    // Single API call with all filters
    provider.fetchFilteredTransactions(filters: filters);
  }

  void _showCategoryPicker(ExpenseProvider provider) {
    // Show a dialog to select category
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category picker coming soon')),
    );
  }

  Future<void> _selectDateRange(ExpenseProvider provider) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });

      // Format dates as YYYY-MM-DD
      final startDateStr = DateFormat('yyyy-MM-dd').format(picked.start);
      final endDateStr = DateFormat('yyyy-MM-dd').format(picked.end);

      provider.updateFilter('start_date', startDateStr);
      provider.updateFilter('end_date', endDateStr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: _selectedPersonName == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedPersonName != null) {
          setState(() {
            _selectedPersonName = null;
          });
        }
      },
      child: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final transactions = provider.personalTransactions;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // COMPACT SUMMARY CARD
                _buildCompactSummaryCard(provider, colorScheme),
                const SizedBox(height: 12),

                // ACTION BUTTONS
                _buildCompactActionButtons(theme),
                const SizedBox(height: 12),

                // SEARCH BAR
                _buildCompactSearchBar(theme),
                const SizedBox(height: 8),

                // FILTER CHIPS
                _buildCompactFilterChips(theme),
                const SizedBox(height: 12),

                // TRANSACTIONS LIST TITLE
                Text(
                  _selectedPersonName == null
                      ? 'All Transactions'
                      : 'Transactions with $_selectedPersonName',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // TRANSACTIONS LIST
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: _buildTransactionList(provider, theme, colorScheme, transactions),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionList(
    ExpenseProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
    List<Map<String, dynamic>> transactions,
  ) {
    // Filter by selected person if needed
    List<Map<String, dynamic>> displayTransactions = transactions;
    if (_selectedPersonName != null) {
      displayTransactions = transactions.where((tx) {
        final name = tx['name'] as String? ?? '';
        return name.toLowerCase() == _selectedPersonName!.toLowerCase();
      }).toList();
    }

    // Loading state
    if (provider.isLoadingTransactions && displayTransactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (provider.errorMessage != null && displayTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Error: ${provider.errorMessage}',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _handleRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (displayTransactions.isEmpty && !provider.isLoadingTransactions) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          _buildCompactEmptyState(theme),
        ],
      );
    }

    // Group transactions by date
    final groupedTransactions = _groupByDate(displayTransactions);

    // Transactions list with infinite scroll and date grouping
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: groupedTransactions.length + (provider.hasMoreData && _selectedPersonName == null ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at bottom for pagination (only when not filtering by person)
        if (index == groupedTransactions.length && provider.hasMoreData && _selectedPersonName == null) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final entry = groupedTransactions.entries.elementAt(index);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                entry.key,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            // Transactions for this date
            ...entry.value.map(
              (tx) => _CompactTransactionCard(
                transaction: tx,
                onTap: () {
                  // Navigate to transaction detail screen
                  context.push('/transaction-detail', extra: tx);
                },
                onNameTap: () {
                  final name = tx['name'] as String?;
                  if (name != null && name.isNotEmpty) {
                    context.push(
                      '/person-transactions?name=${Uri.encodeComponent(name)}',
                    );
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Group transactions by date
  Map<String, List<Map<String, dynamic>>> _groupByDate(List<Map<String, dynamic>> transactions) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final tx in transactions) {
      final dateStr = tx['transaction_date'] as String? ?? '';
      if (dateStr.isEmpty) continue;
      try {
        final date = DateTime.parse(dateStr);
        final key = DateFormat.yMMMd().format(date);
        grouped.putIfAbsent(key, () => []).add(tx);
      } catch (e) {
        // Skip invalid dates
      }
    }
    return grouped;
  }

  // Compact Summary Card
  Widget _buildCompactSummaryCard(ExpenseProvider provider, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Balance',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${provider.totalBalance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Income', '₹${provider.totalIncome.toStringAsFixed(2)}', Colors.green, colorScheme),
                _buildSummaryItem('Expense', '₹${provider.totalExpense.toStringAsFixed(2)}', Colors.red, colorScheme),
                _buildSummaryItem('Loan', '₹${provider.totalLoan.toStringAsFixed(2)}', Colors.orange, colorScheme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // Compact Action Buttons
  Widget _buildCompactActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _CompactActionButton(
            label: 'Income',
            icon: Icons.add_circle,
            color: Colors.green,
            onPressed: () {
              context.push('/add-expense', extra: {
                'isBusiness': false,
                'transactionType': 'RECEIVED',
                'transactionCategory': 'INCOME',
              });
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _CompactActionButton(
            label: 'Expense',
            icon: Icons.remove_circle,
            color: Colors.red,
            onPressed: () {
              context.push('/add-expense', extra: {
                'isBusiness': false,
                'transactionType': 'PAID',
                'transactionCategory': 'EXPENSE',
              });
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _CompactActionButton(
            label: 'Loan',
            icon: Icons.account_balance_wallet,
            color: Colors.orange,
            onPressed: () {
              context.push('/add-expense', extra: {
                'isBusiness': false,
                'transactionCategory': 'LOAN',
              });
            },
          ),
        ),
      ],
    );
  }

  // Compact Search Bar
  Widget _buildCompactSearchBar(ThemeData theme) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search transactions...',
          prefixIcon: const Icon(Icons.search, size: 18),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          suffixIcon: _currentSearchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: _clearSearch,
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  // Compact Filter Chips
  Widget _buildCompactFilterChips(ThemeData theme) {
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: FilterChip(
              label: Text(
                filter,
                style: const TextStyle(fontSize: 11),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _onFilterChanged(filter);
                } else {
                  setState(() {
                    _selectedFilter = 'All';
                  });
                  final provider = Provider.of<ExpenseProvider>(context, listen: false);
                  provider.clearFilters();
                }
              },
              selectedColor: theme.colorScheme.primaryContainer,
              checkmarkColor: theme.colorScheme.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          );
        },
      ),
    );
  }

  // Compact Empty State
  Widget _buildCompactEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No transactions found',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/add-expense', extra: {
                  'isBusiness': false,
                  'transactionType': 'PAID',
                  'transactionCategory': 'EXPENSE',
                });
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Transaction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Compact Action Button Widget
class _CompactActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _CompactActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Compact Transaction Card Widget
class _CompactTransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onTap;
  final VoidCallback? onNameTap;

  const _CompactTransactionCard({
    required this.transaction,
    required this.onTap,
    this.onNameTap,
  });

  @override
  Widget build(BuildContext context) {
   
  
    final theme = Theme.of(context);
    final amount = (() {
      final val = transaction['amount'];
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    })();
    final transactionType = transaction['transaction_type'] as String? ?? '';
    final category = transaction['category'] as String? ?? '';
    final transactionCategory = transaction['transactionCategory'] as String? ?? '';
    final paymentMode = transaction['payment_mode'] as String? ?? '';
    final dateStr = transaction['transaction_date'] as String? ?? '';
    final remark = transaction['remark'] as String? ?? '';
    final personName = transaction['name'] as String? ?? '';

    DateTime? date;
    String? timeStr;
    if (dateStr.isNotEmpty) {
      try {
        date = DateTime.parse(dateStr);
        // Use transaction_time field if available, otherwise extract from date
        final transactionTime = transaction['transaction_time'] as String?;
        if (transactionTime != null && transactionTime.isNotEmpty) {
          timeStr = transactionTime;
        } else {
          timeStr = DateFormat.jm().format(date);
        }
      } catch (e) {
        // Keep date as null
      }
    }

    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (transactionType.toUpperCase()) {
      case 'INCOME':
        typeColor = Colors.green;
        typeIcon = Icons.arrow_downward;
        typeLabel = 'Income';
        break;
      case 'EXPENSE':
        typeColor = Colors.red;
        typeIcon = Icons.arrow_upward;
        typeLabel = 'Expense';
        break;
      case 'LOAN':
        final loanType = transaction['loan_type'] as String? ?? '';
        if (loanType == 'LENT') {
          typeColor = Colors.blue;
          typeIcon = Icons.account_balance_wallet;
          typeLabel = 'Lent';
        } else {
          typeColor = Colors.orange;
          typeIcon = Icons.account_balance;
          typeLabel = 'Borrow';
        }
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.help;
        typeLabel = transactionType;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              // Type Icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  typeIcon,
                  color: typeColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Person name - clickable
                        if (personName.isNotEmpty)
                          GestureDetector(
                            onTap: onNameTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: typeColor,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                personName,
                                style: TextStyle(
                                  color: typeColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        if (personName.isNotEmpty) const SizedBox(width: 6),
                        // Category
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (transactionCategory.isNotEmpty)
                                Text(
                                  transactionCategory,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (date != null)
                          Text(
                            DateFormat.yMMMd().format(date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        if (date != null && timeStr != null && timeStr.isNotEmpty)
                          Text(
                            ' at $timeStr',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        if (date != null && paymentMode.isNotEmpty)
                          Text(
                            ' • $paymentMode',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 9,
                        color: typeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

