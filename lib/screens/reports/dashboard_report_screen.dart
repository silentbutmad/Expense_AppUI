import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/report_models.dart';
import 'package:myapp/providers/report_provider.dart';
import 'package:provider/provider.dart';

class DashboardReportScreen extends StatefulWidget {
  final String? businessId;
  const DashboardReportScreen({super.key, this.businessId});

  @override
  State<DashboardReportScreen> createState() => _DashboardReportScreenState();
}

class _DashboardReportScreenState extends State<DashboardReportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void didUpdateWidget(DashboardReportScreen old) {
    super.didUpdateWidget(old);
    if (widget.businessId != old.businessId) _fetch();
  }

  Future<void> _fetch() async {
    final p = context.read<ReportProvider>();
    await p.fetchDashboard(
      businessId: widget.businessId,
      startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
      endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() { _startDate = picked.start; _endDate = picked.end; });
      _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<ReportProvider>(
      builder: (context, rp, _) {
        if (rp.isLoading) return const Center(child: CircularProgressIndicator());
        if (rp.error != null) return Center(child: Text(rp.error!, style: TextStyle(color: theme.colorScheme.error)));
        final d = rp.dashboard;
        if (d == null) return const Center(child: Text('No dashboard data'));

        return RefreshIndicator(
          onRefresh: _fetch,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _dateFilterChip(context),
              const SizedBox(height: 12),
              _kpiRow(context, d),
              const SizedBox(height: 16),
              Text('Recent Transactions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (d.recentTransactions.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No recent transactions')))
              else
                ...d.recentTransactions.map((t) => _recentTxCard(context, t)),
            ],
          ),
        );
      },
    );
  }

  Widget _dateFilterChip(BuildContext context) {
    final label = _startDate != null && _endDate != null
        ? '${DateFormat.yMd().format(_startDate!)} - ${DateFormat.yMd().format(_endDate!)}'
        : 'Select Date Range';
    return InkWell(
      onTap: _pickDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.date_range, size: 16, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 6), Text(label)],
        ),
      ),
    );
  }

  Widget _kpiRow(BuildContext context, DashboardReport d) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - 16) / 3;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _kpiCard(context, 'Total Sales', '\u20b9${d.totalSales.toStringAsFixed(0)}', Colors.green, w),
            _kpiCard(context, 'Total Purchase', '\u20b9${d.totalPurchase.toStringAsFixed(0)}', Colors.orange, w),
            _kpiCard(context, 'Total Expenses', '\u20b9${d.totalExpenses.toStringAsFixed(0)}', Colors.red, w),
            _kpiCard(context, 'Parties', '${d.totalParties}', Colors.blue, w),
            _kpiCard(context, 'Items', '${d.totalItems}', Colors.purple, w),
            _kpiCard(context, 'Reminders', '${d.pendingReminders}', Colors.amber.shade700, w),
          ],
        );
      },
    );
  }

  Widget _kpiCard(BuildContext context, String label, String value, Color color, double width) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text(label, style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey.shade600), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentTxCard(BuildContext context, RecentTransaction t) {
    final theme = Theme.of(context);
    final isSale = t.transactionType == 'SALE';
    final color = isSale ? Colors.green : (t.transactionType == 'EXPENSE' ? Colors.red : Colors.orange);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(isSale ? Icons.arrow_upward : Icons.arrow_downward, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.partyName ?? t.transactionNumber ?? 'N/A', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  if (t.transactionDate != null) Text(t.transactionDate!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
            ),
            Text('\u20b9${t.totalAmount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
