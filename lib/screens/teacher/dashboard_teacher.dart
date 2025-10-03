import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/widgets/teacher_drawer.dart';
import 'package:beranibicara/widgets/teacher_report_card.dart';
import 'package:beranibicara/widgets/teacher_student_list.dart';
import 'package:beranibicara/screens/teacher/report_list_screen.dart';
import 'package:beranibicara/screens/teacher/student_list_screen.dart';

final supabase = Supabase.instance.client;

class TeacherDashboardScreen extends StatefulWidget {
  static const String routeName = '/teacher-dashboard';
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // a. Dapatkan ID guru yang sedang login
      final teacherId = supabase.auth.currentUser!.id;
      // b. Cari data kelas yang wali_kelas_id-nya sama dengan ID guru
      final kelasResponse = await supabase
          .from('kelas')
          .select('id, tingkat, jurusan')
          .eq('wali_kelas_id', teacherId)
          .neq('tingkat', 99)
          .neq('jurusan', 'X')
          .single();

      final kelasId = kelasResponse['id'];
      final tingkat = kelasResponse['tingkat'];
      final jurusan = kelasResponse['jurusan'];
      final namaKelas = '$tingkat $jurusan';

      // c. Ambil 3 siswa teratas di kelas tersebut (ascending dari nama)
      final siswaResponse = await supabase
          .from('profiles')
          .select('id, full_name')
          .eq('kelas_id', kelasId)
          .eq('role', 'siswa')
          .order('full_name')
          .limit(3);

      final daftarSiswa = (siswaResponse as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();

      // Ambil daftar ID siswa untuk query laporan
      final siswaIds = daftarSiswa.map((siswa) => siswa['id']).toList();

      // d. Ambil 3 laporan terbaru dari siswa-siswa di kelas (termasuk anonim untuk tracking internal)
      List<Map<String, dynamic>> daftarLaporan = [];
      if (siswaIds.isNotEmpty) {
        final laporanResponse = await supabase
            .from('reports')
            .select('*, profiles(full_name)')
            .inFilter('reporter_id', siswaIds)
            // Tampilkan semua status seperti di admin, bukan hanya aktif
            // .inFilter('status', ['baru', 'diproses'])  // Comment out filter ini
            .order('created_at', ascending: false)
            .limit(3);

        daftarLaporan = (laporanResponse as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }

      // e. Kembalikan data dalam bentuk Map
      setState(() {
        _dashboardData = {
          'namaKelas': namaKelas,
          'daftarSiswa': daftarSiswa,
          'daftarLaporan': daftarLaporan,
        };
        _isLoading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $error')),
        );
      }
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Wali Kelas'),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
        elevation: 1.0,
      ),
      drawer: const TeacherDrawer(currentRoute: TeacherDashboardScreen.routeName),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header - Nama Kelas
                    Center(
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.school,
                                size: 48,
                                color: const Color(0xFF36A395),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Kelas ${_dashboardData['namaKelas'] ?? 'Unknown'}',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF36A395),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Bagian 1: Daftar 3 Laporan Terbaru
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Laporan Terbaru',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, TeacherReportListScreen.routeName);
                          },
                          child: const Text('Lihat Semua'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildLaporanSection(),

                    const SizedBox(height: 32),

                    // Bagian 2: Daftar 3 Siswa Teratas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daftar Siswa',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, TeacherStudentListScreen.routeName);
                          },
                          child: const Text('Lihat Semua'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildSiswaSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLaporanSection() {
    final daftarLaporan = _dashboardData['daftarLaporan'] as List<Map<String, dynamic>>? ?? [];

    if (daftarLaporan.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada laporan',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Belum ada laporan dari siswa di kelas ini',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: daftarLaporan.map((laporan) {
        return TeacherReportCard(laporan: laporan);
      }).toList(),
    );
  }

  Widget _buildSiswaSection() {
    final daftarSiswa = _dashboardData['daftarSiswa'] as List<Map<String, dynamic>>? ?? [];
    return TeacherStudentList(daftarSiswa: daftarSiswa);
  }
}