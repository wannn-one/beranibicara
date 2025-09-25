import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;

  // Password validation states
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigits = false;
  bool _hasSpecialCharacters = false;
  bool _passwordsMatch = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validatePasswordMatch);
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasDigits = password.contains(RegExp(r'[0-9]'));
      _hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
    _validatePasswordMatch();
  }

  void _validatePasswordMatch() {
    setState(() {
      _passwordsMatch = _passwordController.text.isNotEmpty && 
                       _confirmPasswordController.text.isNotEmpty &&
                       _passwordController.text == _confirmPasswordController.text;
    });
  }

  bool get _isPasswordValid {
    return _hasMinLength && _hasUppercase && _hasLowercase && _hasDigits && _passwordsMatch;
  }

  String get _passwordStrength {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasLowercase) score++;
    if (_hasDigits) score++;
    if (_hasSpecialCharacters) score++;

    switch (score) {
      case 0:
      case 1:
        return 'Sangat Lemah';
      case 2:
        return 'Lemah';
      case 3:
        return 'Sedang';
      case 4:
        return 'Kuat';
      case 5:
        return 'Sangat Kuat';
      default:
        return 'Sangat Lemah';
    }
  }

  Color get _passwordStrengthColor {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasLowercase) score++;
    if (_hasDigits) score++;
    if (_hasSpecialCharacters) score++;

    switch (score) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  Future<void> _updatePassword() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password baru tidak boleh kosong')),
      );
      return;
    }

    if (!_isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password tidak memenuhi kriteria yang diperlukan')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isGoogleUser 
              ? 'Password berhasil dibuat! Sekarang Anda dapat login dengan email dan password.' 
              : 'Password berhasil diperbarui!'
            )
          ),
        );
        _passwordController.clear();
        _confirmPasswordController.clear();
        // Kembali ke halaman profil setelah berhasil
        Navigator.of(context).pop();
        if (!_isGoogleUser) {
          Navigator.of(context).pop(); // Pop twice to go back to profile from verify screen (only for non-Google users)
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${error.message}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Widget _buildPasswordCriteriaItem(String text, bool isValid, {bool isOptional = false}) {
    Color getColor() {
      if (isOptional && !isValid) {
        return Colors.grey; // Show grey for optional items that aren't met
      }
      return isValid ? Colors.green : Colors.red;
    }

    IconData getIcon() {
      if (isOptional && !isValid) {
        return Icons.help_outline; // Show help icon for optional items that aren't met
      }
      return isValid ? Icons.check_circle : Icons.cancel;
    }

    return Row(
      children: [
        Icon(
          getIcon(),
          color: getColor(),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: getColor(),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePassword);
    _confirmPasswordController.removeListener(_validatePasswordMatch);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isGoogleUser {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final identities = user.identities;
      return identities?.any((identity) => identity.provider == 'google') ?? false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isGoogleUser ? 'Buat Password' : 'Ubah Password'),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
        elevation: 1.0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            _isGoogleUser 
              ? 'Buat password untuk akun Anda. Ini akan memungkinkan Anda untuk login menggunakan email dan password selain Google.'
              : 'Buat password baru yang kuat untuk melindungi akun Anda.',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          
          // New Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _isPasswordObscured,
            decoration: InputDecoration(
              labelText: 'Password Baru',
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
          ),
          
          // Password Strength Indicator
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Kekuatan Password: ',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  _passwordStrength,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _passwordStrengthColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (_hasMinLength ? 0.2 : 0) +
                     (_hasUppercase ? 0.2 : 0) +
                     (_hasLowercase ? 0.2 : 0) +
                     (_hasDigits ? 0.2 : 0) +
                     (_hasSpecialCharacters ? 0.2 : 0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _isConfirmPasswordObscured,
            decoration: InputDecoration(
              labelText: 'Konfirmasi Password Baru',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordObscured ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                  });
                },
              ),
            ),
          ),
          
          // Password Match Indicator
          if (_confirmPasswordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _passwordsMatch ? Icons.check_circle : Icons.cancel,
                  color: _passwordsMatch ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _passwordsMatch ? 'Password cocok' : 'Password tidak cocok',
                  style: TextStyle(
                    color: _passwordsMatch ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Password Criteria
          const Text(
            'Password harus memenuhi kriteria berikut:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildPasswordCriteriaItem('Minimal 8 karakter', _hasMinLength),
          const SizedBox(height: 4),
          _buildPasswordCriteriaItem('Huruf besar (A-Z)', _hasUppercase),
          const SizedBox(height: 4),
          _buildPasswordCriteriaItem('Huruf kecil (a-z)', _hasLowercase),
          const SizedBox(height: 4),
          _buildPasswordCriteriaItem('Angka (0-9)', _hasDigits),
          const SizedBox(height: 4),
          _buildPasswordCriteriaItem('Karakter khusus (!@#\$%^&*) - Opsional', _hasSpecialCharacters, isOptional: true),
          const SizedBox(height: 4),
          _buildPasswordCriteriaItem('Password cocok', _passwordsMatch),
          
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_isLoading || !_isPasswordValid) ? null : _updatePassword,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _isPasswordValid ? const Color(0xFF36A395) : Colors.grey,
              foregroundColor: _isPasswordValid ? Colors.white : Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : Text(_isGoogleUser ? 'Buat Password' : 'Simpan Password Baru'),
          )
        ],
      ),
    );
  }
}