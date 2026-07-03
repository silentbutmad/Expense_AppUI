import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _hsnCodeController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'Item name is required';
    }
    if (trimmed.length < 2) {
      return 'Must be at least 2 characters';
    }
    if (trimmed.length > 200) {
      return 'Must be at most 200 characters';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'Price is required';
    }
    final price = double.tryParse(trimmed);
    if (price == null) {
      return 'Enter a valid price';
    }
    if (price < 0) {
      return 'Price cannot be negative';
    }
    if (price > 999999999) {
      return 'Price is too high';
    }
    return null;
  }

  String? _validateHsnCode(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(r'^\d{4,8}$').hasMatch(value.trim())) {
      return 'Enter a valid HSN code (4-8 digits)';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final provider = Provider.of<BusinessProvider>(context, listen: false);
    final business = provider.selectedBusiness;
    if (business == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No business selected')));
      setState(() => _isSubmitting = false);
      return;
    }

    final data = {
      'name': _nameController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'business_id': business.business_id,
      if (_descriptionController.text.trim().isNotEmpty)
        'description': _descriptionController.text.trim(),
      if (_unitController.text.trim().isNotEmpty)
        'unit': _unitController.text.trim(),
      if (_hsnCodeController.text.trim().isNotEmpty)
        'hsn_code': _hsnCodeController.text.trim(),
    };

    final success = await provider.createCatalogItem(data);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Item added!')));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to add item')));
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
          if (business == null) {
            return const Center(child: Text('Select a business first'));
          }
          final isLoading = provider.isSubmitting || _isSubmitting;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Add Catalog Item',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Business: ${business.business_name}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 20),
                  _buildTextField(
                    _nameController,
                    'Item Name *',
                    Icons.shopping_bag,
                    validator: _validateName,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(200),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _descriptionController,
                    'Description',
                    Icons.description,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(500),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _priceController,
                    'Price *',
                    Icons.currency_rupee,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: _validatePrice,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _unitController,
                    'Unit (pcs, kg, box)',
                    Icons.scale,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(50),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _hsnCodeController,
                    'HSN Code',
                    Icons.numbers,
                    keyboardType: TextInputType.number,
                    validator: _validateHsnCode,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.words,
    List<TextInputFormatter>? inputFormatters,
  }) {
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
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
    );
  }
}
