import 'package:flutter/material.dart';
import 'package:myapp/providers/business_provider.dart';
import 'package:provider/provider.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});
  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController();
  final _hsnCodeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _hsnCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = Provider.of<BusinessProvider>(context, listen: false);
    final business = provider.selectedBusiness;
    if (business == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No business selected')));
      return;
    }
    final data = {
      'name': _nameController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      'business_id': business.business_id,
      if (_descriptionController.text.trim().isNotEmpty) 'description': _descriptionController.text.trim(),
      if (_unitController.text.trim().isNotEmpty) 'unit': _unitController.text.trim(),
      if (_hsnCodeController.text.trim().isNotEmpty) 'hsn_code': _hsnCodeController.text.trim(),
    };
    final success = await provider.createCatalogItem(data);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item added!')));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: Consumer<BusinessProvider>(
        builder: (context, provider, child) {
          final business = provider.selectedBusiness;
          if (business == null) return const Center(child: Text('Select a business first'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Add Catalog Item', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Business: ${business.business_name}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 20),
                  _buildTextField(_nameController, 'Item Name *', Icons.shopping_bag, validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 16),
                  _buildTextField(_descriptionController, 'Description', Icons.description, maxLines: 2),
                  const SizedBox(height: 16),
                  _buildTextField(_priceController, 'Price *', Icons.currency_rupee, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    return double.tryParse(v.trim()) == null ? 'Invalid price' : null;
                  }),
                  const SizedBox(height: 16),
                  _buildTextField(_unitController, 'Unit (pcs, kg, box)', Icons.scale),
                  const SizedBox(height: 16),
                  _buildTextField(_hsnCodeController, 'HSN Code', Icons.numbers),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: provider.isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: provider.isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Add Item'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType, String? Function(String?)? validator, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
    );
  }
}
