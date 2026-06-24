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

class _PersonalTabContentState extends State<PersonalTabContent> {
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

  // Search state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Date range filter
  DateTime? _startDate;
  DateTime? _endDate;

  // Selected person for filtered view
  String? _selectedPersonName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    await provider.refreshAll();
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  // Get filtered transactions
  List<Map<String, dynamic>> _getFilteredTransactions(List<Map<String, dynamic>> transactions) {
    var filtered = List<Map<String, dynamic>>.from(transactions);

    // Apply person filter
    if (_selectedPersonName != null) {
      filtered = filtered.where((tx) {
        final name = tx['name'] as String? ?? '';
        return name.toLowerCase() == _selectedPersonName!.toLowerCase();
      }).toList();
    }

    // Apply type filter
    switch (_selectedFilter) {
      case 'Income':
        filtered = filtered.where((tx) => tx['transaction_type'] == 'INCOME').toList();
        break;
      case 'Expense':
        filtered = filtered.where((tx) => tx['transaction_type'] == 'EXPENSE').toList();
        break;
      case 'Loan':
        filtered = filtered.where((tx) => tx['transaction_type'] == 'LOAN').toList();
        break;
      case 'Borrow':
        filtered = filtered.where((tx) {
          return tx['transaction_type'] == 'LOAN' && tx['loan_type'] == 'BORROW';
        }).toList();
        break;
      case 'Lent':
        filtered = filtered.where((tx) {
          return tx['transaction_type'] == 'LOAN' && tx['loan_type'] == 'LENT';
        }).toList();
        break;
      case 'Cash':
        filtered = filtered.where((tx) => tx['payment_mode'] == 'CASH').toList();
        break;
      case 'Online':
        filtered = filtered.where((tx) => tx['payment_mode'] == 'ONLINE').toList();
        break;
      case 'Category':
        // Category filter would need a sub-filter, for now show all
        break;
      case 'Date Range':
        if (_startDate != null && _endDate != null) {
          filtered = filtered.where((tx) {
            final dateStr = tx['transaction_date'] as String? ?? '';
            if (dateStr.isEmpty) return false;
            try {
              final date = DateTime.parse(dateStr);
              return date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
                  date.isBefore(_endDate!.add(const Duration(days: 1)));
            } catch (e) {
              return false;
            }
          }).toList();
        }
        break;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((tx) {
        final name = (tx['name'] as String? ?? '').toLowerCase();
        final category = (tx['category'] as String? ?? '').toLowerCase();
        final remark = (tx['remark'] as String? ?? '').toLowerCase();
        return name.contains(query) || category.contains(query) || remark.contains(query);
      }).toList();
    }

    // Sort by date descending
    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a['transaction_date'] as String? ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['transaction_date'] as String? ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    return filtered;
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
          final allTransactions = provider.personalTransactions;
          final filteredTransactions = _getFilteredTransactions(allTransactions);
          final groupedTransactions = _groupByDate(filteredTransactions);

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
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

                  // TRANSACTIONS LIST
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

                  if (provider.isLoadingTransactions)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (filteredTransactions.isEmpty)
                    _buildCompactEmptyState(theme)
                  else
                    ...groupedTransactions.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Text(
                              entry.key,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          ...entry.value.map((tx) => _CompactTransactionCard(
                            transaction: tx,
                            onTap: () {
                              context.push('/transaction-detail', extra: tx);
                            },
                            onNameTap: () {
                              final name = tx['name'] as String?;
                              if (name != null && name.isNotEmpty) {
                                setState(() {
                                  _selectedPersonName = name;
                                });
                              }
                            },
                          )),
                          const SizedBox(height: 4),
                        ],
                      );
                    }).toList(),

                  // Bottom padding for scroll
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
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
                fontSize: 12,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
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
            fontSize: 10,
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
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search transactions...',
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
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
                setState(() {
                  _selectedFilter = filter;
                  if (filter == 'Date Range' && _startDate == null) {
                    _selectDateRange();
                  }
                });
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

  Future<void> _selectDateRange() async {
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
    }
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
    final colorScheme = theme.colorScheme;
    final amount = (() {
      final val = transaction['amount'];
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    })();
    final transactionType = transaction['transaction_type'] as String? ?? '';
    final category = transaction['category'] as String? ?? '';
    final paymentMode = transaction['payment_mode'] as String? ?? '';
    final dateStr = transaction['transaction_date'] as String? ?? '';
    final timeStr = transaction['time'] as String? ?? '';
    final remark = transaction['remark'] as String? ?? '';
    final personName = transaction['name'] as String? ?? '';

    DateTime? date;
    if (dateStr.isNotEmpty) {
      try {
        date = DateTime.parse(dateStr);
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
                          child: Text(
                            category,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                        if (date != null && timeStr.isNotEmpty)
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
                    if (remark.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          remark,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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