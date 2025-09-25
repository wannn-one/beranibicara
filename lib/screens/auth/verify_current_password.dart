import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:beranibicara/screens/auth/change_password.dart';

final supabase = Supabase.instance.client;

class VerifyCurrentPasswordScreen extends StatefulWidget {
  const VerifyCurrentPasswordScreen({super.key});

  @override
  State<VerifyCurrentPasswordScreen> createState() => _VerifyCurrentPasswordScreenState();
}

class _VerifyCurrentPasswordScreenState extends State<VerifyCurrentPasswordScreen> {
  final _currentPasswordController = TextEditingController();
  bool _isPasswordObscured = true;
  bool _isLoading = false;
  bool _isGoogleUser = false;

  @override
  void initState() {
    super.initState();
    _checkAuthProvider();
  }

  void _checkAuthProvider() {
    final user = supabase.auth.currentUser;
    if (user != null) {
      // Check if user has Google as provider
      final identities = user.identities;
      _isGoogleUser = identities?.any((identity) => identity.provider == 'google') ?? false;
      
      // If user is Google user, automatically navigate to change password
      if (_isGoogleUser) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showGoogleUserDialog();
        });
      }
    }
  }

  void _showGoogleUserDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Akun Google'),
          content: const Text(
            'Anda masuk menggunakan akun Google. Karena Anda belum memiliki password, Anda dapat langsung membuat password baru untuk akun Anda.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to profile
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF36A395),
                foregroundColor: Colors.white,
              ),
              child: const Text('Buat Password'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _verifyCurrentPassword() async {
    if (_currentPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password saat ini tidak boleh kosong')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // Get current user email
      final user = supabase.auth.currentUser;
      if (user?.email == null) {
        throw AuthException('User tidak ditemukan');
      }

      // Create a temporary Supabase client to verify password without affecting current session
      final tempClient = SupabaseClient(
        dotenv.env['SUPABASE_URL']!,
        dotenv.env['SUPABASE_ANON_KEY']!,
      );

      // Verify password using temporary client
      await tempClient.auth.signInWithPassword(
        email: user!.email!,
        password: _currentPasswordController.text.trim(),
      );

      // Close the temporary client
      tempClient.dispose();

      if (mounted) {
        // Password is correct, navigate to change password screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ChangePasswordScreen(),
          ),
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        String errorMessage = 'Password salah';
        if (error.message.toLowerCase().contains('invalid login credentials')) {
          errorMessage = 'Password yang Anda masukkan salah. Silakan coba lagi.';
        } else if (error.message.toLowerCase().contains('email not confirmed')) {
          errorMessage = 'Email belum diverifikasi. Silakan verifikasi email terlebih dahulu.';
        } else {
          errorMessage = 'Error: ${error.message}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If user is Google user, show loading while dialog is being shown
    if (_isGoogleUser) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Password'),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
        elevation: 1.0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Untuk keamanan akun Anda, silakan masukkan password saat ini terlebih dahulu sebelum mengubah password.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _currentPasswordController,
            obscureText: _isPasswordObscured,
            decoration: InputDecoration(
              labelText: 'Password Saat Ini',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordObscured ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordObscured = !_isPasswordObscured;
                  });
                },
              ),
            ),
            onFieldSubmitted: (_) => _verifyCurrentPassword(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _verifyCurrentPassword,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF36A395),
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24, 
                    width: 24, 
                    child: CircularProgressIndicator(
                      color: Colors.white, 
                      strokeWidth: 3
                    )
                  )
                : const Text(
                  'Verifikasi Password',
                ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Catatan: Jika Anda lupa password, silakan keluar dan gunakan fitur "Lupa Password" di halaman login.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 