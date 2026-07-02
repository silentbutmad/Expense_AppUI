import 'package:flutter/material.dart';
import 'package:myapp/utils/amount_parser.dart';
import 'package:intl/intl.dart';
import 'package:myapp/providers/expense_provider.dart';
import 'package:provider/provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final bool isBusiness;
  final String? transactionType;
  final String? personName;
  final String? transactionCategory;
  final String? transactionId;
  final Map<String, dynamic>? existingTransaction;

  const AddExpenseScreen({
    super.key,
    this.isBusiness = false,
    this.transactionType,
    this.personName,
    this.transactionCategory,
    this.transactionId,
    this.existingTransaction,
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
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedCategory = 'Food';
  String _selectedTransactionCategory = 'EXPENSE';
  String _selectedPaymentMode = 'CASH';
  bool _isBorrow = true;
  bool _isSubmitting = false;
  bool _isLoadingData = false;

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
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  void _presentTimePicker() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((pickedTime) {
      if (pickedTime == null) {
        return;
      }
      setState(() {
        _selectedTime = pickedTime;
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
    if (widget.existingTransaction != null) {
      _loadExistingTransaction(widget.existingTransaction!);
    }
  }

  Future<void> _loadExistingTransaction(Map<String, dynamic> tx) async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // Parse all values first
      final rawAmount = tx['amount'];
      final name = tx['name'] as String?;
      final email = tx['email'] as String?;
      final remark = tx['remark'] as String?;
      final category = tx['category'] as String?;
      final transactionCategory = tx['transaction_type'] as String?;
      final paymentMode = tx['payment_mode'] as String?;
      final dateStr = tx['transaction_date'] as String?;
      final loanType = tx['loan_type'] as String?;
      
      // Parse date/time
      DateTime? parsedDate;
      TimeOfDay? parsedTime;
      if (dateStr != null && dateStr.isNotEmpty) {
        try {
          final dateTime = DateTime.parse(dateStr);
          parsedDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
          parsedTime = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
          debugPrint('Personal tx - Parsed datetime: $parsedDate $parsedTime');
        } catch (e) {
          debugPrint('Error parsing personal transaction date: $e');
        }
      }
      
      // Now set all values in a single setState
      setState(() {
        if (rawAmount != null) {
          _amountController.text = parseAmount(rawAmount).toString();
        }
        if (name != null) {
          _personNameController.text = name;
        }
        if (email != null) {
          _emailController.text = email;
        }
        if (remark != null) {
          _remarkController.text = remark;
        }
        if (category != null) {
          _selectedCategory = category;
        }
        if (transactionCategory != null) {
          _selectedTransactionCategory = transactionCategory;
        }
        if (paymentMode != null) {
          _selectedPaymentMode = paymentMode;
        }
        if (parsedDate != null) {
          _selectedDate = parsedDate;
        }
        if (parsedTime != null) {
          _selectedTime = parsedTime;
        }
        if (loanType != null) {
          _isBorrow = loanType == 'BORROW';
        }
        
        _isLoadingData = false;
      });
    } catch (e) {
      debugPrint('Error loading personal transaction: $e');
      setState(() {
        _isLoadingData = false;
      });
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

        final isLoan = _selectedTransactionCategory == 'LOAN';
        
        final transactionData = {
          "amount": enteredAmount,
          "name": _personNameController.text.trim(),
          "email": _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          "category": isLoan ? null : _selectedCategory,
          "remark": _remarkController.text.trim().isEmpty
              ? null
              : _remarkController.text.trim(),
          "payment_mode": _selectedPaymentMode,
          "transaction_type": _selectedTransactionCategory,
          "loan_type": isLoan
              ? (_isBorrow ? "BORROW" : "LENT")
              : null,
          "transaction_date": DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _selectedTime.hour,
            _selectedTime.minute,
          ).toIso8601String(),
        };

        bool success;
        if (widget.transactionId != null) {
          // Update existing transaction
          success = await provider.updateTransaction(widget.transactionId!, transactionData);
        } else {
          // Add new transaction
          success = await provider.addPersonalTransaction(transactionData);
        }

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction saved successfully'),
              ),
            );
            // Navigate back after successful save
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.errorMessage ?? 'Failed to save transaction'),
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

  bool get _isLoan => _selectedTransactionCategory == 'LOAN';

  @override
  Widget build(BuildContext context) {
    final isPersonal = !widget.isBusiness;

    // Dynamic screen title based on transaction type
    String appBarTitle;
    if (widget.isBusiness) {
      appBarTitle = 'Add Business Expense';
    } else if (_selectedTransactionCategory == 'INCOME') {
      appBarTitle = 'Add Income';
    } else if (_selectedTransactionCategory == 'EXPENSE') {
      appBarTitle = 'Add Expense';
    } else if (_selectedTransactionCategory == 'LOAN') {
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
          child: _isLoadingData
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
                                Radio<String>(
                                  value: 'CASH',
                                  groupValue: _selectedPaymentMode,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPaymentMode = value!;
                                    });
                                  },
                                ),
                                const Text('Cash'),
                                Radio<String>(
                                  value: 'ONLINE',
                                  groupValue: _selectedPaymentMode,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPaymentMode = value!;
                                    });
                                  },
                                ),
                                const Text('Online'),
                                Radio<String>(
                                  value: 'OTHER',
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
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Time: ${_selectedTime.format(context)}',
                          ),
                        ),
                        TextButton(
                          onPressed: _presentTimePicker,
                          child: const Text(
                            'Choose Time',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                          : Text(widget.transactionId != null
                              ? 'Update Transaction'
                              : widget.isBusiness
                                  ? 'Add Expense'
                                  : 'Add Transaction'),
                    ),
                    ],
                  ),
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