import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class VerificationScreen extends StatefulWidget {
  final String email;
  final String screenTitle;
  final String mainText;
  final String buttonText;
  final OtpType otpType;
  final Future<void> Function(String email) onResend;
  final void Function(BuildContext context) onSuccess;

  const VerificationScreen({
    super.key,
    required this.email,
    required this.screenTitle,
    required this.mainText,
    required this.buttonText,
    required this.otpType,
    required this.onResend,
    required this.onSuccess,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Timer? _timer;
  int _resendTimer = 60;
  bool _isResendButtonActive = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _startTimer() {
    setState(() {
      _isResendButtonActive = false;
      _resendTimer = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isResendButtonActive = true;
        });
      }
    });
  }

  Future<void> _resendCode() async {
    try {
      await widget.onResend(widget.email);
      _showDialog('Sukses', 'Kode baru telah dikirim.');
      _startTimer();
    } catch (error) {
      _showDialog('Error', 'Gagal mengirim ulang kode: $error');
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      _showDialog('Peringatan', 'Silakan masukkan 6 digit kode OTP');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await supabase.auth.verifyOTP(
        token: _otpController.text.trim(),
        type: widget.otpType,
        email: widget.email,
      );

      if (mounted) {
        widget.onSuccess(context);
      }
    } on AuthException catch (error) {
      if (mounted) {
        _showDialog('Error', 'Verifikasi Gagal: ${error.message}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, color: Colors.black),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF36A395),
      appBar: AppBar(
        title: Text(widget.screenTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Text(
              widget.mainText,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Kami telah mengirimkan kode 6 digit ke\n${widget.email}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Pinput(
              length: 6,
              controller: _otpController,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: const Color(0xFFF9C0C0)),
                ),
              ),
              onCompleted: (pin) => _verifyOtp(),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(widget.buttonText),
            ),
            const SizedBox(height: 24),
            Center(
              child: _isResendButtonActive
                  ? TextButton(
                      onPressed: _resendCode,
                      child: const Text(
                        'Kirim ulang kode',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline),
                      ),
                    )
                  : Text(
                      'Kirim ulang dalam ($_resendTimer) detik',
                      style: const TextStyle(color: Colors.white70),
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 