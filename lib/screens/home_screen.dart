import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/expense_provider.dart';
import 'package:myapp/screens/personal_tab_screen.dart' show PersonalTabContent;
import 'package:myapp/widgets/expense_list.dart';
import 'package:myapp/widgets/expense_pie_chart.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/expense_model.dart';

enum ExpenseMode { personal, business }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  ExpenseMode _mode = ExpenseMode.personal;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        context.push('/reports');
        break;
      case 2:
        context.push('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    final isBusiness = _mode == ExpenseMode.business;

    // Use backend summary for totals (consistent data source)
    final totalIncome = expenseProvider.totalIncome;
    final totalExpenses = expenseProvider.totalExpense;
    final totalBalance = expenseProvider.totalBalance;

    // Filter local expenses for display only
    final filteredExpenses = expenseProvider.expenses
        .where((e) => e.isBusinessExpense == isBusiness)
        .toList();

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 TOGGLE BUTTON
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Personal"),
                  selected: _mode == ExpenseMode.personal,
                  onSelected: (_) {
                    setState(() => _mode = ExpenseMode.personal);
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Business"),
                  selected: _mode == ExpenseMode.business,
                  onSelected: (_) {
                    setState(() => _mode = ExpenseMode.business);
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (isBusiness) ...[
              // 💰 BUSINESS BALANCE CARD
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Business Balance',
                        style: textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '\u20b9${totalBalance.toStringAsFixed(2)}',
                        style: textTheme.displayLarge?.copyWith(
                          color: totalBalance >= 0
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                'Revenue',
                                style: textTheme.titleMedium,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '\u20b9${totalIncome.toStringAsFixed(2)}',
                                style: textTheme.bodyLarge
                                    ?.copyWith(color: Colors.green),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                'Costs',
                                style: textTheme.titleMedium,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '\u20b9${totalExpenses.toStringAsFixed(2)}',
                                style: textTheme.bodyLarge
                                    ?.copyWith(color: Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ⚡ QUICK ACTIONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickActionButton(
                    context,
                    icon: Icons.add,
                    label: 'Add Business Expense',
                    onPressed: () => context.push('/add-expense', extra: true),
                  ),
                  _buildQuickActionButton(
                    context,
                    icon: Icons.add_card,
                    label: 'Add Revenue',
                    onPressed: () => context.push('/add-expense', extra: {
                      'isBusiness': true,
                      'transactionType': TransactionType.received,
                      'transactionCategory': TransactionCategory.income,
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // 📊 PIE CHART
              Text(
                'Business Expenses',
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 15),

              SizedBox(
                height: 200,
                child: filteredExpenses.isEmpty
                    ? const Center(child: Text('No expenses yet.'))
                    : ExpensePieChart(expenses: filteredExpenses),
              ),

              const SizedBox(height: 25),

              // 📋 RECENT TRANSACTIONS
              Text(
                'Recent Transactions',
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),

              filteredExpenses.isEmpty
                  ? const Center(child: Text('No recent transactions.'))
                  : ExpenseList(
                      expenses: filteredExpenses.take(5).toList(),
                    ),
            ] else ...[
              // Personal Tab Content
              const PersonalTabContent(),
            ],
          ],
        ),
      ),

      // 🔻 BOTTOM NAV
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: label,
          onPressed: onPressed,
          child: Icon(icon, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}