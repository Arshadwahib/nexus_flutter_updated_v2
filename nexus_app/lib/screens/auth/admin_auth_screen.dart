// lib/screens/auth/admin_auth_screen.dart
// ⚠️ CONFIDENTIAL — Admin authentication screen
// Access via: tap the bottom of login screen 5 times
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nexus_logo.dart';
import '../../widgets/nexus_text_field.dart';
import '../../widgets/nexus_button.dart';

enum _AdminMode { login, signup }

class AdminAuthScreen extends StatefulWidget {
  const AdminAuthScreen({super.key});

  @override
  State<AdminAuthScreen> createState() => _AdminAuthScreenState();
}

class _AdminAuthScreenState extends State<AdminAuthScreen> {
  _AdminMode _mode = _AdminMode.login;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminUsernameController = TextEditingController();
  final _adminSecretController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureSecret = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _adminUsernameController.dispose();
    _adminSecretController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    bool success;

    if (_mode == _AdminMode.login) {
      success = await auth.adminSignIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        adminUsername: _adminUsernameController.text.trim(),
        adminSecret: _adminSecretController.text,
      );
    } else {
      success = await auth.adminSignUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        adminUsername: _adminUsernameController.text.trim(),
        adminSecret: _adminSecretController.text,
      );
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Authentication failed'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/auth/login'),
        ),
        title: const Text(''),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // NEXUS logo
                const Center(child: NexusLogo(size: 36)),
                const SizedBox(height: 20),
                // Admin badge header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.grey900 : AppTheme.grey100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.adminBlue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.adminBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shield_rounded, color: AppTheme.adminBlue, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Access',
                            style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.adminBlue),
                          ),
                          Text(
                            'Restricted area',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Toggle login/signup
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _mode = _AdminMode.login),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _mode == _AdminMode.login
                                ? (isDark ? AppTheme.white : AppTheme.black)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Admin Login',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: _mode == _AdminMode.login
                                  ? (isDark ? AppTheme.black : AppTheme.white)
                                  : (isDark ? AppTheme.grey500 : AppTheme.grey400),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _mode = _AdminMode.signup),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _mode == _AdminMode.signup
                                ? (isDark ? AppTheme.white : AppTheme.black)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Admin Sign Up',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: _mode == _AdminMode.signup
                                  ? (isDark ? AppTheme.black : AppTheme.white)
                                  : (isDark ? AppTheme.grey500 : AppTheme.grey400),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Email
                NexusTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'admin@nexus.app',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                // Password
                NexusTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: '••••••••',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 14),

                // Admin username
                NexusTextField(
                  controller: _adminUsernameController,
                  label: 'Admin Username',
                  hint: 'Your admin username',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                // Admin secret
                NexusTextField(
                  controller: _adminSecretController,
                  label: 'Admin Secret Key',
                  hint: '••••••••••••',
                  obscureText: _obscureSecret,
                  prefixIcon: Icons.key_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureSecret ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
                  ),
                  validator: (v) => v?.isEmpty == true ? 'Secret key is required' : null,
                ),

                const SizedBox(height: 32),

                NexusButton(
                  onPressed: _submit,
                  label: _mode == _AdminMode.login ? 'Sign In as Admin' : 'Create Admin Account',
                  isLoading: isLoading,
                  color: AppTheme.adminBlue,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
