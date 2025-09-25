import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/screens/student/create_report.dart';
import 'package:beranibicara/widgets/student_drawer.dart';
import 'package:beranibicara/screens/student/track_report.dart';
import 'package:beranibicara/screens/student/socialization_detail.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

final supabase = Supabase.instance.client;

class StudentDashboardScreen extends StatefulWidget {
  static const String routeName = '/student-dashboard';
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  String _userName = 'Siswa';
  bool _isLoading = true;
  late Future<List<Map<String, dynamic>>> _reportsFuture;
  late Future<List<Map<String, dynamic>>> _socializationFuture;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _reportsFuture = _fetchUserReports();
    _socializationFuture = _fetchSocializationContent();
  }

  Future<void> _fetchUserName() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .single();

      if (response['full_name'] != null) {
        setState(() {
          _userName = response['full_name'];
        });
      }
    } catch (error) {
      debugPrint('Error fetching user name: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUserReports() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('reports')
          .select('*')
          .eq('reporter_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((item) => item as Map<String, dynamic>).toList();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: $error')));
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSocializationContent() async {
    try {
      final response = await supabase
          .from('socialization')
          .select('*, profiles(full_name)')
          .order('published_at', ascending: false)
          .limit(5);

      return (response as List).map((item) => item as Map<String, dynamic>).toList();
    } catch (error) {
      debugPrint('Error fetching socialization content: $error');
      return [];
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'baru':
        return Colors.blue;
      case 'diproses':
        return Colors.orange;
      case 'selesai':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'baru':
        return 'Baru';
      case 'diproses':
        return 'Diproses';
      case 'selesai':
        return 'Selesai';
      case 'ditolak':
        return 'Ditolak';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
        elevation: 1.0,
      ),
      drawer: const StudentDrawer(currentRoute: StudentDashboardScreen.routeName),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang,\n$_userName!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (context) => const CreateReportScreen()),
                      );
                      if (result == true && mounted) {
                        setState(() {
                          _reportsFuture = _fetchUserReports();
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Buat Laporan Baru'
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      textStyle: const TextStyle(fontSize: 18),
                      backgroundColor: Color(0xFF36A395),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bagian Sosialisasi & Edukasi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sosialisasi & Edukasi',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/student-socialization');
                        },
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(
                            color: Color(0xFF36A395),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Konten Sosialisasi
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _socializationFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      
                      if (snapshot.hasError) {
                        return Container(
                          height: 120,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text('Gagal memuat konten sosialisasi'),
                          ),
                        );
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Container(
                          height: 120,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.article_outlined, size: 32, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Belum ada konten sosialisasi'),
                              ],
                            ),
                          ),
                        );
                      }

                      final contents = snapshot.data!;
                      return SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: contents.length,
                          itemBuilder: (context, index) {
                            final content = contents[index];
                            final publishedAt = DateTime.parse(content['published_at'] ?? content['created_at']);
                            final formattedDate = DateFormat('d MMM yyyy').format(publishedAt);
                            final authorName = content['profiles']?['full_name'] ?? 'TPPK';
                            final coverImageUrl = content['cover_image_url'] as String?;

                            return Container(
                              width: 280,
                              margin: EdgeInsets.only(
                                right: index < contents.length - 1 ? 16 : 0,
                              ),
                              child: Card(
                                elevation: 2,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SocializationDetailScreen(content: content),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Cover Image
                                      if (coverImageUrl != null)
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                          child: CachedNetworkImage(
                                            imageUrl: coverImageUrl,
                                            height: 120,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              height: 120,
                                              color: Colors.grey[300],
                                              child: const Center(child: CircularProgressIndicator()),
                                            ),
                                            errorWidget: (context, url, error) => Container(
                                              height: 120,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.broken_image),
                                            ),
                                          ),
                                        ),
                                      
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                content['title'] ?? 'Tanpa Judul',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Expanded(
                                                child: Text(
                                                  content['content'] ?? '',
                                                  maxLines: coverImageUrl != null ? 2 : 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.person, size: 11, color: Colors.grey[600]),
                                                  const SizedBox(width: 2),
                                                  Expanded(
                                                    child: Text(
                                                      authorName,
                                                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Icon(Icons.schedule, size: 11, color: Colors.grey[600]),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    formattedDate,
                                                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Bagian Laporan Saya
                  Text(
                    'Laporan Saya',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  // Daftar laporan menggunakan FutureBuilder
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _reportsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text('Error: ${snapshot.error}'),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text('Anda belum membuat laporan.'),
                          ),
                        );
                      }

                      final reports = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final report = reports[index];
                          final reportDate = DateTime.parse(report['created_at']);
                          final formattedDate = DateFormat('d MMMM yyyy, HH:mm').format(reportDate);
                          final status = report['status'] ?? 'baru';
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                report['title'] ?? 'Laporan Tanpa Judul',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                'Dibuat: $formattedDate',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(status),
                                  style: TextStyle(
                                    color: _getStatusColor(status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => TrackingReportScreen(reportId: report['id']),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}