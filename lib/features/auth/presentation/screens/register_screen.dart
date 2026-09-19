import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/constants/app_colors.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/core/constants/app_strings.dart';
import 'package:beranibicara/core/utils/legal_urls.dart';
import 'package:beranibicara/core/utils/url_utils.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/features/auth/presentation/widgets/nisn_text_field.dart';
import 'package:beranibicara/features/auth/presentation/widgets/role_selector.dart';
import 'package:beranibicara/shared/widgets/custom_button.dart';
import 'package:beranibicara/shared/widgets/custom_text_field.dart';
import 'package:beranibicara/shared/widgets/dialogs.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nisnController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isLoading = false;
  bool _acceptedLegal = false;
  UserRole _selectedRole = UserRole.siswa;

  @override
  void initState() {
    super.initState();
    _nisnController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _requireLegalConsent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.acceptLegalToContinue)),
    );
  }

  Future<void> _signUp() async {
    if (!_acceptedLegal) {
      _requireLegalConsent();
      return;
    }

    if (_fullNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      showAppMessageDialog(context, 'Peringatan', 'Semua field harus diisi');
      return;
    }

    if (_selectedRole == UserRole.siswa) {
      final authNotifier = context.read<AuthNotifier>();
      if (_nisnController.text.trim().length != AppConstants.nisnLength ||
          authNotifier.verifiedNisn?.nisn != _nisnController.text.trim()) {
        showAppMessageDialog(
          context,
          'Peringatan',
          'Verifikasi NISN terlebih dahulu sebelum mendaftar',
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authNotifier = context.read<AuthNotifier>();
      final success = await authNotifier.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
        nisn: _selectedRole == UserRole.siswa
            ? _nisnController.text.trim()
            : null,
      );

      if (!mounted) return;

      if (!success) {
        showErrorDialog(
          context,
          authNotifier.errorMessage ?? 'Registrasi gagal',
        );
        return;
      }

      if (authNotifier.isAuthenticated) {
        context.go(AppConstants.routeDashboard);
        return;
      }

      showSuccessDialog(
        context,
        'Registrasi berhasil. Cek email di HP ini, buka tautan verifikasi, lalu Anda masuk otomatis. Atau masuk manual setelah email dikonfirmasi.',
        onClose: () {
          if (mounted) context.go(AppConstants.routeLogin);
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    if (!_acceptedLegal) {
      _requireLegalConsent();
      return;
    }

    if (_selectedRole == UserRole.guru) {
      showAppMessageDialog(
        context,
        'Peringatan',
        'Akun guru menggunakan daftar email. Google saat ini hanya untuk siswa.',
      );
      return;
    }

    final authNotifier = context.read<AuthNotifier>();
    final success = await authNotifier.signInWithGoogle();
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authNotifier.errorMessage ??
                'Terjadi error saat daftar dengan Google',
          ),
        ),
      );
      return;
    }

    context.go(AppConstants.routeDashboard);
  }

  Future<void> _verifyNisn() async {
    final authNotifier = context.read<AuthNotifier>();
    await authNotifier.verifyNisn(_nisnController.text.trim());
    if (!mounted) return;
    if (authNotifier.verifiedNisn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authNotifier.errorMessage ?? AppStrings.nisnInvalid),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nisnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final nisn = _nisnController.text.trim();
    final nisnVerified =
        authNotifier.verifiedNisn != null &&
        authNotifier.verifiedNisn!.nisn == nisn;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RoleSelector(
              selectedRole: _selectedRole,
              onRoleChanged: (role) {
                setState(() {
                  _selectedRole = role;
                });
                authNotifier.clearNisnVerification();
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Full name',
              style: TextStyle(color: AppColors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            CustomTextField(controller: _fullNameController),
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
                  _isPasswordObscured
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordObscured = !_isPasswordObscured;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Email',
              style: TextStyle(color: AppColors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            if (_selectedRole == UserRole.siswa) ...[
              const SizedBox(height: 16),
              Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                child: NisnTextField(
                  controller: _nisnController,
                  isVerifying: authNotifier.isNisnVerifying,
                  isVerified: nisn.isEmpty ? null : nisnVerified,
                  onVerifyPressed: _verifyNisn,
                ),
              ),
            ],
            const SizedBox(height: 20),
            CheckboxListTile(
              value: _acceptedLegal,
              onChanged: (value) {
                setState(() {
                  _acceptedLegal = value ?? false;
                });
              },
              activeColor: AppColors.secondary,
              checkColor: Colors.black87,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text.rich(
                TextSpan(
                  style: const TextStyle(color: AppColors.white, fontSize: 14),
                  children: [
                    const TextSpan(text: 'Saya setuju dengan '),
                    TextSpan(
                      text: AppStrings.termsOfUse,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => openExternalUrl(termsOfUseUrl()),
                    ),
                    const TextSpan(text: ' dan '),
                    TextSpan(
                      text: AppStrings.privacyPolicy,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => openExternalUrl(privacyPolicyUrl()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Sign Up',
              isLoading: _isLoading,
              onPressed: (_isLoading || !_acceptedLegal) ? null : _signUp,
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
              onPressed: (!_acceptedLegal || _selectedRole == UserRole.guru)
                  ? null
                  : _signUpWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: Colors.black87,
                disabledBackgroundColor: Colors.white24,
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
            if (_selectedRole == UserRole.guru) ...[
              const SizedBox(height: 8),
              const Text(
                'Akun guru didaftarkan lewat email, bukan Google.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: AppColors.white, fontSize: 16),
                    ),
                    TextSpan(
                      text: 'Log in',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
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
