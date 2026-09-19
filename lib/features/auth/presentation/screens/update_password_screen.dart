import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:beranibicara/core/constants/app_colors.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/features/auth/presentation/providers/auth_notifier.dart';
import 'package:beranibicara/shared/widgets/custom_button.dart';
import 'package:beranibicara/shared/widgets/custom_text_field.dart';
import 'package:beranibicara/shared/widgets/dialogs.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password != confirm) {
      showAppMessageDialog(
        context,
        'Peringatan',
        'Konfirmasi password tidak sama',
      );
      return;
    }

    final authNotifier = context.read<AuthNotifier>();
    final success = await authNotifier.updatePassword(password);
    if (!mounted) return;

    if (success) {
      context.go(AppConstants.routeDashboard);
    } else {
      showErrorDialog(
        context,
        authNotifier.errorMessage ?? 'Gagal menyimpan password',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<AuthNotifier>().isUpdatingPassword;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Password Baru'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Buat password baru',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Masukkan password baru untuk akun Anda.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Text('Password baru', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          PasswordField(
            controller: _passwordController,
            showPrefixIcon: false,
          ),
          const SizedBox(height: 16),
          const Text('Konfirmasi password', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          PasswordField(
            controller: _confirmController,
            showPrefixIcon: false,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Simpan password',
            isLoading: saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
