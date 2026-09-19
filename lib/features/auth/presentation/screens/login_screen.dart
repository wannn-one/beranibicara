import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/core/constants/app_colors.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/shared/widgets/auth_logo.dart';
import 'package:beranibicara/shared/widgets/custom_button.dart';
import 'package:beranibicara/shared/widgets/custom_text_field.dart';
import 'package:beranibicara/shared/widgets/dialogs.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordObscured = true;
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showAppMessageDialog(
        context,
        'Peringatan',
        'Email dan Password harus diisi',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authNotifier = Provider.of<AuthNotifier>(context, listen: false);

      final success = await authNotifier.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (success && mounted) {
        context.go(AppConstants.routeDashboard);
      } else if (!success && mounted) {
        showErrorDialog(
          context,
          authNotifier.errorMessage ?? 'Login Gagal',
        );
      }
    } catch (error) {
      if (mounted) {
        showErrorDialog(context, 'Terjadi error yang tidak terduga: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final authNotifier = Provider.of<AuthNotifier>(context, listen: false);

      final success = await authNotifier.signInWithGoogle();

      if (success && mounted) {
        context.go(AppConstants.routeDashboard);
      } else if (!success && mounted) {
        showErrorDialog(
          context,
          authNotifier.errorMessage ?? 'Error login dengan Google',
        );
      }
    } catch (error) {
      if (mounted) {
        showErrorDialog(context, 'Error login dengan Google: $error');
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Log In'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: AuthLogo(),
            ),
            const Text(
              'Email',
              style: TextStyle(color: AppColors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const Text(
              'Password',
              style: TextStyle(color: AppColors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _passwordController,
              obscureText: _isPasswordObscured,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordObscured = !_isPasswordObscured;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  context.push(AppConstants.routeForgotPassword);
                },
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Log In',
              isLoading: _isLoading,
              onPressed: _signIn,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: AppColors.white.withValues(alpha: 0.5),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: AppColors.white.withValues(alpha: 0.5),
                    thickness: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _signInWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.googleBackground,
                foregroundColor: Colors.black87,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
                shadowColor: Colors.black26,
              ),
              icon: const FaIcon(
                FontAwesomeIcons.google,
                size: 20,
                color: AppColors.google,
              ),
              label: const Text(
                'Continue with Google',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: AppColors.white, fontSize: 16),
                  children: [
                    const TextSpan(text: "Don't have an account? "),
                    TextSpan(
                      text: 'Sign up',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          context.push(AppConstants.routeRegister);
                        },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
