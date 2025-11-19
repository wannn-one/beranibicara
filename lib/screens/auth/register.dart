import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:beranibicara/screens/auth/email_verification.dart';
import 'package:beranibicara/utils/nisn_validator.dart';

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
  final _nisnController = TextEditingController(); // ✅ Add NISN controller

  bool _isPasswordObscured = true;
  bool _isLoading = false;
  bool _isTermsAccepted = false;
  bool _isNISNRegistration = false; // ✅ Add NISN registration mode
  Map<String, dynamic>? _nisnInfo; // ✅ Store NISN validation info

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
                   // 1. Tutup dialog
                   Navigator.of(context).pop(); 
               
                   // 2. Navigasi ke halaman verifikasi email yang baru
                   Navigator.of(context).pushReplacement(
                     MaterialPageRoute(
                       builder: (context) => EmailVerificationScreen(email: _emailController.text.trim()),
                     ),
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
      

    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${error.message}')));
      }
    } catch (error) {
       if (mounted) {
        // Error handled by UI
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi error saat login dengan Google')));
      }
    }
  }


  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nisnController.dispose(); // ✅ Dispose NISN controller
    super.dispose();
  }

  // ✅ Method untuk validasi NISN (SECURE)
  Future<void> _validateNISN() async {
    if (_nisnController.text.isEmpty) {
      _showErrorDialog('NISN harus diisi');
      return;
    }

    if (!NISNValidator.isValidFormat(_nisnController.text)) {
      _showErrorDialog('Format NISN tidak valid. NISN harus 10 digit angka.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Server-side validation untuk keamanan
      final response = await supabase.rpc('check_nisn_available', params: {
        'nisn_input': _nisnController.text.trim(),
      });

      if (response['is_valid'] == false) {
        _showErrorDialog('NISN tidak ditemukan dalam database sekolah.');
        return;
      }

      if (response['is_registered'] == true) {
        _showErrorDialog('NISN sudah terdaftar. Silakan gunakan NISN lain atau hubungi admin.');
        return;
      }

      // NISN valid dan tersedia
      setState(() {
        _nisnInfo = response;
        _isNISNRegistration = true;
        _fullNameController.text = response['nama_siswa'] ?? '';
      });

      _showSuccessDialog('NISN valid! Silakan lengkapi data pendaftaran.');
    } catch (error) {
      _showErrorDialog('Gagal validasi NISN: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ Method untuk registrasi dengan NISN (SECURE)
  Future<void> _signUpWithNISN() async {
    if (_passwordController.text.isEmpty || _emailController.text.isEmpty) {
      _showErrorDialog('Password dan Email harus diisi');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Server-side validation untuk keamanan
      final validationResult = await supabase.rpc('validate_nisn_registration', params: {
        'nisn_input': _nisnController.text.trim(),
        'user_email': _emailController.text.trim(),
      });

      if (!validationResult) {
        _showErrorDialog('NISN tidak valid atau sudah terdaftar');
        return;
      }

      // ✅ Baru create user setelah validasi server
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'full_name': _fullNameController.text.trim(),
          'nisn': _nisnController.text.trim(), // ✅ Pass NISN in metadata
        },
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Registrasi Berhasil'),
              content: const Text(
                'Akun Anda berhasil dibuat dengan NISN. '
                'Silakan cek email untuk verifikasi, kemudian login menggunakan NISN dan password Anda.'
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Back to login
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      _showErrorDialog('Gagal registrasi: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Berhasil'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
            // ✅ Toggle untuk pilih jenis registrasi
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Pilih Jenis Registrasi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            leading: Radio<bool>(
                              value: false,
                              groupValue: _isNISNRegistration,
                              onChanged: (value) {
                                setState(() {
                                  _isNISNRegistration = value!;
                                  _nisnController.clear();
                                  _nisnInfo = null;
                                });
                              },
                            ),
                            title: const Text('Email'),
                            onTap: () {
                              setState(() {
                                _isNISNRegistration = false;
                                _nisnController.clear();
                                _nisnInfo = null;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            leading: Radio<bool>(
                              value: true,
                              groupValue: _isNISNRegistration,
                              onChanged: (value) {
                                setState(() {
                                  _isNISNRegistration = value!;
                                  _emailController.clear();
                                });
                              },
                            ),
                            title: const Text('NISN'),
                            onTap: () {
                              setState(() {
                                _isNISNRegistration = true;
                                _emailController.clear();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ NISN Input (jika mode NISN)
            if (_isNISNRegistration) ...[
              const Text('NISN', style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nisnController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        hintText: 'Masukkan NISN (10 digit)',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _validateNISN,
                    child: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Validasi'),
                  ),
                ],
              ),
              if (_nisnInfo != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nama: ${_nisnInfo!['nama_siswa']}'),
                      if (_nisnInfo!['tingkat'] != null) Text('Tingkat: ${_nisnInfo!['tingkat']}'),
                      if (_nisnInfo!['jurusan'] != null) Text('Jurusan: ${_nisnInfo!['jurusan']}'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],

            // ✅ Email Input (jika mode Email)
            if (!_isNISNRegistration) ...[
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
              const SizedBox(height: 16),
            ],

            // ✅ Email Input untuk verifikasi (jika mode NISN)
            if (_isNISNRegistration) ...[
              const Text('Email untuk Verifikasi', style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  hintText: 'Masukkan email asli untuk verifikasi',
                ),
              ),
              const SizedBox(height: 16),
            ],

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
            const SizedBox(height: 24),
            CheckboxListTile(
              value: _isTermsAccepted,
              onChanged: (bool? value) {
                setState(() {
                  _isTermsAccepted = value ?? false;
                });
              },
              title: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  children: [
                    const TextSpan(text: 'Dengan mencentang ini, saya mengonfirmasi bahwa saya berusia di atas 13 tahun, ATAU saya adalah orang tua/wali yang mendaftarkan akun ini untuk anak saya dan telah membaca serta menyetujui '),
                    TextSpan(
                      text: 'Syarat & Ketentuan',
                      style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launchUrl(Uri.parse('https://beranibicara.site/terms-of-service'));
                        },
                    ),
                    const TextSpan(text: ' dan '),
                    TextSpan(
                      text: 'Kebijakan Privasi',
                      style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launchUrl(Uri.parse('https://beranibicara.site/privacy-policy'));
                        },
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Colors.white,
              checkColor: const Color(0xFF36A395),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading || !_isTermsAccepted 
                ? null 
                : (_isNISNRegistration ? _signUpWithNISN : _signUp),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9C0C0),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _isNISNRegistration ? 'Daftar dengan NISN' : 'Sign Up',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
