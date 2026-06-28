import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _addressController.dispose();
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
      'party_type': _partyType,
      'business_id': business.business_id,
      if (_phoneController.text.trim().isNotEmpty) 'phone': _phoneController.text.trim(),
      if (_emailController.text.trim().isNotEmpty) 'email': _emailController.text.trim(),
      if (_gstinController.text.trim().isNotEmpty) 'gstin': _gstinController.text.trim(),
      if (_addressController.text.trim().isNotEmpty) 'address': _addressController.text.trim(),
    };
    final success = await provider.createParty(data);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Party added!')));
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
      appBar: AppBar(title: const Text('Add Party')),
      body: Consumer<BusinessProvider>(
        builder: (context, provider, child) {
          final business = provider.selectedBusiness;
          if (business == null) return const Center(child: Text('Select a business first'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Add Party', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Business: ${business.business_name}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: ChoiceChip(label: const Text('Customer'), selected: _partyType == 'CUSTOMER', onSelected: (_) => setState(() => _partyType = 'CUSTOMER'))),
                  const SizedBox(width: 12),
                  Expanded(child: ChoiceChip(label: const Text('Supplier'), selected: _partyType == 'SUPPLIER', onSelected: (_) => setState(() => _partyType = 'SUPPLIER'))),
                ]),
                const SizedBox(height: 20),
                _buildField(_nameController, 'Party Name *', Icons.person, (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                const SizedBox(height: 16),
                _buildField(_phoneController, 'Phone', Icons.phone, null, TextInputType.phone),
                const SizedBox(height: 16),
                _buildField(_emailController, 'Email', Icons.email, null, TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildField(_gstinController, 'GSTIN', Icons.numbers),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on), border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: provider.isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: provider.isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Add Party'),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(TextEditingController c, String label, IconData icon, [String? Function(String?)? validator, TextInputType? keyboardType]) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
      validator: validator,
      keyboardType: keyboardType,
    );
  }
}
