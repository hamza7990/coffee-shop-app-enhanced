// lib/screens/forgot_password_screen.dart
// ─────────────────────────────────────────────────────────────
// Modern forgot password screen with email input and validation.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).forgotPassword(
        _emailController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;

    // Show success message dialog
    if (authState.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSuccessDialog(context, authState.successMessage!);
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary.withOpacity(0.05),
              cs.surface,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    children: [
                      // Illustration
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_reset,
                          size: 60,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title card
                      Card(
                        elevation: 8,
                        shadowColor: cs.primary.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Forgot Password?',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Enter your email address and we\'ll send you a link to reset your password.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurface.withOpacity(0.7),
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),

                                // Error message
                                if (authState.errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.error.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline, color: AppColors.error, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            authState.errorMessage!,
                                            style: TextStyle(color: AppColors.error, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Email field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _validateEmail,
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
                                    hintText: 'Enter your registered email',
                                    prefixIcon: Icon(Icons.email_outlined, color: cs.primary),
                                    filled: true,
                                    fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: cs.outline.withOpacity(0.3)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: cs.primary, width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: AppColors.error, width: 1),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Submit button
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: authState.isLoading ? null : _handleSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: cs.primary,
                                      foregroundColor: cs.onPrimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: authState.isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'Send Reset Link',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Back to login
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_back, size: 16, color: cs.primary),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Back to Login',
                                        style: TextStyle(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Demo token input for testing
                                const SizedBox(height: 32),
                                Divider(color: cs.outline.withOpacity(0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  'Have a reset token?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurface.withOpacity(0.5),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ResetPasswordScreen(),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.vpn_key_outlined, size: 18, color: cs.primary),
                                  label: Text(
                                    'Enter Reset Token',
                                    style: TextStyle(color: cs.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 50,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Email Sent!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ResetPasswordScreen(
                        email: '',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Enter Reset Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
