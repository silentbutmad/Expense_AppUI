import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/providers/report_provider.dart';
import 'package:provider/provider.dart';

class FinancialReportScreen extends StatefulWidget {
  final String? businessId;
  const FinancialReportScreen({super.key, this.businessId});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _startDate;
  DateTime? _endDate;

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

  @override
  void didUpdateWidget(FinancialReportScreen old) {
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
      p.fetchProfitLoss(businessId: widget.businessId, startDate: dp['startDate'], endDate: dp['endDate']),
      p.fetchCashFlow(businessId: widget.businessId, startDate: dp['startDate'], endDate: dp['endDate']),
      p.fetchMonthlyTrends(businessId: widget.businessId, startDate: dp['startDate'], endDate: dp['endDate']),
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
            Tab(text: 'P&L'),
            Tab(text: 'Cash Flow'),
            Tab(text: 'Monthly'),
          ],
        ),
        Expanded(
          child: Consumer<ReportProvider>(
            builder: (context, rp, _) {
              if (rp.isLoading) return const Center(child: CircularProgressIndicator());
              return TabBarView(
                controller: _tabController,
                children: [
                  _profitLossTab(rp),
                  _cashFlowTab(rp),
                  _monthlyTab(rp),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _profitLossTab(ReportProvider rp) {
    if (rp.error != null) return Center(child: Text(rp.error!));
    final pl = rp.profitLoss;
    if (pl == null) return const Center(child: Text('No P&L data'));
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _plRow('Total Sales', pl.totalSales, Colors.green),
          _plRow('Total Purchases', pl.totalPurchase, Colors.orange),
          const Divider(),
          _plRow('Gross Profit', pl.grossProfit, Colors.blue),
          const Divider(),
          _plRow('Total Expenses', pl.totalExpenses, Colors.red),
          const Divider(thickness: 2),
          _plRow('Net Profit', pl.netProfit, pl.netProfit >= 0 ? Colors.green : Colors.red),
        ],
      ),
    );
  }

  Widget _plRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
          Text('\u20b9${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _cashFlowTab(ReportProvider rp) {
    if (rp.error != null) return Center(child: Text(rp.error!));
    final list = rp.cashFlow;
    if (list.isEmpty) return const Center(child: Text('No cash flow data'));
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final cf = list[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 3),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cf.date ?? '', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      Text('${cf.transactionType} (${cf.contextType})', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                  const Spacer(),
                  if (cf.amountIn > 0)
                    Text('+\u20b9${cf.amountIn.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12))
                  else
                    Text('-\u20b9${cf.amountOut.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: Text('\u20b9${cf.balance.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _monthlyTab(ReportProvider rp) {
    if (rp.error != null) return Center(child: Text(rp.error!));
    final list = rp.monthlyTrends;
    if (list.isEmpty) return const Center(child: Text('No monthly data'));
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: list.map((m) => [m.totalSales, m.totalPurchase, m.totalExpenses].reduce((a, b) => a > b ? a : b)).reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i >= 0 && i < list.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(list[i].month.length >= 7 ? list[i].month.substring(5) : list[i].month, style: const TextStyle(fontSize: 9)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: list.asMap().entries.map((entry) {
                  final i = entry.key;
                  final m = entry.value;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(toY: m.totalSales, color: Colors.green, width: 6, borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2))),
                      BarChartRodData(toY: m.totalPurchase, color: Colors.orange, width: 6, borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2))),
                      BarChartRodData(toY: m.totalExpenses, color: Colors.red, width: 6, borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend('Sales', Colors.green),
              const SizedBox(width: 16),
              _legend('Purchases', Colors.orange),
              const SizedBox(width: 16),
              _legend('Expenses', Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          ...list.map((m) => Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.month, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _monthRow('Sales', m.totalSales, Colors.green),
                  _monthRow('Purchases', m.totalPurchase, Colors.orange),
                  _monthRow('Expenses', m.totalExpenses, Colors.red),
                  const Divider(),
                  _monthRow('Net Profit', m.netProfit, m.netProfit >= 0 ? Colors.green : Colors.red),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _monthRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Text('\u20b9${amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
