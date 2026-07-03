import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/providers/business_provider.dart';
import 'package:provider/provider.dart';

class AddPartyScreen extends StatefulWidget {
  const AddPartyScreen({super.key});
  @override
  State<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends State<AddPartyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstinController = TextEditingController();
  final _addressController = TextEditingController();
  String _partyType = 'CUSTOMER';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'Party name is required';
    }
    if (trimmed.length < 2) {
      return 'Must be at least 2 characters';
    }
    if (trimmed.length > 100) {
      return 'Must be at most 100 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9\s\-\.\&\(\)\,]+$').hasMatch(trimmed)) {
      return 'Only letters, numbers, spaces, and basic punctuation allowed';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      return 'Must be exactly 10 digits';
    }
    if (!RegExp(r'^[6-9]').hasMatch(digits)) {
      return 'Must start with 6, 7, 8, or 9';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateGstin(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.trim().toUpperCase();
    if (!RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}\d[Z]{1}[A-Z\d]{1}$')
        .hasMatch(cleaned)) {
      return 'Enter a valid 15-character GSTIN';
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
      'party_type': _partyType,
      'business_id': business.business_id,
      if (_phoneController.text.trim().isNotEmpty)
        'phone': _phoneController.text.trim(),
      if (_emailController.text.trim().isNotEmpty)
        'email': _emailController.text.trim().toLowerCase(),
      if (_gstinController.text.trim().isNotEmpty)
        'gstin': _gstinController.text.trim().toUpperCase(),
      if (_addressController.text.trim().isNotEmpty)
        'address': _addressController.text.trim(),
    };

    final success = await provider.createParty(data);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Party added!')));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to add party')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Party')),
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
                    Text('Add Party',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Business: ${business.business_name}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Customer'),
                          selected: _partyType == 'CUSTOMER',
                          onSelected: (_) =>
                              setState(() => _partyType = 'CUSTOMER'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Supplier'),
                          selected: _partyType == 'SUPPLIER',
                          onSelected: (_) =>
                              setState(() => _partyType = 'SUPPLIER'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _buildField(
                      _nameController,
                      'Party Name *',
                      Icons.person,
                      validator: _validateName,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(100),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      _phoneController,
                      'Phone',
                      Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      _emailController,
                      'Email',
                      Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      _gstinController,
                      'GSTIN',
                      Icons.numbers,
                      validator: _validateGstin,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(15),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(500),
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
                          : const Text('Add Party'),
                    ),
                  ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(
    TextEditingController c,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.words,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
    );
  }
}
