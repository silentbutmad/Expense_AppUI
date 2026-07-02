import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/providers/report_provider.dart';
import 'package:provider/provider.dart';

class HistoryReportScreen extends StatefulWidget {
  const HistoryReportScreen({super.key});

  @override
  State<HistoryReportScreen> createState() => _HistoryReportScreenState();
}

class _HistoryReportScreenState extends State<HistoryReportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    final p = context.read<ReportProvider>();
    await p.fetchHistory(
      startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
      endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context, firstDate: DateTime(2020), lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null ? DateTimeRange(start: _startDate!, end: _endDate!) : null,
    );
    if (picked != null) {
      setState(() { _startDate = picked.start; _endDate = picked.end; });
      _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        Expanded(
          child: Consumer<ReportProvider>(
            builder: (context, rp, _) {
              if (rp.isLoading) return const Center(child: CircularProgressIndicator());
              if (rp.error != null) return Center(child: Text(rp.error!));
              final list = rp.history;
              if (list.isEmpty) return const Center(child: Text('No transaction history'));
              return RefreshIndicator(
                onRefresh: _fetch,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final h = list[i];
                    final isPersonal = h.contextType == 'PERSONAL';
                    final contextColor = isPersonal ? Colors.purple : Colors.blue;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: contextColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                              child: Icon(isPersonal ? Icons.person : Icons.business, color: contextColor, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(h.partyName ?? h.transactionType, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(color: contextColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                        child: Text(h.contextType, style: TextStyle(fontSize: 9, color: contextColor)),
                                      ),
                                    ],
                                  ),
                                  if (h.transactionDate != null) Text(h.transactionDate!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                                  if (h.description != null) Text(h.description!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500)),
                                ],
                              ),
                            ),
                            Text('\u20b9${h.amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: contextColor)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
