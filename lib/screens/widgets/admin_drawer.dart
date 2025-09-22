import 'package:beranibicara/screens/admin/dashboard_admin.dart';
import 'package:beranibicara/screens/admin/kelola_laporan.dart';
import 'package:beranibicara/screens/admin/kelola_user.dart';
import 'package:beranibicara/screens/admin/profile.dart';
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
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF36A395),
            ),
            child: GestureDetector(
              onTap: () {
                // Jika sudah di halaman profil, tutup saja drawer-nya
                if (currentRoute == AdminProfileScreen.routeName) {
                  Navigator.pop(context);
                  return;
                }
                // Jika di halaman lain, ganti halaman ke profil
                Navigator.pop(context); // Tutup drawer dulu
                Navigator.pushNamed(context, AdminProfileScreen.routeName);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Icon(Icons.person, size: 36),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    supabase.auth.currentUser?.userMetadata?['full_name'] ?? 'Admin TPPK',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    supabase.auth.currentUser?.email ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
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