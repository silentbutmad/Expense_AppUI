import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/services/api_service.dart';
import 'package:myapp/theme/app_theme.dart';
import 'package:myapp/theme/app_tokens.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSubmitting = false;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  String? _selectedLanguage;

  final List<String> _languages = [
    'English',
    'Hindi',
    'Spanish',
    'French',
    'German',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.getProfile();
      setState(() {
        _userData = data;
        _isLoading = false;
      });
      _populateControllers();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateControllers() {
    if (_userData == null) return;
    _firstNameController.text = _getField('first_name', 'firstName') ?? '';
    _lastNameController.text = _getField('last_name', 'lastName') ?? '';
    _emailController.text = _getField('email') ?? '';
    _mobileController.text =
        _getField('mobile_number', 'mobileNumber', 'mobile') ?? '';
    _selectedLanguage = _getField('language');
  }

  String? _getField(String primaryKey, [String? altKey1, String? altKey2]) {
    return _userData?[primaryKey]?.toString() ??
        _userData?[altKey1]?.toString() ??
        _userData?[altKey2]?.toString();
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    try {
      final date = DateTime.parse(dateValue.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateValue.toString();
    }
  }

  String? _validateName(String? value, String fieldName) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return '$fieldName is required';
    }
    if (trimmed.length < 2) {
      return 'Must be at least 2 characters';
    }
    if (trimmed.length > 50) {
      return 'Must be at most 50 characters';
    }
    if (!RegExp(r'^[a-zA-Z]+(?: [a-zA-Z]+)*$').hasMatch(trimmed)) {
      return 'Only letters and single spaces allowed';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number is required';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
      return 'Enter a valid 10-digit number starting with 6-9';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final updatedData = <String, dynamic>{
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'mobile_number': _mobileController.text.trim(),
        'language': _selectedLanguage,
      };

      await apiService.updateProfile(updatedData);

      final freshData = await apiService.getProfile();
      if (mounted) {
        setState(() {
          _userData = freshData;
          _isEditing = false;
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isLoading && _userData != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                  if (!_isEditing) _populateControllers();
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : apiService.isAuthenticated && _userData != null
              ? _isEditing
                  ? _buildEditForm()
                  : _buildProfileView()
              : const Center(
                  child: Text('No user data available. Please login.'),
                ),
    );
  }

  Widget _buildProfileView() {
    final firstName =
        _getField('first_name', 'firstName') ?? _getField('name');
    final lastName = _getField('last_name', 'lastName');
    final fullName = firstName != null && lastName != null
        ? '$firstName $lastName'
        : firstName ?? 'N/A';
    final email = _getField('email') ?? 'N/A';
    final mobile =
        _getField('mobile_number', 'mobileNumber', 'mobile') ?? 'N/A';
    final language = _getField('language') ?? 'N/A';
    final isVerified = _userData!['isverified'] == true ||
        _userData!['isVerified'] == true;
    final lastLogin =
        _formatDate(_userData!['last_login'] ?? _userData!['lastLogin']);
    final memberSince = _formatDate(_userData!['created_at'] ??
        _userData!['createdAt'] ??
        _userData!['create_at']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.padding),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
            child: Text(
              (firstName?.isNotEmpty == true ? firstName![0] : '?')
                  .toUpperCase(),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          if (isVerified)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'Verified Account',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.padding),
              child: Column(
                children: [
                  _ProfileRow(
                    icon: Icons.person,
                    label: 'Name',
                    value: fullName,
                  ),
                  const Divider(height: 24),
                  _ProfileRow(
                    icon: Icons.email,
                    label: 'Email',
                    value: email,
                  ),
                  const Divider(height: 24),
                  _ProfileRow(
                    icon: Icons.phone,
                    label: 'Mobile',
                    value: mobile,
                  ),
                  const Divider(height: 24),
                  _ProfileRow(
                    icon: Icons.language,
                    label: 'Language',
                    value: language,
                  ),
                  const Divider(height: 24),
                  _ProfileRow(
                    icon: Icons.login,
                    label: 'Last Login',
                    value: lastLogin,
                  ),
                  const Divider(height: 24),
                  _ProfileRow(
                    icon: Icons.calendar_today,
                    label: 'Member Since',
                    value: memberSince,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _populateControllers();
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.padding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Profile',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                LengthLimitingTextInputFormatter(50),
              ],
              validator: (v) => _validateName(v, 'First name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                LengthLimitingTextInputFormatter(50),
              ],
              validator: (v) => _validateName(v, 'Last name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mobileController,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: _validateMobile,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language),
              ),
              items: _languages
                  .map((lang) => DropdownMenuItem(
                        value: lang,
                        child: Text(lang),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value;
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _saveProfile,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
