import 'package:beranibicara/screens/auth/complete_profile.dart';
import 'package:beranibicara/screens/auth/verification.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  @override
  Widget build(BuildContext context) {
    return VerificationScreen(
      email: widget.email,
      screenTitle: 'Verifikasi Email',
      mainText: 'Satu Langkah Terakhir!',
      buttonText: 'Verifikasi & Lanjutkan',
      otpType: OtpType.signup,
      onResend: (email) => supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      ),
      onSuccess: (context) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
        );
      },
    );
  }
}