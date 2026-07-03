import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/services/api_service.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _mobileFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  String? _errorMessage;
  bool _isSubmitting = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _mobileFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'This field is required';
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'At least 8 characters required';
    }
    if (value.length > 64) {
      return 'Must be at most 64 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Must contain an uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Must contain a lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Must contain a number';
    }
    if (!RegExp(r'''[!@#$%^&*(),.?"':{}|<>~`_\-+=\[\]\\;/]''').hasMatch(value)) {
      return 'Must contain a special character';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  PasswordStrength get _passwordStrength {
    final p = _passwordController.text;
    if (p.isEmpty) return PasswordStrength.none;
    int score = 0;
    if (p.length >= 8) score++;
    if (p.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'''[!@#$%^&*(),.?"':{}|<>~`_\-+=\[\]\\;/]''').hasMatch(p)) {
      score++;
    }
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  bool get _isFormValid {
    return _validateName(_firstNameController.text) == null &&
        _validateName(_lastNameController.text) == null &&
        _validateEmail(_emailController.text) == null &&
        _validateMobile(_mobileController.text) == null &&
        _validatePassword(_passwordController.text) == null &&
        _validateConfirmPassword(_confirmPasswordController.text) == null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      await apiService.register({
        "firstname": _firstNameController.text.trim(),
        "lastname": _lastNameController.text.trim(),
        "email": _emailController.text.trim().toLowerCase(),
        "mobile": _mobileController.text.trim(),
        "password": _passwordController.text,
        "conform_password": _confirmPasswordController.text,
      });

      if (mounted) {
        context.push('/otp', extra: {
          "email": _emailController.text.trim().toLowerCase(),
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  Widget _buildNameField({
    required TextEditingController controller,
    required String label,
    required FocusNode focusNode,
    required FocusNode nextFocus,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        maxLength: 50,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
        ],
        decoration: _inputDecoration(label).copyWith(
          counterText: '',
        ),
        onFieldSubmitted: (_) => nextFocus.requestFocus(),
        validator: validator,
      ),
    );
  }

  Widget _buildEmailField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _emailController,
        focusNode: _emailFocus,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        decoration: _inputDecoration('Email'),
        onFieldSubmitted: (_) => _mobileFocus.requestFocus(),
        validator: _validateEmail,
      ),
    );
  }

  Widget _buildMobileField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _mobileController,
        focusNode: _mobileFocus,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        maxLength: 10,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        decoration: _inputDecoration('Mobile').copyWith(counterText: ''),
        onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
        validator: _validateMobile,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required FocusNode focusNode,
    required FocusNode? nextFocus,
    required bool isVisible,
    required ValueChanged<bool> onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: !isVisible,
        textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
        decoration: _inputDecoration(label).copyWith(
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: () => onToggleVisibility(!isVisible),
          ),
        ),
        onFieldSubmitted: (_) {
          if (nextFocus != null) {
            nextFocus.requestFocus();
          } else {
            _formKey.currentState?.validate();
            _register();
          }
        },
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final isLoading = apiService.isLoading || _isSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,

              child: Column(
                children: [
                  _buildNameField(
                    controller: _firstNameController,
                    label: 'First Name',
                    focusNode: _firstNameFocus,
                    nextFocus: _lastNameFocus,
                    validator: _validateName,
                  ),
                  _buildNameField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    focusNode: _lastNameFocus,
                    nextFocus: _emailFocus,
                    validator: _validateName,
                  ),
                  _buildEmailField(),
                  _buildMobileField(),
                  _buildPasswordField(
                    controller: _passwordController,
                    label: 'Password',
                    focusNode: _passwordFocus,
                    nextFocus: _confirmPasswordFocus,
                    isVisible: _isPasswordVisible,
                    onToggleVisibility: (v) => setState(() => _isPasswordVisible = v),
                    validator: _validatePassword,
                  ),
                  _buildPasswordStrengthIndicator(),
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    focusNode: _confirmPasswordFocus,
                    nextFocus: null,
                    isVisible: _isConfirmPasswordVisible,
                    onToggleVisibility: (v) =>
                        setState(() => _isConfirmPasswordVisible = v),
                    validator: _validateConfirmPassword,
                  ),
                  const SizedBox(height: 20),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _register,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Register'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final strength = _passwordStrength;
    if (strength == PasswordStrength.none) return const SizedBox.shrink();

    final indicator = _PasswordStrengthIndicator(strength: strength);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          indicator,
          const SizedBox(height: 4),
          Text(
            strength.label,
            style: TextStyle(
              fontSize: 12,
              color: strength.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

enum PasswordStrength { none, weak, medium, strong }

extension on PasswordStrength {
  String get label {
    switch (this) {
      case PasswordStrength.none:
        return '';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  Color get color {
    switch (this) {
      case PasswordStrength.none:
        return Colors.transparent;
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;
  const _PasswordStrengthIndicator({required this.strength});

  @override
  Widget build(BuildContext context) {
    final segments = 3;
    final activeSegments = switch (strength) {
      PasswordStrength.none => 0,
      PasswordStrength.weak => 1,
      PasswordStrength.medium => 2,
      PasswordStrength.strong => 3,
    };

    return Row(
      children: List.generate(segments, (i) {
        final isActive = i < activeSegments;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isActive ? strength.color : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
