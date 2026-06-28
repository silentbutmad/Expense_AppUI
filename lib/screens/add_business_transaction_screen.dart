import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/business_models.dart';
import 'package:myapp/providers/business_provider.dart';
import 'package:provider/provider.dart';

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
  List<CatalogItemModel> _filteredItems = [];
  List<PartyModel> _filteredParties = [];
  final _partySearchCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _showPartyDropdown = false;

  @override void dispose() {
    _gstCtrl.dispose(); _partySearchCtrl.dispose(); _titleCtrl.dispose(); _descriptionCtrl.dispose(); super.dispose();
  }

  double get _subtotal => _items.fold(0.0, (s, i) => s + i.total);
  double get _totalGst => _subtotal * _gstPct / 100;
  double get _totalAmt => _subtotal + _totalGst;

  void _addItem() => setState(() => _items.add(LineItem()));
  void _removeItem(int i) { if (_items.length > 1) setState(() => _items.removeAt(i)); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].quantity <= 0 || _items[i].price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item ${i+1}: invalid qty/price')));
        return;
      }
    }
    final p = Provider.of<BusinessProvider>(context, listen: false);
    final b = p.selectedBusiness;
    if (b == null) return;
    final success = await p.addBusinessTransaction({
      'business_id': b.business_id,
      if (_selParty != null) 'party_id': _selParty!.id,
      'transaction_type': _txnType,
      'transaction_date': DateFormat('yyyy-MM-dd').format(_txnDate),
      if (_dueDate != null) 'due_date': DateFormat('yyyy-MM-dd').format(_dueDate!),
      'title': _titleCtrl.text.isEmpty ? null : _titleCtrl.text,
      'description': _descriptionCtrl.text.isEmpty ? null : _descriptionCtrl.text,
      'items': _items.map((e) => e.toJson()).toList(),
      'subtotal_amount': _subtotal,
      'total_gst_amount': _totalGst,
      'total_amount': _totalAmt,
    });
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
            ] else
              _buildPartySelector(prov, t),
            if (_txnType != 'EXPENSE') const SizedBox(height: 10),
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
            ],
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

  Widget _buildPartySelector(BusinessProvider prov, ThemeData t) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Party', style: t.textTheme.labelMedium),
      const SizedBox(height: 4),
      TextField(
        controller: _partySearchCtrl,
        decoration: InputDecoration(
          hintText: 'Search party...',
          prefixIcon: const Icon(Icons.search, size: 20),
          border: const OutlineInputBorder(),
          suffixIcon: _selParty != null
              ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () {
                  setState(() { _selParty = null; _partySearchCtrl.clear(); });
                })
              : null,
        ),
        onChanged: (v) {
          setState(() {
            _showPartyDropdown = v.isNotEmpty;
            _filteredParties = prov.parties.where((p) => p.name.toLowerCase().contains(v.toLowerCase())).toList();
          });
        },
      ),
      if (_selParty != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Chip(
            label: Text('${_selParty!.name} (${_selParty!.partyType})'),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => setState(() { _selParty = null; _partySearchCtrl.clear(); }),
          ),
        ),
      if (_showPartyDropdown && _filteredParties.isNotEmpty && _selParty == null)
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          constraints: const BoxConstraints(maxHeight: 150),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _filteredParties.length,
            itemBuilder: (ctx, i) => ListTile(
              dense: true,
              title: Text(_filteredParties[i].name),
              subtitle: Text(_filteredParties[i].partyType),
              onTap: () {
                setState(() {
                  _selParty = _filteredParties[i];
                  _showPartyDropdown = false;
                  _partySearchCtrl.text = _filteredParties[i].name;
                });
              },
            ),
          ),
        ),
      if (prov.parties.isEmpty)
        TextButton.icon(
          onPressed: () => Navigator.of(context).pushNamed('/add-party'),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Create New Party'),
        ),
    ]);
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
        TextField(
          decoration: InputDecoration(
            hintText: 'Item name / Search catalog',
            prefixIcon: const Icon(Icons.search, size: 20),
            border: const OutlineInputBorder(), isDense: true,
          ),
          onChanged: (v) {
            setState(() {
              _filteredItems = prov.catalogItems.where((ci) => ci.name.toLowerCase().contains(v.toLowerCase())).toList();
              item.description = v; item.itemId = null;
            });
          },
        ),
        if (_filteredItems.isNotEmpty && item.itemId == null)
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            constraints: const BoxConstraints(maxHeight: 120),
            child: ListView.builder(shrinkWrap: true, itemCount: _filteredItems.length,
              itemBuilder: (ctx, i) {
                final ci = _filteredItems[i];
                return ListTile(dense: true, title: Text(ci.name),
                  subtitle: Text('Rs${ci.price.toStringAsFixed(2)}'),
                  onTap: () { setState(() { item.itemId = ci.id; item.description = ci.name; item.price = ci.price; _filteredItems = []; }); },
                );
              },
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
          Expanded(child: TextFormField(
            initialValue: item.price > 0 ? item.price.toStringAsFixed(2) : '',
            decoration: const InputDecoration(labelText: 'Price', prefixText: 'Rs ', border: OutlineInputBorder(), isDense: true),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => item.price = double.tryParse(v) ?? 0,
          )),
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