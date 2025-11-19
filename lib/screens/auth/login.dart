import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:beranibicara/screens/auth/register.dart';
import 'package:beranibicara/screens/auth/forgot_password.dart';
import 'package:beranibicara/screens/splash.dart';
import 'package:beranibicara/utils/nisn_validator.dart';

// Mengambil instance Supabase dari main.dart
final supabase = Supabase.instance.client;

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
  bool _isNISNLogin = false; // ✅ Add NISN login mode

  // ✅ Auto-detect input type
  void _onInputChanged(String value) {
    if (value.length == 10 && RegExp(r'^\d+$').hasMatch(value)) {
      setState(() => _isNISNLogin = true);
    } else if (value.contains('@')) {
      setState(() => _isNISNLogin = false);
    }
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Peringatan'),
            content: Text(_isNISNLogin 
              ? 'NISN dan Password harus diisi' 
              : 'Email dan Password harus diisi'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    // ✅ Validasi NISN format jika menggunakan NISN
    if (_isNISNLogin && !NISNValidator.isValidFormat(_emailController.text)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Format NISN tidak valid. NISN harus 10 digit angka.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isNISNLogin) {
        // ✅ Login dengan NISN
        await _signInWithNISN();
      } else {
        // ✅ Login dengan Email (existing logic)
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }

      if (mounted) {
        // Jika berhasil, navigasi ke Dashboard dan hapus semua halaman sebelumnya
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
        );
      }
    } on AuthException {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(_isNISNLogin 
                ? 'NISN atau Password salah' 
                : 'Email atau Password salah'),
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
    } catch (error) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Terjadi error: $error'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ✅ Method untuk login dengan NISN
  Future<void> _signInWithNISN() async {
    // Cari user berdasarkan NISN
    final response = await supabase
        .from('profiles')
        .select('id')
        .eq('nisn', _emailController.text.trim())
        .single();

    // Ambil email user dari auth.users
    final userResponse = await supabase
        .from('auth.users')
        .select('email')
        .eq('id', response['id'])
        .single();

    // Login dengan email yang ditemukan
    await supabase.auth.signInWithPassword(
      email: userResponse['email'],
      password: _passwordController.text.trim(),
    );
  }

  // Fungsi Google Sign In bisa kita gunakan kembali
  Future<void> _signInWithGoogle() async {
    try {
      final androidClientId = dotenv.env['GOOGLE_CLIENT_ID'];

      final GoogleSignIn googleSignIn = GoogleSignIn(clientId: androidClientId);
      
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        return;
      }
      
      final googleAuth = await googleUser.authentication;
      
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID token found from Google authentication!';
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      // Navigation will be handled by auth listener in main.dart
    } catch (error) {
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Error login dengan Google: $error'),
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
      backgroundColor: const Color(0xFF36A395), // Warna background teal
      appBar: AppBar(
        title: const Text('Log In'),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: Image.asset(
                  "assets/images/logo.png",
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            Text(_isNISNLogin ? 'NISN' : 'Email', style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: _isNISNLogin ? TextInputType.number : TextInputType.emailAddress,
              maxLength: _isNISNLogin ? 10 : null,
              onChanged: _onInputChanged,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                hintText: 'Masukkan email / NISN (10 digit)',
                counterText: _isNISNLogin ? '' : null,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Password', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _isPasswordObscured,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _isPasswordObscured = !_isPasswordObscured;
                    });
                  },
                ),
                hintText: 'Masukkan password',
              ),
            ),
            const SizedBox(height: 16),
            // Forgot Password Link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                  );
                },
              child: const Text('Lupa Password?', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9C0C0),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Log In',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
            
            const SizedBox(height: 16),
            // OR Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.5), thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.5), thickness: 1)),
              ],
            ),
            const SizedBox(height: 16),
            // Google Sign-In Button
            ElevatedButton.icon(
              onPressed: _signInWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 2,
                shadowColor: Colors.black26,
              ),
              icon: const FaIcon(
                FontAwesomeIcons.google,
                size: 20,
                color: Color(0xFFDB4437),
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
            const SizedBox(height: 16),
            // Link untuk navigasi ke halaman Register
            Center(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 16),
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
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
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