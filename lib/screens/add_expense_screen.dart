import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/expense_model.dart';
import 'package:myapp/providers/expense_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddExpenseScreen extends StatefulWidget {
  final bool isBusiness;
  final TransactionType? transactionType;
  final String? personName;
  final TransactionCategory? transactionCategory;

  const AddExpenseScreen({
    super.key,
    this.isBusiness = false,
    this.transactionType,
    this.personName,
    this.transactionCategory,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _personNameController = TextEditingController();
  final _remarkController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Food';
  TransactionType _selectedTransactionType = TransactionType.paid;
  TransactionCategory _selectedTransactionCategory = TransactionCategory.expense;
  PaymentMode _selectedPaymentMode = PaymentMode.cash;

  final List<String> _categories = [
    'Other',
    'Insurance',
    'Entertainment',
    'Food',
    'Transport',
    'Shopping',
    'Groceries',
    'Health',
    'Electronics',
    'Social Life',
    'Petty cash',
    'EMI',
    'Salary',
    'Investment',
    'Bonus',
    'Home',
    'Repairs',
    'Pocket money',
  ];

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.transactionType != null) {
      _selectedTransactionType = widget.transactionType!;
    }
    if (widget.personName != null) {
      _personNameController.text = widget.personName!;
    }
    if (widget.transactionCategory != null) {
      _selectedTransactionCategory = widget.transactionCategory!;
    }
  }

  void _submitData() {
    if (_formKey.currentState!.validate()) {
      final enteredAmount = double.tryParse(_amountController.text);
      if (enteredAmount == null || enteredAmount <= 0) {
        return;
      }
      final newExpense = Expense(
        id: const Uuid().v4(),
        title: _titleController.text,
        amount: enteredAmount,
        date: _selectedDate,
        category: _selectedCategory,
        contextType: widget.isBusiness ? ContextType.business : ContextType.personal,
        transactionCategory: _selectedTransactionCategory,
        personName: _personNameController.text.trim().isEmpty
            ? null
            : _personNameController.text.trim(),
        transactionType: widget.isBusiness ? null : _selectedTransactionType,
        remark: _remarkController.text.trim().isEmpty
            ? null
            : _remarkController.text.trim(),
        paymentMode: _selectedPaymentMode,
      );
      Provider.of<ExpenseProvider>(context, listen: false)
          .addExpense(newExpense);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPersonal = !widget.isBusiness;
    final appBarTitle = widget.isBusiness
        ? 'Add Business Expense'
        : (_selectedTransactionType == TransactionType.received
            ? 'Add Money Received'
            : 'Add Money Paid');

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount.';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number.';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Please enter a number greater than zero.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (isPersonal) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _personNameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        // TODO: Implement contact picker
                      },
                      icon: const Icon(Icons.contacts),
                      tooltip: 'Select from contacts',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TransactionCategory>(
                  initialValue: _selectedTransactionCategory,
                  items: const [
                    DropdownMenuItem(
                      value: TransactionCategory.income,
                      child: Text('Income'),
                    ),
                    DropdownMenuItem(
                      value: TransactionCategory.expense,
                      child: Text('Expense'),
                    ),
                    DropdownMenuItem(
                      value: TransactionCategory.loan,
                      child: Text('Loan'),
                    ),
                  ],
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedTransactionCategory = newValue;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField(
                  initialValue: _selectedCategory,
                  items: _categories.map((String category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue as String;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Sub Category',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _remarkController,
                  decoration: const InputDecoration(
                    labelText: 'Remark',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Payment Mode:'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Radio<PaymentMode>(
                            value: PaymentMode.cash,
                            groupValue: _selectedPaymentMode,
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMode = value!;
                              });
                            },
                          ),
                          const Text('Cash'),
                          Radio<PaymentMode>(
                            value: PaymentMode.online,
                            groupValue: _selectedPaymentMode,
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMode = value!;
                              });
                            },
                          ),
                          const Text('Online'),
                          Radio<PaymentMode>(
                            value: PaymentMode.other,
                            groupValue: _selectedPaymentMode,
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMode = value!;
                              });
                            },
                          ),
                          const Text('Other'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Date: ${DateFormat.yMd().format(_selectedDate)}',
                    ),
                  ),
                  TextButton(
                    onPressed: _presentDatePicker,
                    child: const Text(
                      'Choose Date',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                ),
                child: Text(widget.isBusiness ? 'Add Expense' : 'Add Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
