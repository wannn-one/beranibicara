import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/screens/widgets/admin_drawer.dart';
import 'package:beranibicara/screens/auth/change_passwort.dart';

final supabase = Supabase.instance.client;

class AdminProfileScreen extends StatefulWidget {
  static const String routeName = '/admin-profile';
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _passwordController = TextEditingController();

  final _currentUser = supabase.auth.currentUser;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1.0,
      ),
      drawer: const AdminDrawer(currentRoute: AdminProfileScreen.routeName),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Bagian Informasi Akun
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informasi Akun', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 24),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Nama Lengkap'),
                    subtitle: Text(_currentUser?.userMetadata?['full_name'] ?? 'Tidak ada nama'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: Text(_currentUser?.email ?? 'Tidak ada email'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Ubah Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}