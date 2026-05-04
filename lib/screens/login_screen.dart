import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_sizes.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController(text: 'admin@brewhaus.com');
  final _passwordCtrl = TextEditingController(text: 'password');
  bool _obscure = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 4) {
      return 'Password must be at least 4 characters';
    }
    return null;
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authProvider.notifier).login(
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark    = ref.watch(themeProvider);
    final cs        = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background blobs ─────────────────────────────
          Positioned(
            top: -120, right: -80,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -80, left: -40,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDark.withValues(alpha: isDark ? 0.05 : 0.08),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 8)
                              )
                            ],
                          ),
                          child: const Icon(Icons.coffee, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 20),
                        Text('Brewhaus',
                            style: AppTextStyles.displayStyle(ctx: context, size: 36, color: cs.onSurface)),
                        const SizedBox(height: 6),
                        Text('Coffee Shop POS System',
                            style: AppTextStyles.muted(context, size: 15)),
                        const SizedBox(height: 48),

                        // Card
                        Container(
                          padding: const EdgeInsets.all(AppSizes.p32),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: cs.outline),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05), blurRadius: 24)
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Welcome back',
                                    style: AppTextStyles.title(context, size: 24)),
                                const SizedBox(height: AppSizes.p8),
                                Text('Sign in to your dashboard',
                                    style: AppTextStyles.muted(context, size: 14)),
                                const SizedBox(height: AppSizes.p32),

                                // Email
                                Text('Email', style: AppTextStyles.title(context, size: 14)),
                                const SizedBox(height: AppSizes.p8),
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _validateEmail,
                                  decoration: InputDecoration(
                                    hintText: 'you@example.com',
                                    prefixIcon: Icon(Icons.email_outlined, color: cs.primary),
                                  ),
                                ),
                                const SizedBox(height: AppSizes.p20),

                                // Password
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Password', style: AppTextStyles.title(context, size: 14)),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: cs.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSizes.p8),
                                TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscure,
                                  validator: _validatePassword,
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    prefixIcon: Icon(Icons.lock_outline, color: cs.primary),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                                      onPressed: () => setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  onFieldSubmitted: (_) => _login(),
                                ),

                                if (authState.errorMessage != null) ...[
                                   const SizedBox(height: AppSizes.p16),
                                   Container(
                                     padding: const EdgeInsets.all(AppSizes.p12),
                                     decoration: BoxDecoration(
                                       color: AppColors.error.withValues(alpha: 0.1),
                                       borderRadius: BorderRadius.circular(12),
                                     ),
                                     child: Text(authState.errorMessage!,
                                         style: const TextStyle(color: AppColors.error, fontSize: 13)),
                                   ),
                                ],

                                const SizedBox(height: AppSizes.p32),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: authState.isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: authState.isLoading
                                        ? const SizedBox(
                                            width: 24, height: 24,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                        : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(height: AppSizes.p20),
                                Center(
                                  child: Text('Demo: admin@brewhaus.com / password',
                                      style: AppTextStyles.muted(context, size: 12)),
                                ),

                                const SizedBox(height: AppSizes.p24),
                                // Register link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: AppTextStyles.muted(context, size: 14),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Dark mode toggle
                        const SizedBox(height: 32),
                        OutlinedButton.icon(
                          onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 18),
                          label: Text(isDark ? 'Light Mode' : 'Dark Mode', style: AppTextStyles.body(context)),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            side: BorderSide(color: cs.outline),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
