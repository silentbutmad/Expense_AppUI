import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/business_models.dart';
import 'package:myapp/providers/business_provider.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

class LineItem {
  String? itemId;
  String description = '';
  int quantity = 1;
  double price = 0.0;
  Map<String, dynamic> toJson() => {
    if (itemId != null) 'item_id': itemId,
    'description': description, 'quantity': quantity, 'price': price,
  };
  double get total => quantity * price;
}

class AddBusinessTransactionScreen extends StatefulWidget {
  const AddBusinessTransactionScreen({super.key});
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
  List<LineItem> _items = [LineItem()];
  final _gstCtrl = TextEditingController(text: '18');
  double _gstPct = 18;
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  @override void dispose() {
    _gstCtrl.dispose(); _titleCtrl.dispose(); _descriptionCtrl.dispose(); _amountCtrl.dispose(); super.dispose();
  }

  double get _subtotal => _txnType == 'EXPENSE' 
      ? double.tryParse(_amountCtrl.text) ?? 0.0
      : _items.fold(0.0, (s, i) => s + i.total);
  double get _totalGst => _subtotal * _gstPct / 100;
  double get _totalAmt => _subtotal + _totalGst;

  // Get filtered parties based on transaction type
  List<PartyModel> _getFilteredParties(List<PartyModel> allParties) {
    if (_txnType == 'SALE') {
      return allParties.where((p) => p.partyType == 'CUSTOMER').toList();
    } else if (_txnType == 'PURCHASE') {
      return allParties.where((p) => p.partyType == 'SUPPLIER').toList();
    }
    return allParties;
  }

  void _addItem() => setState(() => _items.add(LineItem()));
  void _removeItem(int i) { 
    if (_items.length > 1) setState(() => _items.removeAt(i)); 
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final p = Provider.of<BusinessProvider>(context, listen: false);
    final b = p.selectedBusiness;
    if (b == null) return;

    Map<String, dynamic> transactionData = {
      'business_id': b.business_id,
      'transaction_type': _txnType,
      'transaction_date': DateFormat('yyyy-MM-dd').format(_txnDate),
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

    final success = await p.addBusinessTransaction(transactionData);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction created!')));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(p.errorMessage ?? 'Failed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Consumer<BusinessProvider>(builder: (context, prov, _) {
        if (prov.selectedBusiness == null) return const Center(child: Text('Select a business first'));
        
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
                  selected: _txnType==tx, onSelected: (_) => setState(() => _txnType=tx), selectedColor: c,
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
                  if (double.tryParse(v!) == null) return 'Invalid amount';
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
              Row(children: [
                const Text('GST %: '),
                SizedBox(width: 70, child: TextFormField(
                  controller: _gstCtrl,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6)),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() => _gstPct = double.tryParse(v) ?? 0),
                )),
              ]),
              const SizedBox(height: 8),
              _sumRow('Subtotal', _subtotal),
              _sumRow('GST ($_gstPct%)', _totalGst),
              _sumRow('Total', _totalAmt, true),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: prov.isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: prov.isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Create $_txnType'),
            ),
          ])),
        );
      }),
    );
  }

  Widget _buildPartyDropdown(
  BusinessProvider prov,
  ThemeData t,
  List<PartyModel> parties,
) {
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

      DropdownSearch<PartyModel>(
        selectedItem: _selParty,

        items: (filter, infiniteScrollProps) async {
          if (filter.isEmpty) {
            return parties;
          }

          return parties.where((party) {
            return party.name
                .toLowerCase()
                .contains(filter.toLowerCase());
          }).toList();
        },

        compareFn: (a, b) => a.id == b.id,

        itemAsString: (PartyModel party) => party.name,

        popupProps: PopupProps.menu(
          showSearchBox: true,
          fit: FlexFit.loose,
          constraints: const BoxConstraints(
            maxHeight: 320,
          ),
          menuProps: MenuProps(
            borderRadius: BorderRadius.circular(14),
            elevation: 8,
            shadowColor: Colors.black26,
          ),
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search party...",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          itemBuilder: (context, item, isDisabled, isSelected) {
            return Container(
              height: 54,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                ),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: item.partyType == "CUSTOMER"
                      ? Colors.blue.shade50
                      : Colors.orange.shade50,
                  child: Icon(
                    item.partyType == "CUSTOMER"
                        ? Icons.person
                        : Icons.business,
                    size: 18,
                    color: item.partyType == "CUSTOMER"
                        ? Colors.blue
                        : Colors.orange,
                  ),
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary)
                    : null,
              ),
            );
          },
          emptyBuilder: (context, searchEntry) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off, size: 36, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      "No party found",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        decoratorProps: DropDownDecoratorProps(
          decoration: InputDecoration(
            hintText: _txnType == "SALE"
                ? "Select Consumer"
                : "Select Supplier",

            prefixIcon: const Icon(Icons.person),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),

        onChanged: (PartyModel? party) {
          setState(() {
            _selParty = party;
          });
        },
      ),

      const SizedBox(height: 8),

      InkWell(
        onTap: () async {
          final result =
              await Navigator.of(context).pushNamed('/add-party');

          if (result == true) {
            await prov.fetchParties();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
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
        DropdownSearch<CatalogItemModel>(
          selectedItem: item.itemId != null ? CatalogItemModel(
            id: item.itemId!,
            businessId: '',
            name: item.description,
            price: item.price,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ) : null,
          items: (filter, infiniteScrollProps) async {
            if (filter.isEmpty) {
              return prov.catalogItems;
            }
            return prov.catalogItems.where((ci) {
              return ci.name.toLowerCase().contains(filter.toLowerCase());
            }).toList();
          },
          compareFn: (a, b) => a.id == b.id,
          itemAsString: (CatalogItemModel ci) => ci.name,
          popupProps: PopupProps.menu(
            showSearchBox: true,
            fit: FlexFit.loose,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: "Search item...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
            itemBuilder: (context, ci, isDisabled, isSelected) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.inventory_2, color: Colors.blue),
                title: Text(ci.name),
                subtitle: Text('Rs${ci.price.toStringAsFixed(2)}'),
              );
            },
            emptyBuilder: (context, searchEntry) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text("No item found")),
              );
            },
          ),
          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              hintText: 'Select Item',
              prefixIcon: const Icon(Icons.inventory_2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
          onChanged: (value) {
            setState(() {
              if (value != null) {
                item.itemId = value.id;
                item.description = value.name;
                item.price = value.price;
              } else {
                item.itemId = null;
                item.description = '';
                item.price = 0.0;
              }
            });
          },
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final result = await Navigator.of(context).pushNamed('/add-item');
            if (result == true) {
              await prov.fetchCatalogItems();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
            initialValue: item.quantity.toString(),
            decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder(), isDense: true),
            keyboardType: TextInputType.number,
            onChanged: (v) => item.quantity = int.tryParse(v) ?? 0,
          )),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: item.price > 0 ? item.price.toStringAsFixed(2) : '',
              decoration: const InputDecoration(
                labelText: 'Price', 
                prefixText: 'Rs ', 
                border: OutlineInputBorder(), 
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: item.itemId == null,
              onChanged: item.itemId != null ? null : (v) => item.price = double.tryParse(v) ?? 0,
            ),
          ),
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