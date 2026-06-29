import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/business_provider.dart';
import 'package:provider/provider.dart';
import 'package:myapp/utils/amount_parser.dart';
import 'package:myapp/widgets/compact_business_action_buttons.dart';
import 'package:myapp/widgets/compact_business_filter_chips.dart';
import 'package:myapp/widgets/compact_business_selector.dart';
import 'package:myapp/widgets/compact_empty_state.dart';
import 'package:myapp/widgets/compact_loading_state.dart';
import 'package:myapp/widgets/compact_search_bar.dart';
import 'package:myapp/widgets/compact_summary_card.dart';
import 'package:myapp/widgets/compact_transaction_card.dart';
import 'package:myapp/utils/transaction_helpers.dart';

class BusinessTabContent extends StatefulWidget {
  const BusinessTabContent({super.key});
  @override
  State<BusinessTabContent> createState() => _BusinessTabContentState();
}

class _BusinessTabContentState extends State<BusinessTabContent> with WidgetsBindingObserver {
  bool _isFirstBuild = true;
  final ScrollController _scrollController = ScrollController();

  // Search/filter
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _currentSearchQuery = '';

  // Transaction type filter
  String? _txnTypeFilter;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadData();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstBuild) {
      _isFirstBuild = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    }
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
      Provider.of<BusinessProvider>(context, listen: false).loadMoreTransactions();
    }
  }

  Future<void> _loadData() async {
    await Provider.of<BusinessProvider>(context, listen: false).refreshAll();
  }

  Future<void> _handleRefresh() async => await _loadData();

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    setState(() => _currentSearchQuery = value);
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      // Local filtering happens in build
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _currentSearchQuery = '');
  }

  void _onFilterChanged(String? filter) {
    setState(() {
      _txnTypeFilter = filter;
    });
    final provider = Provider.of<BusinessProvider>(context, listen: false);
    provider.setTransactionTypeFilter(filter);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Consumer<BusinessProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Business Selector
                SliverToBoxAdapter(
                  child: CompactBusinessSelector(
                    selectedBusiness: provider.selectedBusiness,
                    onTap: () => showBusinessPickerBottomSheet(context, provider),
                    onCreateBusiness: () async {
                      final result = await context.push('/create-business');
                      if (result == true && mounted) provider.fetchBusinesses();
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Summary Cards - ONLY show when a business is selected
                if (provider.selectedBusiness != null)
                  SliverToBoxAdapter(child: _buildSummaryCards(provider, theme, colorScheme)),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Action Buttons - ONLY show when a business is selected
                if (provider.selectedBusiness != null)
                  SliverToBoxAdapter(
                    child: CompactBusinessActionButtons(
                      onAddTransaction: () => context.push('/add-business-transaction'),
                      onAddParty: () => context.push('/add-party'),
                      onAddItem: () => context.push('/add-item'),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CompactSearchBar(
                      hintText: 'Search transactions...',
                      onSearchChanged: _onSearchChanged,
                      onClearSearch: _clearSearch,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Filter Chips
                SliverToBoxAdapter(
                  child: CompactBusinessFilterChips(
                    selectedFilter: _txnTypeFilter,
                    onFilterChanged: _onFilterChanged,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // Section Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      provider.selectedBusiness == null
                          ? 'Select a Business'
                          : 'All Transactions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Transaction List / States
                if (provider.selectedBusiness == null)
                  SliverFillRemaining(
                    child: _buildNoBusinessState(provider, theme),
                  )
                else if (provider.isLoadingTransactions && provider.businessTransactions.isEmpty)
                  const SliverFillRemaining(
                    child: CompactLoadingState(message: 'Loading transactions...'),
                  )
                else if (provider.errorMessage != null &&
                    (provider.businessTransactions.isEmpty ||
                        _filteredTransactions(provider).isEmpty))
                  SliverFillRemaining(
                    child: CompactErrorState(
                      message: 'Error: ${provider.errorMessage}',
                      onRetry: _handleRefresh,
                    ),
                  )
                else if (_filteredTransactions(provider).isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(theme),
                  )
                else
                  ..._buildTransactionSlivers(provider, theme, colorScheme),

                // Loading more indicator
                if (provider.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _filteredTransactions(BusinessProvider provider) {
    List<Map<String, dynamic>> displayTransactions = provider.businessTransactions;

    if (_txnTypeFilter != null && _txnTypeFilter!.isNotEmpty) {
      displayTransactions = displayTransactions.where((tx) {
        final type = tx['transaction_type'] as String? ?? '';
        return type == _txnTypeFilter;
      }).toList();
    }

    if (_currentSearchQuery.isNotEmpty) {
      displayTransactions = displayTransactions.where((tx) {
        final category = tx['category'] as String? ?? '';
        final remark = tx['remark'] as String? ?? '';
        final partyName = tx['party']?['name'] as String? ?? tx['party_name'] as String? ?? '';
        final itemNames = (tx['items'] as List?)?.map((item) => item['description'] as String? ?? '').join(' ') ?? '';
        final query = _currentSearchQuery.toLowerCase();
        return category.toLowerCase().contains(query) ||
            remark.toLowerCase().contains(query) ||
            partyName.toLowerCase().contains(query) ||
            itemNames.toLowerCase().contains(query);
      }).toList();
    }

    return displayTransactions;
  }

  Widget _buildSummaryCards(BusinessProvider provider, ThemeData theme, ColorScheme colorScheme) {
    double totalSales = 0.0;
    double totalPurchases = 0.0;
    double totalExpenses = 0.0;
    for (final tx in provider.businessTransactions) {
      final amount = parseAmount(tx['total_amount'] ?? tx['amount']);
      final type = tx['transaction_type'] as String? ?? '';
      if (type == 'SALE') {
        totalSales += amount;
      } else if (type == 'PURCHASE') {
        totalPurchases += amount;
      } else if (type == 'EXPENSE') {
        totalExpenses += amount;
      }
    }
    double net = totalSales - totalPurchases - totalExpenses;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          CompactBalanceCard(
            title: 'Net Flow',
            amount: '₹${net.toStringAsFixed(2)}',
            colorScheme: colorScheme,
            items: [
              CompactSummaryItem(label: 'Sales', value: '₹${totalSales.toStringAsFixed(2)}', color: Colors.green),
              CompactSummaryItem(label: 'Purchases', value: '₹${totalPurchases.toStringAsFixed(2)}', color: Colors.blue),
              CompactSummaryItem(label: 'Expenses', value: '₹${totalExpenses.toStringAsFixed(2)}', color: Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoBusinessState(BusinessProvider provider, ThemeData theme) {
    return CompactEmptyState(
      icon: Icons.business_center,
      title: 'No Business Selected',
      subtitle: 'Select a business or create a new one to start tracking transactions.',
      actionLabel: 'Create Business',
      actionIcon: Icons.add,
      onAction: () async {
        final result = await context.push('/create-business');
        if (result == true && mounted) {
          provider.fetchBusinesses();
        }
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return CompactEmptyState(
      icon: Icons.receipt_long,
      title: 'No Transactions Found',
      subtitle: _txnTypeFilter != null
          ? 'No ${_txnTypeFilter!.toLowerCase()} transactions found. Try changing the filter or add a new transaction.'
          : 'Add your first business transaction to get started.',
      actionLabel: 'Add Transaction',
      actionIcon: Icons.add,
      onAction: () => context.push('/add-business-transaction'),
    );
  }

  List<Widget> _buildTransactionSlivers(
    BusinessProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final displayTransactions = _filteredTransactions(provider);
    final grouped = groupTransactionsByDate(displayTransactions);
    final slivers = <Widget>[];

    for (final entry in grouped.entries) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              entry.key,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
      );

      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final tx = entry.value[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: CompactTransactionCard(
                  transaction: tx,
                  onTap: () {
                    context.push('/transaction-detail', extra: tx);
                  },
                  onNameTap: () {
                    final partyName = tx['party']?['name'] as String? ?? tx['party_name'] as String? ?? '';
                    if (partyName.isNotEmpty) {
                      // Navigate to party transactions if needed
                    }
                  },
                ),
              );
            },
            childCount: entry.value.length,
          ),
        ),
      );
    }

    // Add infinite scroll indicator
    if (provider.hasMoreData && _txnTypeFilter == null && _currentSearchQuery.isEmpty) {
      slivers.add(
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      );
    }

    return slivers;
  }
}
