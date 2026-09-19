import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/constants/app_colors.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/shared/widgets/auth_logo.dart';
import 'package:beranibicara/shared/widgets/custom_button.dart';
import 'package:beranibicara/shared/widgets/custom_text_field.dart';
import 'package:beranibicara/shared/widgets/dialogs.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isEmailSent = false;

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      showAppMessageDialog(context, 'Peringatan', 'Email harus diisi');
      return;
    }

    final authNotifier = context.read<AuthNotifier>();
    final success = await authNotifier.resetPassword(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _isEmailSent = true;
      });
    } else {
      showErrorDialog(
        context,
        authNotifier.errorMessage ?? 'Gagal mengirim email reset',
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthNotifier>().isResettingPassword;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
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
            const SizedBox(height: 30),
            
            if (!_isEmailSent) ...[
              // Form untuk input email
              Center(
                child: Text(
                  'Forgot Your Password?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Enter your email address and we\'ll send you a link to reset your password. Open the link on this device.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              
              const Text('Email', style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                hint: 'Enter your email address',
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: 'Send Reset Link',
                isLoading: isLoading,
                onPressed: _resetPassword,
              ),
            ] else ...[
              // Pesan sukses setelah email terkirim
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Check Your Email',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'We\'ve sent a password reset link to:',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _emailController.text,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Please check your email and open the link on this phone to set a new password.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    
                    CustomButton(
                      text: 'Send Another Email',
                      onPressed: () {
                        setState(() {
                          _isEmailSent = false;
                          _emailController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 40),
            // Link untuk kembali ke halaman Login
            Center(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  children: [
                    const TextSpan(text: "Remember your password? "),
                    TextSpan(
                      text: 'Back to Login',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          context.go(AppConstants.routeLogin);
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