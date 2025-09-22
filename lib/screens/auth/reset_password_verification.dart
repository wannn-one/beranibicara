import 'package:beranibicara/screens/auth/update_password.dart';
import 'package:beranibicara/screens/auth/verification.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ResetPasswordVerificationScreen extends StatefulWidget {
  final String email;
  const ResetPasswordVerificationScreen({super.key, required this.email});

  @override
  State<ResetPasswordVerificationScreen> createState() => _ResetPasswordVerificationScreenState();
}

class _ResetPasswordVerificationScreenState extends State<ResetPasswordVerificationScreen> {
  @override
  Widget build(BuildContext context) {
    return VerificationScreen(
      email: widget.email,
      screenTitle: 'Verifikasi OTP',
      mainText: 'Silakan Cek Email Anda',
      buttonText: 'Verifikasi',
      otpType: OtpType.recovery,
      onResend: (email) => supabase.auth.resetPasswordForEmail(email),
      onSuccess: (context) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const UpdatePasswordScreen()),
        );
      },
    );
  }
}