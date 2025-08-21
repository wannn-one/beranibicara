import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard Admin TPPK')),
      body: Center(
        child: Text('Selamat Datang, Admin TPPK!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}