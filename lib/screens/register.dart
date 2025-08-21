import 'package:beranibicara/screens/splash.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:beranibicara/screens/complete_profile.dart';

final supabase = Supabase.instance.client;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_fullNameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Peringatan'),
            content: const Text('Semua field harus diisi'),
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
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {'full_name': _fullNameController.text.trim()},
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Berhasil'),
              content: const Text('Registrasi berhasil! Silakan cek email untuk verifikasi.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const SplashScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } on AuthException catch (error) {
       if (mounted) {
         showDialog(
           context: context,
           builder: (BuildContext context) {
             return AlertDialog(
               title: const Text('Error'),
               content: Text('Error: ${error.message}'),
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
              content: const Text('Terjadi error yang tidak terduga.'),
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

    Future<void> _signUpWithGoogle() async {
    try {
      // 1. Dapatkan Web Client ID dari Google Cloud Console (kredensial Web)
      // get from env
      final webClientId = dotenv.env['GOOGLE_CLIENT_ID']!;

      // 2. Minta Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: webClientId);
      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser!.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID token found!';
      }

      // 3. Panggil Supabase signInWithIdToken
      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
      (route) => false,
      );
      }

    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${error.message}')));
      }
    } catch (error) {
       if (mounted) {
        debugPrint('Error: $error');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi error saat login dengan Google')));
      }
    }
  }


  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF36A395),
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Full name', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _isPasswordObscured = !_isPasswordObscured;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Email', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _signUp, // Nonaktifkan tombol saat loading
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9C0C0),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Sign Up',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            // Google Sign-In Button
            ElevatedButton.icon(
              onPressed: _signUpWithGoogle,
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
                color: Color(0xFFDB4437), // Google's brand red color
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
            const Center(
              child: Text('By continuing, you agree to', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(height: 8),
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Terms of Use',
                      style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline, color: Colors.white),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launchUrl(Uri.parse('https://www.websiteanda.com/terms'));
                        },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    TextSpan(
                      text: 'Log in',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.of(context).pop();
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