import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider.dart';

import '../../../../core/providers/items_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor; // Should be the maroon color approx 0xFF781C2E
    // Hardcoding the maroon from the image if theme differs, but theme likely matches.
    // Based on previous code: Theme.of(context).colorScheme.primary is used.
    final maroonColor = const Color(0xFF781C2E);

    return Scaffold(
      backgroundColor: maroonColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 8,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: maroonColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: maroonColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined, // Or look for specific shield/user icon if admin key, but sticking to shopping bag for Rental App
                              size: 40,
                              color: Colors.white,
                            ),
                          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                          
                          const SizedBox(height: 24),
                          
                          // Title
                          Text(
                            'Rental App',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: const Color(0xFF1E1E2C), // Dark text like "Admin Portal"
                              fontWeight: FontWeight.bold,
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                          
                          const SizedBox(height: 8),
                          
                          // Subtitle
                          Text(
                            _isLogin 
                              ? 'Welcome back! Please sign in to continue.'
                              : 'Create an account to get started.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                          
                          const SizedBox(height: 32),

                          // Name Field (Sign Up only)
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: 'Full Name',
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5), // Light grey fill
                                prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              validator: (value) {
                                if (!_isLogin && (value == null || value.isEmpty)) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ).animate().fadeIn().slideY(begin: 0.2),
                            const SizedBox(height: 16),
                          ],

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                              prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your email';
                              if (!value.contains('@')) return 'Please enter a valid email';
                              return null;
                            },
                          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                          
                          const SizedBox(height: 16),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(color: Colors.black87),
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your password';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),

                          // Forgot Password
                          if (_isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _handleForgotPassword,
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: maroonColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 24),

                          // Sign In / Up Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: maroonColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isLogin ? 'Sign In' : 'Sign Up',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ).animate().fadeIn(delay: 600.ms),

                          const SizedBox(height: 16),

                          // Google Sign In (Optional in this view but good to keep)
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _handleGoogleSignIn,
                              icon: const Icon(Icons.g_mobiledata, size: 28), // Or custom G logo
                              label: const Text('Continue with Google'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 700.ms),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Toggle Login/Signup (Outside card, white text on maroon bg)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign Up"
                        : 'Already have an account? Sign In',
                    style: const TextStyle(
                      color: Colors.white, // White text on maroon specific background
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address to reset password'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(_emailController.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      if (_isLogin) {
        // Sign In
        await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        // Sign Up
        final credential = await authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );

        // Create user profile in Firestore
        if (credential?.user != null) {
          await firestoreService.createUserProfile(
            credential!.user!,
            name: _nameController.text.trim(),
          );
        }
      }

      if (!mounted) return;

      // Navigate back on success
      // In the new flow, AuthGate handles navigation, so we just pop if pushed or let stream update handle it
      // But for now, let's keep it safe. If we are in AuthGate, state change will rebuild MainNavigator.
      // If we pushed AuthScreen, we need to pop.
      // However, we are changing Main to be AuthGate based.
      // So we might not need to pop manually if we are at root.
      // Let's assume we might be using it as a standalone screen or replaced.
      // We'll leave the pop if it can pop, but AuthGate is better.
      // For now, let's just show success.

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isLogin ? '✅ Signed in successfully!' : '✅ Account created!',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final message = e.toString();

      // Auto-switch to Sign In if account exists
      if (message.contains('An account already exists')) {
        setState(() => _isLogin = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account already exists. Switched to Sign In mode.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      print('Starting Google Sign In...');
      final credential = await authService.signInWithGoogle();

      // If credential is null (cancelled), we just return
      if (credential == null) {
        print('Google Sign In cancelled by user');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      print('Google Sign In successful: ${credential.user?.uid}');

      if (credential.user != null) {
        print('Creating/updating user profile...');

        // Create/update user profile
        await firestoreService.createUserProfile(credential.user!);

        // Verify user was actually saved
        final userExists = await firestoreService.userExistsInFirestore(
          credential.user!.uid,
        );
        print('User exists in Firestore after creation: $userExists');

        print('User profile created successfully');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userExists
                  ? '✅ Signed in with Google!'
                  : '⚠️ Signed in but profile may not be saved',
            ),
            backgroundColor: userExists ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error in Google Sign In: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign in: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
