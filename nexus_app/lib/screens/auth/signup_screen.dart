// lib/screens/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nexus_logo.dart';
import '../../widgets/nexus_text_field.dart';
import '../../widgets/nexus_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showSnack('Please agree to the Terms of Service', AppTheme.danger);
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      username: _usernameController.text.trim().toLowerCase(),
      displayName: _displayNameController.text.trim(),
    );
    if (!success && mounted) {
      _showSnack(auth.errorMessage ?? 'Sign up failed', AppTheme.danger);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/auth/login'),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // Real NEXUS logo
                  const Center(child: NexusLogo(size: 40)),
                  const SizedBox(height: 24),

                  Text('Create account',
                      style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Join Nexus and connect with the world.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          isDark ? AppTheme.grey500 : AppTheme.grey400,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Display Name
                  NexusTextField(
                    controller: _displayNameController,
                    label: 'Full Name',
                    hint: 'John Doe',
                    prefixIcon: Icons.badge_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Name is required';
                      if (v.trim().length < 2) return 'Name too short';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Username
                  NexusTextField(
                    controller: _usernameController,
                    label: 'Username',
                    hint: 'johndoe',
                    prefixIcon: Icons.alternate_email_rounded,
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Username is required';
                      if (v.length < 3) return 'Minimum 3 characters';
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                        return 'Only letters, numbers and underscores';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Email
                  NexusTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline_rounded,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!v.contains('@') || !v.contains('.'))
                        return 'Invalid email';
                      return null;
                    },
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
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: isDark
                            ? AppTheme.grey500
                            : AppTheme.grey400,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Password is required';
                      if (v.length < 8) return 'Minimum 8 characters';
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Terms checkbox
                  GestureDetector(
                    onTap: () =>
                        setState(() => _agreedToTerms = !_agreedToTerms),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _agreedToTerms
                                ? (isDark
                                    ? AppTheme.white
                                    : AppTheme.black)
                                : Colors.transparent,
                            border: Border.all(
                              color: _agreedToTerms
                                  ? (isDark
                                      ? AppTheme.white
                                      : AppTheme.black)
                                  : AppTheme.grey300,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: _agreedToTerms
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: isDark
                                      ? AppTheme.black
                                      : AppTheme.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppTheme.grey400
                                    : AppTheme.grey500,
                              ),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppTheme.white
                                        : AppTheme.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppTheme.white
                                        : AppTheme.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  NexusButton(
                    onPressed: _signUp,
                    label: 'Create Account',
                    isLoading: isLoading,
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account?',
                          style: theme.textTheme.bodyMedium),
                      TextButton(
                        onPressed: () => context.go('/auth/login'),
                        child: Text(
                          'Sign in',
                          style: TextStyle(
                            color: isDark ? AppTheme.white : AppTheme.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
