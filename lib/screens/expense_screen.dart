import 'package:flutter/material.dart';
import 'package:myapp/models/expense_model.dart';
import 'package:myapp/providers/expense_provider.dart';
import 'package:myapp/screens/expense_detail_screen.dart';
import 'package:myapp/widgets/expense_chart.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  bool _showChart = false;

  void _addExpense(Expense expense) {
    Provider.of<ExpenseProvider>(context, listen: false).addExpense(expense);
  }

  void _showAddExpenseDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String category = 'Food'; // Default category
    DateTime? selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Add Expense'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title.';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(labelText: 'Amount'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
                            return 'Please enter a valid amount.';
                          }
                          return null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        items: const [
                          DropdownMenuItem(value: 'Food', child: Text('Food')),
                          DropdownMenuItem(
                              value: 'Transport', child: Text('Transport')),
                          DropdownMenuItem(
                              value: 'Leisure', child: Text('Leisure')),
                          DropdownMenuItem(value: 'Work', child: Text('Work')),
                          DropdownMenuItem(
                              value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              category = value;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Date: ${DateFormat.yMd().format(selectedDate!)}',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_month),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate!,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (pickedDate != null) {
                                setDialogState(() {
                                  selectedDate = pickedDate;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                ElevatedButton(
                  child: const Text('Add'),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final newExpense = Expense(
                          id: const Uuid().v4(),
                          amount: double.parse(amountController.text),
                          date: selectedDate!,
                          category: category);
                      _addExpense(newExpense);
                      Navigator.of(ctx).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Food':
        return Icons.fastfood;
      case 'Transport':
        return Icons.directions_bus;
      case 'Leisure':
        return Icons.sports_esports;
      case 'Work':
        return Icons.work;
      default:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final expenses = expenseProvider.expenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(_showChart ? Icons.list : Icons.pie_chart),
            onPressed: () {
              setState(() {
                _showChart = !_showChart;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ExpenseDetailScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showChart
                ? ExpenseChart(expenses: expenses)
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: expenses.isEmpty
                ? const Center(
                    child: Text(
                      'No expenses yet. Add one!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (ctx, index) {
                      final expense = expenses[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primary.withAlpha(25),
                            child: Icon(
                              _getIconForCategory(expense.category),
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat.yMMMd().format(expense.date),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: Text(
                            '\$${expense.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        label: const Text('Add Expense'),
        icon: const Icon(Icons.add),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }
}
