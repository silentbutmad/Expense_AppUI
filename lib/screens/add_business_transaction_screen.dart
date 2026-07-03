import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/business_models.dart';
import 'package:myapp/providers/business_provider.dart';
import 'package:provider/provider.dart';

class LineItem {
  String? itemId;
  String description = '';
  int quantity = 1;
  double price = 0.0;
  double gstRate = 18.0; // Default GST rate
  Map<String, dynamic> toJson() => {
    if (itemId != null) 'item_id': itemId,
    'description': description, 'quantity': quantity, 'price': price,
    'gst_rate': gstRate,
  };
  double get total => quantity * price;
  double get gstAmount => total * gstRate / 100;
  double get totalWithGst => total + gstAmount;
}

class AddBusinessTransactionScreen extends StatefulWidget {
  final bool isEdit;
  final String? transactionId;
  final Map<String, dynamic>? existingTransaction;

  const AddBusinessTransactionScreen({
    super.key,
    this.isEdit = false,
    this.transactionId,
    this.existingTransaction,
  });
  
  @override
  State<AddBusinessTransactionScreen> createState() => _AddBusinessTransactionScreenState();
}

class _AddBusinessTransactionScreenState extends State<AddBusinessTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _txnType = 'SALE';
  DateTime _txnDate = DateTime.now();
  TimeOfDay _txnTime = TimeOfDay.now();
  DateTime? _dueDate;
  PartyModel? _selParty;
  final List<LineItem> _items = [LineItem()];
  final Map<int, TextEditingController> _priceControllers = {};
  final Map<int, TextEditingController> _qtyControllers = {};
  final Map<int, double> _itemGstRates = {}; // Per-item GST rates
  final _gstCtrl = TextEditingController(text: '18');
  double _gstPct = 18;
  
  // Available GST rates
  static const List<double> _availableGstRates = [0, 5, 12, 18, 28];
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  
  bool get _isEditMode => widget.isEdit;
  bool _isLoadingData = false;

  @override 
  void initState() {
    super.initState();
    _priceControllers[0] = TextEditingController();
    _qtyControllers[0] = TextEditingController(text: '1');
    
    // Load existing transaction data if in edit mode
    if (_isEditMode && widget.existingTransaction != null) {
      _loadExistingTransaction(widget.existingTransaction!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If we have a partyId but no party object, look it up from provider
    if (_isEditMode && widget.existingTransaction != null) {
      final partyId = widget.existingTransaction!['party_id'] as String?;
      if (partyId != null && _selParty == null) {
        final provider = Provider.of<BusinessProvider>(context, listen: false);
        try {
          _selParty = provider.parties.firstWhere((p) => p.id == partyId);
          debugPrint('Found party from provider: ${_selParty!.name}');
          // Trigger rebuild to show the selected party
          if (mounted) {
            setState(() {});
          }
        } catch (e) {
          debugPrint('Party not found in provider list: $partyId');
        }
      }
    }
  }
  
  Future<void> _loadExistingTransaction(Map<String, dynamic> tx) async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final transactionType = tx['transaction_type'] as String? ?? 'SALE';
      final txnTypeUpper = transactionType.toUpperCase();
      final transactionDate = tx['transaction_date'] as String? ?? '';
      final dueDate = tx['due_date'] as String?;
      final title = tx['title'] as String? ?? '';
      final description = tx['description'] as String? ?? '';
      // For EXPENSE transactions, use total_amount (saved directly, subtotal is 0)
      // For other transactions, use total_amount
      final amount = tx['total_amount'] ?? tx['subtotal_amount'] ?? 0.0;
      final partyId = tx['party_id'] as String?;
      final partyData = tx['party'] as Map<String, dynamic>?;
      final items = tx['items'] as List<dynamic>? ?? [];
      
      setState(() {
        _txnType = txnTypeUpper;
        _titleCtrl.text = title;
        _descriptionCtrl.text = description;
        _amountCtrl.text = amount.toString();
        
        // Parse date and time - backend sends separate fields for business transactions
        if (transactionDate.isNotEmpty) {
          try {
            final dateTime = DateTime.parse(transactionDate);
            _txnDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
            debugPrint('Parsed date: $_txnDate');
          } catch (e) {
            debugPrint('Error parsing date: $e');
          }
        }
        
        // Parse time from separate transaction_time field if available
        final transactionTime = tx['transaction_time'] as String?;
        if (transactionTime != null && transactionTime.isNotEmpty) {
          try {
            final timeParts = transactionTime.split(':');
            if (timeParts.length >= 2) {
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              _txnTime = TimeOfDay(hour: hour, minute: minute);
              debugPrint('Parsed time from transaction_time: $_txnTime');
            }
          } catch (e) {
            debugPrint('Error parsing time: $e');
          }
        } else if (transactionDate.isNotEmpty && transactionDate.contains('T')) {
          // Fallback: extract time from datetime string
          try {
            final dateTime = DateTime.parse(transactionDate);
            _txnTime = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
            debugPrint('Parsed time from datetime: $_txnTime');
          } catch (e) {
            debugPrint('Error parsing time from datetime: $e');
          }
        }
        
        // Parse due date
        if (dueDate != null && dueDate.isNotEmpty) {
          try {
            _dueDate = DateTime.parse(dueDate);
          } catch (e) {
            debugPrint('Error parsing due date: $e');
          }
        }
        
        // Load party if available
        if (partyData != null) {
          _selParty = PartyModel.fromJson(partyData);
          debugPrint('Loaded party from transaction data: ${_selParty!.name}');
        } else if (partyId != null) {
          // Try to find party from provider
          final provider = Provider.of<BusinessProvider>(context, listen: false);
          try {
            _selParty = provider.parties.firstWhere((p) => p.id == partyId);
            debugPrint('Found party from provider: ${_selParty!.name}');
          } catch (e) {
            debugPrint('Party not found in provider list: $partyId');
          }
        }
        
        // Load items - ensure price is properly loaded
        if (items.isNotEmpty) {
          _items.clear();
          for (var i = 0; i < items.length; i++) {
            final item = items[i];
            if (item is Map) {
              final lineItem = LineItem();
              lineItem.itemId = item['item_id'] as String?;
              lineItem.description = item['description'] as String? ?? '';
              lineItem.quantity = item['quantity'] as int? ?? 1;
              
              // Parse price - handle both num and string types
              final priceValue = item['price'];
              if (priceValue is num) {
                lineItem.price = priceValue.toDouble();
              } else if (priceValue is String) {
                lineItem.price = double.tryParse(priceValue) ?? 0.0;
              } else {
                lineItem.price = 0.0;
              }
              
              // Parse GST rate
              final gstValue = item['gst_rate'];
              if (gstValue is num) {
                lineItem.gstRate = gstValue.toDouble();
              } else if (gstValue is String) {
                lineItem.gstRate = double.tryParse(gstValue) ?? 18.0;
              } else {
                lineItem.gstRate = 18.0;
              }
              
              _items.add(lineItem);
              debugPrint('Loaded item $i: ${lineItem.description}, price: ${lineItem.price}, qty: ${lineItem.quantity}');
              
              // Create controllers for this item
              _priceControllers[i] = TextEditingController(text: lineItem.price.toString());
              _qtyControllers[i] = TextEditingController(text: lineItem.quantity.toString());
              _itemGstRates[i] = lineItem.gstRate;
            }
          }
        }
        
        _isLoadingData = false;
      });
    } catch (e) {
      debugPrint('Error loading transaction: $e');
      setState(() {
        _isLoadingData = false;
      });
    }
  }
  
  @override 
  void dispose() {
    _gstCtrl.dispose(); 
    _titleCtrl.dispose(); 
    _descriptionCtrl.dispose(); 
    _amountCtrl.dispose();
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // For EXPENSE: amount entered is the total (no GST)
  // For SALE/PURCHASE: calculate from items
  double get _subtotal => _txnType == 'EXPENSE' 
      ? double.tryParse(_amountCtrl.text) ?? 0.0
      : _items.fold(0.0, (s, i) => s + i.total);
  double get _totalGst => _txnType == 'EXPENSE' 
      ? 0.0 // No GST for expenses
      : _items.fold(0.0, (s, i) => s + i.gstAmount);
  double get _totalAmt => _txnType == 'EXPENSE' 
      ? _subtotal // For expenses, total = subtotal (no GST)
      : _subtotal + _totalGst;

  // Get filtered parties based on transaction type
  List<PartyModel> _getFilteredParties(List<PartyModel> allParties) {
    if (_txnType == 'SALE') {
      return allParties.where((p) => p.partyType == 'CUSTOMER').toList();
    } else if (_txnType == 'PURCHASE') {
      return allParties.where((p) => p.partyType == 'SUPPLIER').toList();
    }
    return allParties;
  }

  void _resetForm() {
    setState(() {
      _txnType = 'SALE';
      _txnDate = DateTime.now();
      _txnTime = TimeOfDay.now();
      _dueDate = null;
      _selParty = null;
      _items.clear();
      _items.add(LineItem());
      _gstPct = 18;
      
      _gstCtrl.text = '18';
      _titleCtrl.clear();
      _descriptionCtrl.clear();
      _amountCtrl.clear();
      
      for (final controller in _priceControllers.values) {
        controller.dispose();
      }
      for (final controller in _qtyControllers.values) {
        controller.dispose();
      }
      _priceControllers.clear();
      _qtyControllers.clear();
      _itemGstRates.clear();
      _priceControllers[0] = TextEditingController();
      _qtyControllers[0] = TextEditingController(text: '1');
    });
  }

  void _addItem() {
    setState(() {
      final index = _items.length;
      _items.add(LineItem());
      _priceControllers[index] = TextEditingController();
      _qtyControllers[index] = TextEditingController(text: '1');
      _itemGstRates[index] = 18.0; // Default GST rate for new item
    });
  }
  
  void _removeItem(int i) { 
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(i);
        _priceControllers[i]?.dispose();
        _priceControllers.remove(i);
        _qtyControllers[i]?.dispose();
        _qtyControllers.remove(i);
        _itemGstRates.remove(i);
        // Reindex remaining GST rates
        final newGstRates = <int, double>{};
        int newIndex = 0;
        for (int oldIndex = 0; oldIndex < _items.length; oldIndex++) {
          if (oldIndex != i) {
            newGstRates[newIndex] = _itemGstRates[oldIndex] ?? 18.0;
            newIndex++;
          }
        }
        _itemGstRates.clear();
        _itemGstRates.addAll(newGstRates);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final p = Provider.of<BusinessProvider>(context, listen: false);
    final b = p.selectedBusiness;
    if (b == null) return;

    // Combine date and time into single datetime field for backend
    final combinedDateTime = DateTime(
      _txnDate.year,
      _txnDate.month,
      _txnDate.day,
      _txnTime.hour,
      _txnTime.minute,
    );
    
    Map<String, dynamic> transactionData = {
      'business_id': b.business_id,
      'transaction_type': _txnType,
      'transaction_date': combinedDateTime.toIso8601String(),
      if (_dueDate != null) 'due_date': DateFormat('yyyy-MM-dd').format(_dueDate!),
      'subtotal_amount': _subtotal,
      'total_gst_amount': _totalGst,
      'total_amount': _totalAmt,
    };

    if (_txnType == 'EXPENSE') {
      transactionData['title'] = _titleCtrl.text;
      transactionData['description'] = _descriptionCtrl.text.isEmpty ? null : _descriptionCtrl.text;
    } else {
      if (_selParty != null) transactionData['party_id'] = _selParty!.id;
      transactionData['items'] = _items.map((e) => e.toJson()).toList();
    }

    bool success;
    if (_isEditMode && widget.transactionId != null) {
      success = await p.updateBusinessTransaction(widget.transactionId!, transactionData);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction updated!')));
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(p.errorMessage ?? 'Failed')));
        }
      }
    } else {
      success = await p.addBusinessTransaction(transactionData);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction created!')));
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(p.errorMessage ?? 'Failed')));
        }
      }
    }
  }

  // --- REUSABLE SEARCHABLE BOTTOM SHEET ---
  Future<T?> _showSearchablePicker<T>({
    required String title,
    required List<T> items,
    required String Function(T) itemAsString,
    required Widget Function(T, bool) itemBuilder,
    T? selectedItem,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _SearchableListWidget<T>(
          title: title,
          items: items,
          itemAsString: itemAsString,
          itemBuilder: itemBuilder,
          selectedItem: selectedItem,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Transaction' : 'Add Transaction')),
      body: Consumer<BusinessProvider>(builder: (context, prov, _) {
        if (prov.selectedBusiness == null) return const Center(child: Text('Select a business first'));
        
        // Show loading indicator while loading transaction data
        if (_isLoadingData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final filteredParties = _getFilteredParties(prov.parties);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('New Transaction', style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Business: ${prov.selectedBusiness!.business_name}', style: t.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 12),
            Row(children: ['SALE','EXPENSE','PURCHASE'].map((tx) {
              Color c = tx=='SALE'?Colors.green:tx=='EXPENSE'?Colors.red:Colors.blue;
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ChoiceChip(
                  label: Text(tx, style: TextStyle(fontSize: 11, color: _txnType==tx?Colors.white:null)),
                  selected: _txnType==tx, 
                  onSelected: (_) {
                    if (_txnType != tx) {
                      _resetForm();
                      setState(() => _txnType = tx);
                    }
                  }, 
                  selectedColor: c,
                ),
              ));
            }).toList()),
            const SizedBox(height: 10),
            if (_txnType == 'EXPENSE') ...[
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Enter title' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Amount (Rs)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Enter amount';
                  final amount = double.tryParse(v!);
                  if (amount == null) return 'Invalid amount';
                  if (amount <= 0) return 'Amount must be greater than zero';
                  return null;
                },
              ),
              const SizedBox(height: 10),
            ] else ...[
              _buildPartyDropdown(prov, t, filteredParties),
              const SizedBox(height: 10),
            ],
            Row(children: [
              Expanded(child: _buildDateBtn('Date', _txnDate, (d) => setState(() => _txnDate=d))),
              const SizedBox(width: 8),
              Expanded(child: _buildTimeBtn()),
            ]),
            if (_txnType != 'EXPENSE') ...[
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Items', style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                TextButton.icon(onPressed: _addItem, icon: const Icon(Icons.add, size: 16), label: const Text('Add')),
              ]),
              ..._items.asMap().entries.map((e) => _buildItemCard(e.key, prov, t)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 5, 4, 4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(children: [
                  _sumRow('Subtotal', _subtotal),
                  const SizedBox(height: 4),
                  ..._items.map((item) => _sumRow('  GST (${item.gstRate}%)', item.gstAmount)),
                  const SizedBox(height: 4),
                  _sumRow('Total GST', _totalGst),
                  const Divider(height: 16),
                  _sumRow('Total Amount', _totalAmt, true),
                ]),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: prov.isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: prov.isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEditMode ? 'Update $_txnType' : 'Create $_txnType'),
            ),
          ])),
        );
      }),
    );
  }

  Widget _buildPartyDropdown(
    BusinessProvider prov,
    ThemeData t,
    List<PartyModel> parties,) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Party',
          style: t.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final selected = await _showSearchablePicker<PartyModel>(
              title: _txnType == "SALE" ? "Select Consumer" : "Select Supplier",
              items: parties,
              selectedItem: _selParty,
              itemAsString: (party) => party.name,
              itemBuilder: (item, isSelected) {
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: item.partyType == "CUSTOMER" ? Colors.blue.shade50 : Colors.orange.shade50,
                    child: Icon(
                      item.partyType == "CUSTOMER" ? Icons.person : Icons.business,
                      size: 18,
                      color: item.partyType == "CUSTOMER" ? Colors.blue : Colors.orange,
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  trailing: isSelected ? Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary) : null,
                );
              },
            );

            if (selected != null) {
              setState(() {
                _selParty = selected;
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            isEmpty: _selParty == null,
            child: _selParty == null 
              ? Text(
                  _txnType == "SALE" ? "Select Consumer" : "Select Supplier",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                )
              : Text(
                  _selParty!.name,
                  style: const TextStyle(fontSize: 16),
                ),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final result = await context.push('/add-party');
            if (result == true) {
              await prov.fetchParties();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Create New Party',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(int index, BusinessProvider prov, ThemeData t) {
    final item = _items[index];
    
    // Sync GST rate from state to model
    if (_itemGstRates.containsKey(index)) {
      item.gstRate = _itemGstRates[index]!;
    }
    
    // Debug: Show current state
    debugPrint('ItemCard[$index]: itemId=${item.itemId}, name=${item.description}, price=${item.price}, gst=${item.gstRate}');
    return Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Item ${index+1}', style: t.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
          if (_items.length > 1)
            IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
              onPressed: () => _removeItem(index), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ]),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            // Find current selected item if it exists
            CatalogItemModel? currentItem;
            if (item.itemId != null) {
              try {
                currentItem = prov.catalogItems.firstWhere((e) => e.id == item.itemId);
              } catch (_) {}
            }

            // Debug: Log catalog items before showing picker
            debugPrint('Showing picker with ${prov.catalogItems.length} items');
            for (var i = 0; i < prov.catalogItems.length; i++) {
              final ci = prov.catalogItems[i];
              debugPrint('  Item $i: ${ci.name}, price: ${ci.price}');
            }
            
            final selected = await _showSearchablePicker<CatalogItemModel>(
              title: 'Select Item',
              items: prov.catalogItems,
              selectedItem: currentItem,
              itemAsString: (ci) => ci.name,
              itemBuilder: (ci, isSelected) {
                // Debug: Log each item as it's built
                debugPrint('Building picker item: ${ci.name}, price: ${ci.price}');
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.inventory_2, color: Colors.blue),
                  title: Text(ci.name),
                  subtitle: Text('Rs${ci.price.toStringAsFixed(2)}'),
                  trailing: isSelected ? Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary) : null,
                );
              },
            );

            if (selected != null) {
              setState(() {
                item.itemId = selected.id;
                item.description = selected.name;
                item.price = selected.price;
                // Update the price controller to show the selected price
                if (_priceControllers[index] != null) {
                  _priceControllers[index]!.text = selected.price.toStringAsFixed(2);
                } else {
                  _priceControllers[index] = TextEditingController(text: selected.price.toStringAsFixed(2));
                }
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.inventory_2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            isEmpty: item.itemId == null,
            child: item.itemId == null 
              ? Text(
                  "Select Item",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                )
              : Text(
                  item.description,
                  style: const TextStyle(fontSize: 16),
                ),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final result = await context.push('/add-item');
            if (result == true) {
              await prov.fetchCatalogItems();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Create New Item',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: TextFormField(
            controller: _qtyControllers[index],
            decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder(), isDense: true),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              setState(() {
                item.quantity = int.tryParse(v) ?? 0;
              });
            },
          )),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _priceControllers[index],
              decoration: const InputDecoration(
                labelText: 'Price', 
                prefixText: 'Rs ', 
                border: OutlineInputBorder(), 
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: item.itemId == null,
              onChanged: item.itemId != null ? null : (v) {
                setState(() {
                  item.price = double.tryParse(v) ?? 0;
                });
              },
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const Text('GST: ', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          ..._availableGstRates.map((rate) {
            final isSelected = (_itemGstRates[index] ?? 18.0) == rate;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ChoiceChip(
                label: Text('$rate%', style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _itemGstRates[index] = rate;
                    item.gstRate = rate;
                  });
                },
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontSize: 11,
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            );
          }).toList(),
        ]),
        Align(alignment: Alignment.centerRight,
          child: Text('Total: Rs${item.total.toStringAsFixed(2)}', style: t.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold))),
      ]),
    ));
  }

  Widget _buildDateBtn(String label, DateTime date, Function(DateTime) onPicked, [bool optional = false]) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context, initialDate: date, firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label, border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(DateFormat.yMMMd().format(date)),
      ),
    );
  }

  Widget _buildTimeBtn() {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _txnTime,
        );
        if (picked != null) {
          setState(() => _txnTime = picked);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Time', border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.access_time, size: 18),
        ),
        child: Text(_txnTime.format(context)),
      ),
    );
  }

  Widget _sumRow(String label, double amount, [bool bold = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text('Rs${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ]),
    );
  }
}

// --- SEARCHABLE LIST BOTTOM SHEET WIDGET ---
class _SearchableListWidget<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) itemAsString;
  final Widget Function(T, bool) itemBuilder;
  final T? selectedItem;

  const _SearchableListWidget({
    required this.title,
    required this.items,
    required this.itemAsString,
    required this.itemBuilder,
    this.selectedItem,
  });

  @override
  State<_SearchableListWidget<T>> createState() => _SearchableListWidgetState<T>();
}

class _SearchableListWidgetState<T> extends State<_SearchableListWidget<T>> {
  late List<T> filteredItems;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredItems = widget.items;
      } else {
        filteredItems = widget.items.where((item) {
          return widget.itemAsString(item).toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ensures the bottom sheet avoids the keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filter,
            ),
          ),
          const SizedBox(height: 8),
          
          // List
          Expanded(
            child: filteredItems.isEmpty
              ? const Center(child: Text("No items found", style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  itemCount: filteredItems.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    // Compare using the string representation for simplicity, or identity if T supports it.
                    final isSelected = widget.selectedItem != null && item == widget.selectedItem; 
                    
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).pop(item);
                      },
                      child: widget.itemBuilder(item, isSelected),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}