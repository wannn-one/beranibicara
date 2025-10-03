import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:beranibicara/widgets/student_drawer.dart';
import 'package:beranibicara/screens/student/buat_cerita.dart';
import 'package:beranibicara/screens/student/detail_cerita.dart';

final supabase = Supabase.instance.client;

class MadingKelasScreen extends StatefulWidget {
  static const String routeName = '/student-mading-kelas';
  const MadingKelasScreen({super.key});

  @override
  State<MadingKelasScreen> createState() => _MadingKelasScreenState();
}

class _MadingKelasScreenState extends State<MadingKelasScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _ceritaList = [];
  Map<String, dynamic>? _kelasInfo;
  // String _userName = 'Siswa';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = supabase.auth.currentUser!.id;
      
      // Fetch user info dan kelas
      final userResponse = await supabase
          .from('profiles')
          .select('full_name, kelas_id, kelas:kelas_id(id, tingkat, jurusan)')
          .eq('id', userId)
          .single();
      
      if (userResponse['kelas'] == null) {
        throw Exception('Anda belum terdaftar di kelas manapun');
      }
      
      setState(() {
        // _userName = userResponse['full_name'] ?? 'Siswa';
        _kelasInfo = userResponse['kelas'];
      });
      
      // Fetch cerita di kelas ini
      await _fetchCeritaKelas();
      
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchCeritaKelas() async {
    try {
      final kelasId = _kelasInfo!['id'];
      
      final response = await supabase
          .from('cerita_kelas')
          .select('''
            *,
            author:author_id(full_name),
            tanggapan_count:tanggapan_cerita(count)
          ''')
          .eq('kelas_id', kelasId)
          .eq('is_published', true)
          .order('created_at', ascending: false);
      
      setState(() {
        _ceritaList = (response as List).map((item) => item as Map<String, dynamic>).toList();
      });
      
    } catch (error) {
      debugPrint('Error fetching cerita: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_kelasInfo != null 
          ? 'Mading Kelas ${_kelasInfo!['tingkat']}${_kelasInfo!['jurusan']}'
          : 'Mading Kelas'
        ),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
        elevation: 1.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      drawer: const StudentDrawer(currentRoute: MadingKelasScreen.routeName),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => BuatCeritaScreen(kelasInfo: _kelasInfo!),
            ),
          );
          if (result == true && mounted) {
            _fetchCeritaKelas();
          }
        },
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tulis Cerita'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: _kelasInfo == null
                  ? _buildNoClassWidget()
                  : _buildCeritaList(),
            ),
    );
  }

  Widget _buildNoClassWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Anda Belum Terdaftar di Kelas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Silakan hubungi admin untuk mendaftarkan Anda ke dalam kelas.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCeritaList() {
    if (_ceritaList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.article_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Cerita di Kelas ${_kelasInfo!['tingkat']}${_kelasInfo!['jurusan']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Jadilah yang pertama berbagi cerita menarik!',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _ceritaList.length,
      itemBuilder: (context, index) {
        final cerita = _ceritaList[index];
        return _buildCeritaCard(cerita);
      },
    );
  }

  Widget _buildCeritaCard(Map<String, dynamic> cerita) {
    final authorName = cerita['author']?['full_name'] ?? 'Unknown';
    final createdAt = DateTime.parse(cerita['created_at']);
    final timeAgo = _getTimeAgo(createdAt);
    final tanggapanCount = cerita['tanggapan_count']?[0]?['count'] ?? 0;
    final hasImage = cerita['gambar_url'] != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => DetailCeritaScreen(ceritaId: cerita['id']),
            ),
          );
          if (result == true && mounted) {
            _fetchCeritaKelas();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan info author
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF36A395),
                    child: Text(
                      authorName.isNotEmpty ? authorName[0].toUpperCase() : 'A',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          timeAgo,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Judul cerita
              Text(
                cerita['judul'] ?? 'Tanpa Judul',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Konten cerita (preview)
              Text(
                cerita['konten'] ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              
              // Gambar jika ada
              if (hasImage) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: cerita['gambar_url'],
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Footer dengan jumlah tanggapan
              Row(
                children: [
                  Icon(Icons.comment_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '$tanggapanCount tanggapan',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    'Ketuk untuk baca selengkapnya',
                    style: TextStyle(
                      color: const Color(0xFF36A395),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
} 