import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/providers/report_provider.dart';
import 'package:provider/provider.dart';

class ItemReportScreen extends StatefulWidget {
  final String? businessId;
  const ItemReportScreen({super.key, this.businessId});

  @override
  State<ItemReportScreen> createState() => _ItemReportScreenState();
}

class _ItemReportScreenState extends State<ItemReportScreen> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(ItemReportScreen old) {
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
      p.fetchItemSales(businessId: widget.businessId, startDate: dp['startDate'], endDate: dp['endDate']),
      p.fetchItemPurchases(businessId: widget.businessId, startDate: dp['startDate'], endDate: dp['endDate']),
      p.fetchInventory(businessId: widget.businessId),
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
            Tab(text: 'Sales'),
            Tab(text: 'Purchases'),
            Tab(text: 'Inventory'),
          ],
        ),
        Expanded(
          child: Consumer<ReportProvider>(
            builder: (context, rp, _) {
              if (rp.isLoading) return const Center(child: CircularProgressIndicator());
              return TabBarView(
                controller: _tabController,
                children: [
                  _salesTab(rp),
                  _purchasesTab(rp),
                  _inventoryTab(rp),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _salesTab(ReportProvider rp) {
    if (rp.error != null) return Center(child: Text(rp.error!));
    final list = rp.itemSales;
    if (list.isEmpty) return const Center(child: Text('No item sales'));
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final s = list[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(s.itemName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))),
                      Text('\u20b9${s.totalRevenue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(s.categoryName, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Qty: ${s.totalQuantitySold}', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 16),
                      Text('GST: ${s.gstRate.toStringAsFixed(0)}%', style: Theme.of(context).textTheme.bodySmall),
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

  Widget _purchasesTab(ReportProvider rp) {
    if (rp.error != null) return Center(child: Text(rp.error!));
    final list = rp.itemPurchases;
    if (list.isEmpty) return const Center(child: Text('No item purchases'));
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final p = list[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(p.itemName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))),
                      Text('\u20b9${p.totalCost.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(p.categoryName, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text('Qty: ${p.totalQuantityPurchased}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _inventoryTab(ReportProvider rp) {
    if (rp.error != null) return Center(child: Text(rp.error!));
    final list = rp.inventory;
    if (list.isEmpty) return const Center(child: Text('No inventory data'));
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final inv = list[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(inv.itemName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))),
                      Text('\u20b9${inv.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(inv.categoryName, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      const Spacer(),
                      Text('Stock: ${inv.stockInHand}', style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: inv.stockInHand > 0 ? Colors.green : Colors.red,
                      )),
                    ],
                  ),
                  if (inv.hsnCode != null) Text('HSN: ${inv.hsnCode}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  Text('Sold: ${inv.totalSold} | Purchased: ${inv.totalPurchased}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
