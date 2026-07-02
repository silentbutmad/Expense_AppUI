import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/providers/report_provider.dart';
import 'package:provider/provider.dart';

class GstReportScreen extends StatefulWidget {
  final String? businessId;
  const GstReportScreen({super.key, this.businessId});

  @override
  State<GstReportScreen> createState() => _GstReportScreenState();
}

class _GstReportScreenState extends State<GstReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GstReportScreen old) {
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
      p.fetchGstSummary(businessId: widget.businessId, startDate: dp['startDate'], endDate: dp['endDate']),
      p.fetchGstDetails(businessId: widget.businessId, startDate: dp['startDate'], endDate: dp['endDate']),
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
            Tab(text: 'Summary'),
            Tab(text: 'Details'),
          ],
        ),
        Expanded(
          child: Consumer<ReportProvider>(
            builder: (context, rp, _) {
              if (rp.isLoading) return const Center(child: CircularProgressIndicator());
              return TabBarView(
                controller: _tabController,
                children: [
                  _summaryTab(rp),
                  _detailsTab(rp),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _summaryTab(ReportProvider rp) {
    if (rp.error != null) return Center(child: Text(rp.error!));
    final s = rp.gstSummary;
    if (s == null) return const Center(child: Text('No GST summary'));
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _kpiCard(context, 'GST Collected', '\u20b9${s.totalGstCollected.toStringAsFixed(2)}', Colors.blue),
          const SizedBox(height: 12),
          _kpiCard(context, 'GST Paid', '\u20b9${s.totalGstPaid.toStringAsFixed(2)}', Colors.orange),
          const SizedBox(height: 12),
          _kpiCard(context, 'Net GST', '\u20b9${s.netGst.toStringAsFixed(2)}', s.netGst >= 0 ? Colors.green : Colors.red),
        ],
      ),
    );
  }

  Widget _kpiCard(BuildContext context, String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _detailsTab(ReportProvider rp) {
    if (rp.error != null) return Center(child: Text(rp.error!));
    final list = rp.gstDetails;
    if (list.isEmpty) return const Center(child: Text('No GST details'));
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final g = list[i];
          final isSale = g.transactionType == 'SALE';
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(g.transactionNumber ?? 'N/A', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: (isSale ? Colors.green : Colors.orange).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                        child: Text(g.transactionType, style: TextStyle(fontSize: 10, color: isSale ? Colors.green : Colors.orange)),
                      ),
                    ],
                  ),
                  if (g.partyName != null) Text(g.partyName!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                  if (g.transactionDate != null) Text(g.transactionDate!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _gstField('Subtotal', '\u20b9${g.subtotalAmount.toStringAsFixed(0)}'),
                      const SizedBox(width: 16),
                      _gstField('GST', '\u20b9${g.totalGstAmount.toStringAsFixed(0)}'),
                      const Spacer(),
                      Text('\u20b9${g.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _gstField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
