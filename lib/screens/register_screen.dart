import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  final _conformPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  bool _isPasswordVisible = false;
  bool _isConformPasswordVisible = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    
    _passwordController.dispose();
    _conformPasswordController.dispose();
    super.dispose();
  }


  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final response = await http.post(
          Uri.parse('https://expense-api-gateway.onrender.com/auth/start-register'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "firstname": _firstNameController.text,
            "lastname": _lastNameController.text,
            "email": _emailController.text,
            "mobile": _mobileController.text,
            "password": _passwordController.text,
            "conform_password": _conformPasswordController.text,
          }),
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          // ✅ Navigate to OTP screen
          if (mounted) {
            context.push('/otp', extra: {
              "email": _emailController.text
            });
          }
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Registration failed';
          });
        }

      } catch (e) {
        setState(() {
          _errorMessage = 'Server error: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    bool isVisible,
    VoidCallback toggleVisibility, [
    String? Function(String?)? validator,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: toggleVisibility,
          ),
        ),
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return 'Enter your $label';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildTextField(controller: _firstNameController, label: 'First Name'),
                  _buildTextField(controller: _lastNameController, label: 'Last Name'),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _buildTextField(
                    controller: _mobileController,
                    label: 'Mobile',
                    keyboardType: TextInputType.phone,
                  ),

                  _buildPasswordField(
                    _passwordController,
                    'Password',
                    _isPasswordVisible,
                    () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),

                  _buildPasswordField(
                    _conformPasswordController,
                    'Conform Password',
                    _isConformPasswordVisible,
                    () => setState(() => _isConformPasswordVisible = !_isConformPasswordVisible),
                    (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  if (_errorMessage != null)
                    Text(_errorMessage!, style: TextStyle(color: Colors.red)),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: const Text('Register'),
                  ),

                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Already have account? Login'),
                  )
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}