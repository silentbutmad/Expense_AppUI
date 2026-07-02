import 'package:flutter/material.dart';
import 'package:myapp/providers/report_provider.dart';
import 'package:provider/provider.dart';

class PartyReportScreen extends StatefulWidget {
  final String? businessId;
  const PartyReportScreen({super.key, this.businessId});

  @override
  State<PartyReportScreen> createState() => _PartyReportScreenState();
}

class _PartyReportScreenState extends State<PartyReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
  void didUpdateWidget(PartyReportScreen old) {
    super.didUpdateWidget(old);
    if (widget.businessId != old.businessId) _fetchAll();
  }

  Future<void> _fetchAll() async {
    final p = context.read<ReportProvider>();
    await Future.wait([
      p.fetchPartySummary(businessId: widget.businessId),
      p.fetchTopCustomers(businessId: widget.businessId),
      p.fetchTopSuppliers(businessId: widget.businessId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Top Customers'),
            Tab(text: 'Top Suppliers'),
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
                  _customersTab(rp),
                  _suppliersTab(rp),
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
    final list = rp.partySummaries;
    if (list.isEmpty) return const Center(child: Text('No parties'));
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final p = list[i];
          final isCustomer = p.partyType == 'CUSTOMER';
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isCustomer ? Icons.person : Icons.business, size: 20, color: isCustomer ? Colors.blue : Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p.partyName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: isCustomer ? Colors.blue.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                        child: Text(p.partyType, style: TextStyle(fontSize: 10, color: isCustomer ? Colors.blue : Colors.orange)),
                      ),
                    ],
                  ),
                  if (p.phone != null) Text(p.phone!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _stat('Transactions', '${p.totalTransactions}'),
                      const SizedBox(width: 16),
                      _stat('Sales', '\u20b9${p.totalSales.toStringAsFixed(0)}'),
                      const SizedBox(width: 16),
                      _stat('Purchase', '\u20b9${p.totalPurchase.toStringAsFixed(0)}'),
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

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _customersTab(ReportProvider rp) {
    if (rp.error != null) return Center(child: Text(rp.error!));
    final list = rp.topCustomers;
    if (list.isEmpty) return const Center(child: Text('No customers'));
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final c = list[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text('${i + 1}', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
              ),
              title: Text(c.partyName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: c.phone != null ? Text(c.phone!) : null,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\u20b9${c.totalSales.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  Text('${c.transactionCount} txns', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _suppliersTab(ReportProvider rp) {
    if (rp.error != null) return Center(child: Text(rp.error!));
    final list = rp.topSuppliers;
    if (list.isEmpty) return const Center(child: Text('No suppliers'));
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final s = list[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade100,
                child: Text('${i + 1}', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
              ),
              title: Text(s.partyName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: s.phone != null ? Text(s.phone!) : null,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\u20b9${s.totalPurchase.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  Text('${s.transactionCount} txns', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
