import 'package:flutter/material.dart';

class DashboardTeacher extends StatelessWidget {
  const DashboardTeacher({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard Wali Kelas')),
      body: Center(
        child: Text('Selamat Datang, Wali Kelas!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}