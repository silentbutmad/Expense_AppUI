import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/expense_model.dart';
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
  final List<String> _filterOptions = [
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
        filtered = filtered.where((tx) => tx['transaction_type'] == 'RECEIVED').toList();
        break;
      case 'Expense':
        filtered = filtered.where((tx) => tx['transaction_type'] == 'PAID').toList();
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
    final textTheme = theme.textTheme;

    return PopScope(
      canPop: _selectedPersonName == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedPersonName != null) {
          setState(() {
            _selectedPersonName = null;
          });
        }
      },
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Consumer<ExpenseProvider>(
          builder: (context, provider, child) {
            final allTransactions = provider.personalTransactions;
            final filteredTransactions = _getFilteredTransactions(allTransactions);
            final groupedTransactions = _groupByDate(filteredTransactions);

            // Error state
            if (provider.errorMessage != null && allTransactions.isEmpty) {
              return SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(provider, textTheme),
                      const SizedBox(height: 25),
                      _buildActionButtons(theme),
                      const SizedBox(height: 25),
                      _buildSearchBar(theme),
                      const SizedBox(height: 12),
                      _buildFilterChips(theme),
                      const SizedBox(height: 20),
                      _buildErrorState(provider, theme),
                    ],
                  ),
                ),
              );
            }

            return SafeArea(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 💰 TOP SUMMARY CONTAINER
                    _buildSummaryCard(provider, textTheme),
                    const SizedBox(height: 25),
                    // 🔘 ACTION BUTTONS
                    _buildActionButtons(theme),
                    const SizedBox(height: 25),
                    // 🔍 SEARCH BAR
                    _buildSearchBar(theme),
                    const SizedBox(height: 12),
                    // 📊 FILTERS
                    _buildFilterChips(theme),
                    const SizedBox(height: 20),
                    // 📋 TRANSACTIONS LIST
                    Text(
                      _selectedPersonName == null
                          ? 'All Transactions'
                          : 'Transactions with $_selectedPersonName',
                      style: textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    if (provider.isLoadingTransactions)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (filteredTransactions.isEmpty)
                      _buildEmptyState(theme)
                    else
                      ...groupedTransactions.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                entry.key,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            ...entry.value.map((tx) => _TransactionCard(
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
                            const SizedBox(height: 8),
                          ],
                        );
                      }).toList(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/add-expense', extra: {
                  'isBusiness': false,
                  'transactionType': TransactionType.paid,
                  'transactionCategory': TransactionCategory.expense,
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Transaction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ExpenseProvider provider, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to fetch transactions. Pull down to retry.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _handleRefresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ExpenseProvider provider, TextTheme textTheme) {
    final theme = Theme.of(context);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Total Balance',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              '₹${provider.totalBalance.toStringAsFixed(2)}',
              style: textTheme.displayLarge?.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Income',
                  '₹${provider.totalIncome.toStringAsFixed(2)}',
                  Colors.green,
                  textTheme,
                ),
                _buildSummaryItem(
                  'Expense',
                  '₹${provider.totalExpense.toStringAsFixed(2)}',
                  Colors.red,
                  textTheme,
                ),
                _buildSummaryItem(
                  'Loan',
                  '₹${provider.totalLoan.toStringAsFixed(2)}',
                  Colors.orange,
                  textTheme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, TextTheme textTheme) {
    return Column(
      children: [
        Text(
          label,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: textTheme.bodyLarge?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              context.push('/add-expense', extra: {
                'isBusiness': false,
                'transactionType': TransactionType.received,
                'transactionCategory': TransactionCategory.income,
              });
            },
            icon: const Icon(Icons.add_circle, color: Colors.white),
            label: const Text('Income'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              context.push('/add-expense', extra: {
                'isBusiness': false,
                'transactionType': TransactionType.paid,
                'transactionCategory': TransactionCategory.expense,
              });
            },
            icon: const Icon(Icons.remove_circle, color: Colors.white),
            label: const Text('Expense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              context.push('/add-expense', extra: {
                'isBusiness': false,
                'transactionCategory': TransactionCategory.loan,
              });
            },
            icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
            label: const Text('Loan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by name, category, or remark...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
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
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(filter),
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
            ),
          );
        },
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

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onTap;
  final VoidCallback? onNameTap;

  const _TransactionCard({
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
      case 'RECEIVED':
        typeColor = Colors.green;
        typeIcon = Icons.arrow_downward;
        typeLabel = 'Income';
        break;
      case 'PAID':
        typeColor = Colors.red;
        typeIcon = Icons.arrow_upward;
        typeLabel = 'Expense';
        break;
      case 'LOAN':
        final loanType = transaction['loan_type'] as String? ?? '';
        if (loanType == 'LENT') {
          typeColor = Colors.blue;
          typeIcon = Icons.account_balance_wallet;
          typeLabel = 'Loan Lent';
        } else {
          typeColor = Colors.orange;
          typeIcon = Icons.account_balance;
          typeLabel = 'Loan Borrow';
        }
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.help;
        typeLabel = transactionType;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Type Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  typeIcon,
                  color: typeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

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
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: typeColor,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                personName,
                                style: TextStyle(
                                  color: typeColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        if (personName.isNotEmpty) const SizedBox(width: 8),
                        // Category
                        Expanded(
                          child: Text(
                            category,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (date != null)
                          Text(
                            DateFormat.yMMMd().format(date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        if (date != null && timeStr.isNotEmpty)
                          Text(
                            ' at $timeStr',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        if (date != null && paymentMode.isNotEmpty)
                          Text(
                            ' • $paymentMode',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    if (remark.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          remark,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
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
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 10,
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