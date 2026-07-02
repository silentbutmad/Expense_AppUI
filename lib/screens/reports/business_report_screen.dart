import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/providers/report_provider.dart';
import 'package:provider/provider.dart';

class BusinessReportScreen extends StatefulWidget {
  final String? businessId;
  const BusinessReportScreen({super.key, this.businessId});

  @override
  State<BusinessReportScreen> createState() => _BusinessReportScreenState();
}

class _BusinessReportScreenState extends State<BusinessReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BusinessReportScreen old) {
    super.didUpdateWidget(old);
    if (widget.businessId != old.businessId) _fetchAll();
  }

  Map<String, String?> _dateParams() {
    return {
      'startDate': _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
      'endDate': _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
    };
  }

  Future<void> _fetchAll() async {
    final p = context.read<ReportProvider>();
    final dp = _dateParams();
    await Future.wait([
      p.fetchBusinessTransactions(businessId: widget.businessId, startDate: dp['startDate'], endDate: dp['endDate']),
      p.fetchSales(businessId: widget.businessId, startDate: dp['startDate'], endDate: dp['endDate']),
      p.fetchPurchases(businessId: widget.businessId, startDate: dp['startDate'], endDate: dp['endDate']),
      p.fetchBusinessExpenses(businessId: widget.businessId, startDate: dp['startDate'], endDate: dp['endDate']),
    ]);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context, firstDate: DateTime(2020), lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null ? DateTimeRange(start: _startDate!, end: _endDate!) : null,
    );
    if (picked != null) {
      setState(() { _startDate = picked.start; _endDate = picked.end; });
      _fetchAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              InkWell(
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.date_range, size: 14, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(_startDate != null ? '${DateFormat.MMMd().format(_startDate!)}-${DateFormat.MMMd().format(_endDate!)}' : 'Date Range', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Sales'),
            Tab(text: 'Purchases'),
            Tab(text: 'Expenses'),
          ],
        ),
        Expanded(
          child: Consumer<ReportProvider>(
            builder: (context, rp, _) {
              if (rp.isLoading) return const Center(child: CircularProgressIndicator());
              return TabBarView(
                controller: _tabController,
                children: [
                  _allTransactions(rp),
                  _salesTab(rp),
                  _purchasesTab(rp),
                  _expensesTab(rp),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _allTransactions(ReportProvider rp) {
    if (rp.error != null) return Center(child: Text(rp.error!));
    final list = rp.businessTransactions;
    if (list.isEmpty) return const Center(child: Text('No transactions'));
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final t = list[i];
          final color = t.transactionType == 'SALE' ? Colors.green : (t.transactionType == 'PURCHASE' ? Colors.orange : Colors.red);
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(t.transactionType == 'SALE' ? Icons.arrow_upward : Icons.arrow_downward, color: color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(t.transactionNumber ?? 'N/A', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                              child: Text(t.transactionType, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        if (t.partyName != null) Text(t.partyName!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                        if (t.transactionDate != null) Text(t.transactionDate!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text('\u20b9${t.totalAmount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _salesTab(ReportProvider rp) {
    if (rp.error != null) return Center(child: Text(rp.error!));
    final list = rp.sales;
    if (list.isEmpty) return const Center(child: Text('No sales'));
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final t = list[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const Icon(Icons.arrow_upward, color: Colors.green, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.partyName ?? t.transactionNumber ?? 'N/A', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Text('${t.itemsCount} items', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        if (t.transactionDate != null) Text(t.transactionDate!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text('\u20b9${t.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _purchasesTab(ReportProvider rp) {
    if (rp.error != null) return Center(child: Text(rp.error!));
    final list = rp.purchases;
    if (list.isEmpty) return const Center(child: Text('No purchases'));
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final t = list[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    const Icon(Icons.arrow_downward, color: Colors.orange, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.partyName ?? t.transactionNumber ?? 'N/A', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          if (t.transactionDate != null) Text(t.transactionDate!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text('\u20b9${t.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
                children: t.items.map((item) => Padding(
                  padding: const EdgeInsets.only(left: 36, bottom: 4),
                  child: Text('${item.itemName ?? 'Item'} x${item.quantity} @ \u20b9${item.price.toStringAsFixed(0)}'),
                )).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _expensesTab(ReportProvider rp) {
    if (rp.error != null) return Center(child: Text(rp.error!));
    final list = rp.businessExpenses;
    if (list.isEmpty) return const Center(child: Text('No expenses'));
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final t = list[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    const Icon(Icons.money_off, color: Colors.red, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title ?? t.transactionNumber ?? 'Expense', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          if (t.transactionDate != null) Text(t.transactionDate!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text('\u20b9${t.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
                children: t.items.map((item) => Padding(
                  padding: const EdgeInsets.only(left: 36, bottom: 4),
                  child: Text('${item.itemName ?? 'Item'} x${item.quantity} @ \u20b9${item.price.toStringAsFixed(0)}'),
                )).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
