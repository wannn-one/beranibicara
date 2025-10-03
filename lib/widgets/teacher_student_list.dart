import 'package:flutter/material.dart';

class TeacherStudentList extends StatelessWidget {
  final List<Map<String, dynamic>> daftarSiswa;

  const TeacherStudentList({
    super.key,
    required this.daftarSiswa,
  });

  @override
  Widget build(BuildContext context) {
    if (daftarSiswa.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'Tidak ada siswa terdaftar',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: const Color(0xFF36A395),
                ),
                const SizedBox(width: 8),
                Text(
                  'Total: ${daftarSiswa.length} siswa',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...daftarSiswa.asMap().entries.map((entry) {
              final index = entry.key;
              final siswa = entry.value;
              final isLast = index == daftarSiswa.length - 1;

              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF36A395),
                      radius: 18,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    title: Text(
                      siswa['full_name'] ?? 'Nama tidak diketahui',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (!isLast) const Divider(height: 8),
                ],
              );
            }
          ),
        ],
      ),
    ),
  );
  }
} 