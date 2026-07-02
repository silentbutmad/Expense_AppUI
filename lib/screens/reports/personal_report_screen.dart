import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/providers/report_provider.dart';
import 'package:provider/provider.dart';

class PersonalReportScreen extends StatefulWidget {
  const PersonalReportScreen({super.key});

  @override
  State<PersonalReportScreen> createState() => _PersonalReportScreenState();
}

class _PersonalReportScreenState extends State<PersonalReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    final p = context.read<ReportProvider>();
    final sd = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null;
    final ed = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;
    await Future.wait([
      p.fetchPersonalTransactions(transactionType: _typeFilter, startDate: sd, endDate: ed),
      p.fetchCategoryReports(startDate: sd, endDate: ed),
      p.fetchPaymentModeReports(startDate: sd, endDate: ed),
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
              _filterChip('All', null),
              const SizedBox(width: 6),
              _filterChip('Income', 'INCOME'),
              const SizedBox(width: 6),
              _filterChip('Expense', 'EXPENSE'),
              const SizedBox(width: 6),
              _filterChip('Loan', 'LOAN'),
              const Spacer(),
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
                      Text(_startDate != null ? '${DateFormat.MMMd().format(_startDate!)}-${DateFormat.MMMd().format(_endDate!)}' : 'Dates', style: const TextStyle(fontSize: 11)),
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
            Tab(text: 'Transactions'),
            Tab(text: 'Category'),
            Tab(text: 'Payment Mode'),
          ],
        ),
        Expanded(
          child: Consumer<ReportProvider>(
            builder: (context, rp, _) {
              if (rp.isLoading) return const Center(child: CircularProgressIndicator());
              return TabBarView(
                controller: _tabController,
                children: [
                  _transactionsTab(context, rp),
                  _categoryTab(context, rp),
                  _paymentModeTab(context, rp),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String? value) {
    final sel = _typeFilter == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: sel,
      onSelected: (_) {
        setState(() { _typeFilter = sel ? null : value; });
        _fetchAll();
      },
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _transactionsTab(BuildContext context, ReportProvider rp) {
    if (rp.error != null) return Center(child: Text(rp.error!));
    final list = rp.personalTransactions;
    if (list.isEmpty) return const Center(child: Text('No transactions'));
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final t = list[i];
          final isIncome = t.transactionType == 'INCOME';
          final color = isIncome ? Colors.green : (t.transactionType == 'EXPENSE' ? Colors.red : Colors.orange);
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name ?? t.category ?? 'N/A', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        if (t.transactionDate != null) Text(t.transactionDate!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        if (t.paymentMode != null) Text(t.paymentMode!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Text('\u20b9${t.amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _categoryTab(BuildContext context, ReportProvider rp) {
    if (rp.error != null) return Center(child: Text(rp.error!));
    final list = rp.categoryReports;
    if (list.isEmpty) return const Center(child: Text('No category data'));
    final total = list.fold<double>(0, (s, c) => s + c.totalAmount);
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: list.map((c) {
                  final pct = total > 0 ? c.totalAmount / total : 0.0;
                  return PieChartSectionData(
                    value: pct * 100,
                    title: '${(pct * 100).toStringAsFixed(1)}%',
                    radius: 50,
                    color: _pieColor(list.indexOf(c)),
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...list.map((c) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: _pieColor(list.indexOf(c)), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(c.category, style: Theme.of(context).textTheme.bodyMedium)),
                Text('\u20b9${c.totalAmount.toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('(${c.transactionCount})', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _paymentModeTab(BuildContext context, ReportProvider rp) {
    if (rp.error != null) return Center(child: Text(rp.error!));
    final list = rp.paymentModeReports;
    if (list.isEmpty) return const Center(child: Text('No payment mode data'));
    final total = list.fold<double>(0, (s, p) => s + p.totalAmount);
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: list.map((p) {
                  final pct = total > 0 ? p.totalAmount / total : 0.0;
                  return PieChartSectionData(
                    value: pct * 100,
                    title: '${(pct * 100).toStringAsFixed(1)}%',
                    radius: 50,
                    color: _pieColor(list.indexOf(p)),
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...list.map((p) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: _pieColor(list.indexOf(p)), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(p.paymentMode, style: Theme.of(context).textTheme.bodyMedium)),
                Text('\u20b9${p.totalAmount.toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('(${p.transactionCount})', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _pieColor(int i) {
    const colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.amber, Colors.pink];
    return colors[i % colors.length];
  }
}
