import 'package:flutter/material.dart';
import 'package:myapp/providers/business_provider.dart';
import 'package:myapp/screens/reports/business_report_screen.dart';
import 'package:myapp/screens/reports/dashboard_report_screen.dart';
import 'package:myapp/screens/reports/financial_report_screen.dart';
import 'package:myapp/screens/reports/gst_report_screen.dart';
import 'package:myapp/screens/reports/history_report_screen.dart';
import 'package:myapp/screens/reports/item_report_screen.dart';
import 'package:myapp/screens/reports/party_report_screen.dart';
import 'package:myapp/screens/reports/personal_report_screen.dart';
import 'package:provider/provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final businessProvider = context.watch<BusinessProvider>();
    final businessId = businessProvider.selectedBusiness?.business_id;

    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Dashboard'),
              Tab(text: 'Personal'),
              Tab(text: 'Business'),
              Tab(text: 'Parties'),
              Tab(text: 'Items'),
              Tab(text: 'GST'),
              Tab(text: 'Financials'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DashboardReportScreen(businessId: businessId),
            const PersonalReportScreen(),
            BusinessReportScreen(businessId: businessId),
            PartyReportScreen(businessId: businessId),
            ItemReportScreen(businessId: businessId),
            GstReportScreen(businessId: businessId),
            FinancialReportScreen(businessId: businessId),
            const HistoryReportScreen(),
          ],
        ),
      ),
    );
  }
}
