import 'package:beranibicara/screens/admin/dashboard_admin.dart';
import 'package:beranibicara/screens/admin/kelola_laporan.dart';
import 'package:beranibicara/screens/admin/kelola_user.dart';
import 'package:beranibicara/screens/splash.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AdminDrawer extends StatelessWidget {
  // Variabel untuk menerima rute halaman saat ini
  final String currentRoute;

  const AdminDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(supabase.auth.currentUser?.userMetadata?['full_name'] ?? 'Admin TPPK'),
            accountEmail: Text(supabase.auth.currentUser?.email ?? ''),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 48),
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF36A395),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded),
            title: const Text('Dashboard'),
            // Logika untuk highlight: jika rute saat ini adalah rute dashboard
            selected: currentRoute == AdminDashboardScreen.routeName,
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              // Ganti halaman, jangan menumpuk
              Navigator.pushReplacementNamed(context, AdminDashboardScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_rounded),
            title: const Text('Kelola Laporan'),
            // Logika untuk highlight: jika rute saat ini adalah rute kelola laporan
            selected: currentRoute == ManageReportsScreen.routeName,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, ManageReportsScreen.routeName);
            },
          ),
          ListTile(
          leading: const Icon(Icons.group_rounded),
          title: const Text('Kelola Pengguna'),
          selected: currentRoute == ManageUsersScreen.routeName,
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, ManageUsersScreen.routeName);
          },
        ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Logout'),
            onTap: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SplashScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}