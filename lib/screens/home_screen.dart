import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/screens/business_tab_screen.dart' show BusinessTabContent;
import 'package:myapp/screens/personal_tab_screen.dart' show PersonalTabContent;
import 'package:myapp/providers/business_provider.dart';
import 'package:provider/provider.dart';

enum ExpenseMode { personal, business }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  ExpenseMode _mode = ExpenseMode.personal;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _restoreLastBusiness();
  }

  Future<void> _restoreLastBusiness() async {
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    await businessProvider.fetchBusinesses();
    await businessProvider.restoreLastSelectedBusiness();
    setState(() {
      _isInitialized = true;
    });
  }

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
    final isBusiness = _mode == ExpenseMode.business;

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
      body: Column(
        children: [
          // TOGGLE BUTTON
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Personal"),
                  selected: !isBusiness,
                  onSelected: (_) {
                    setState(() => _mode = ExpenseMode.personal);
                  },
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                const SizedBox(width: 40),
                ChoiceChip(
                  label: const Text("Business"),
                  selected: isBusiness,
                  onSelected: (_) {
                    setState(() => _mode = ExpenseMode.business);
                  },
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isInitialized
                ? isBusiness
                    ? const BusinessTabContent()
                    : const PersonalTabContent()
                : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
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
}