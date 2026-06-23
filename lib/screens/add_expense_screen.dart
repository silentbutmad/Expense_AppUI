import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/expense_model.dart';
import 'package:myapp/providers/expense_provider.dart';
import 'package:provider/provider.dart';



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
  final _amountController = TextEditingController();
  final _personNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _remarkController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Food';
  TransactionCategory _selectedTransactionCategory = TransactionCategory.expense;
  PaymentMode _selectedPaymentMode = PaymentMode.cash;
  bool _isBorrow = true;
  bool _isSubmitting = false;

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
    if (widget.personName != null) {
      _personNameController.text = widget.personName!;
    }
    if (widget.transactionCategory != null) {
      _selectedTransactionCategory = widget.transactionCategory!;
    }
  }

  Future<void> _submitData() async {
    if (_formKey.currentState!.validate()) {
      final enteredAmount = double.tryParse(_amountController.text);
      if (enteredAmount == null || enteredAmount <= 0) {
        return;
      }
      // Prevent duplicate submissions
      if (_isSubmitting) return;
      setState(() {
        _isSubmitting = true;
      });

      try {
        final provider = Provider.of<ExpenseProvider>(context, listen: false);

        final success = await provider.addPersonalTransaction({
          "amount": enteredAmount,
          "name": _personNameController.text.trim(),
          "email": _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          "category": _isLoan ? null : _selectedCategory,
          "remark": _remarkController.text.trim().isEmpty
              ? null
              : _remarkController.text.trim(),
          "payment_mode": _selectedPaymentMode.name.toUpperCase(),
          "transaction_type":
              _selectedTransactionCategory.name.toUpperCase(),
          "loan_type": _isLoan
              ? (_isBorrow ? "BORROW" : "LENT")
              : null,
          "transaction_date": _selectedDate.toIso8601String(),
        });

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction added successfully'),
              ),
            );
            // Navigate back after successful save
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.errorMessage ?? 'Failed to add transaction'),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

   bool get _isLoan => _selectedTransactionCategory == TransactionCategory.loan;

  @override
  Widget build(BuildContext context) {
    final isPersonal = !widget.isBusiness;

    // Dynamic screen title based on transaction type
    String appBarTitle;
    if (widget.isBusiness) {
      appBarTitle = 'Add Business Expense';
    } else if (_selectedTransactionCategory == TransactionCategory.income) {
      appBarTitle = 'Add Income';
    } else if (_selectedTransactionCategory == TransactionCategory.expense) {
      appBarTitle = 'Add Expense';
    } else if (_selectedTransactionCategory == TransactionCategory.loan) {
      if (_isBorrow) {
        appBarTitle = 'Borrow Money';
      } else {
        appBarTitle = 'Lend Money';
      }
    } else {
      appBarTitle = 'Add Transaction';
    }

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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Contact picker coming soon')),
                        );
                      },
                      icon: const Icon(Icons.contacts),
                      tooltip: 'Select from contacts',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoan) ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email ID',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email ID.';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                ],
                if (!_isLoan) ...[
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
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _remarkController,
                  decoration: const InputDecoration(
                    labelText: 'Remark',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),

                if(_isLoan)...[
                  Row(
                    children: [
                      const Text('Loan Type:'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          children: [
                            Radio<bool>(
                              value: true,
                              groupValue: _isBorrow,
                              onChanged: (value) {
                                setState(() {
                                  _isBorrow = value!;
                                });
                              },
                            ),
                            const Text('Borrow'),
                            Radio<bool>(
                              value: false,
                              groupValue: _isBorrow,
                              onChanged: (value) {
                                setState(() {
                                  _isBorrow = value!;
                                });
                              },
                            ),
                            const Text('Lent'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    const Text('Payment Mode:'),
                    const SizedBox(width: 10),
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitData,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(widget.isBusiness ? 'Add Expense' : 'Add Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _personNameController.dispose();
    _emailController.dispose();
    _remarkController.dispose();
    super.dispose();
  }
}
