import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:beranibicara/widgets/teacher_drawer.dart';
import 'package:beranibicara/screens/teacher/detail_cerita_teacher.dart';
import 'package:beranibicara/utils/datetime_utils.dart';

final supabase = Supabase.instance.client;

class MadingKelasTeacherScreen extends StatefulWidget {
  static const String routeName = '/teacher-mading-kelas';
  const MadingKelasTeacherScreen({super.key});

  @override
  State<MadingKelasTeacherScreen> createState() => _MadingKelasTeacherScreenState();
}

class _MadingKelasTeacherScreenState extends State<MadingKelasTeacherScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _ceritaList = [];
  List<Map<String, dynamic>> _kelasList = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = supabase.auth.currentUser!.id;
      
       // Fetch kelas yang diwali oleh guru ini
       final kelasResponse = await supabase
           .from('kelas')
           .select('id, tingkat, jurusan')
           .eq('wali_kelas_id', userId)
           .neq('tingkat', 99)
           .neq('jurusan', 'X')
           .order('tingkat', ascending: true)
           .order('jurusan', ascending: true);
      
      setState(() {
        _kelasList = (kelasResponse as List).map((item) => item as Map<String, dynamic>).toList();
      });
      
      // Fetch cerita dari kelas yang diwali
      await _fetchCerita();
      
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

  Future<void> _fetchCerita() async {
    try {
      String query = '''
        *,
        author:author_id(full_name),
        kelas:kelas_id(tingkat, jurusan),
        tanggapan_count:tanggapan_cerita(count)
      ''';
      
      var request = supabase
          .from('cerita_kelas')
          .select(query)
          .filter('kelas_id', 'in', _kelasList.map((k) => k['id']).toList())
          .order('created_at', ascending: false);
      
      final response = await request;
      List<Map<String, dynamic>> allCerita = (response as List).map((item) => item as Map<String, dynamic>).toList();
      
      // Apply search filter client-side
      List<Map<String, dynamic>> filteredCerita = allCerita;
      
      if (_searchQuery.isNotEmpty) {
        filteredCerita = filteredCerita.where((cerita) {
          final judul = cerita['judul']?.toString().toLowerCase() ?? '';
          final konten = cerita['konten']?.toString().toLowerCase() ?? '';
          final searchLower = _searchQuery.toLowerCase();
          return judul.contains(searchLower) || konten.contains(searchLower);
        }).toList();
      }
      
      setState(() {
        _ceritaList = filteredCerita;
      });
      
    } catch (error) {
      // Error fetching cerita
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _fetchCerita();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mading Kelas'),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
      ),
      drawer: const TeacherDrawer(currentRoute: MadingKelasTeacherScreen.routeName),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _kelasList.isEmpty
              ? _buildNoClassWidget()
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: Column(
                    children: [
                      // Filter dan Search Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey[50],
                        child: Column(
                          children: [
                            // Search Bar
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Cari cerita...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          _onSearchChanged('');
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ],
                        ),
                      ),
                      
                      // Cerita List
                      Expanded(
                        child: _ceritaList.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _ceritaList.length,
                                itemBuilder: (context, index) {
                                  final cerita = _ceritaList[index];
                                  return _buildCeritaCard(cerita);
                                },
                              ),
                      ),
                    ],
                  ),
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
              'Anda Belum Menjadi Wali Kelas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Hubungi admin untuk ditugaskan sebagai wali kelas.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.article_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Cerita di Kelas Anda',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Siswa belum berbagi cerita di kelas yang Anda wali.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCeritaCard(Map<String, dynamic> cerita) {
    final authorName = cerita['author']?['full_name'] ?? 'Unknown';
    final kelasInfo = cerita['kelas'];
    final kelasName = '${kelasInfo['tingkat']}${kelasInfo['jurusan']}';
    final timeAgo = DateTimeUtils.getTimeAgo(cerita['created_at']);
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
              builder: (context) => DetailCeritaTeacherScreen(ceritaId: cerita['id']),
            ),
          );
          if (result == true && mounted) {
            _fetchCerita();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan info author dan kelas
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
                        Row(
                          children: [
                            Icon(Icons.school, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Kelas $kelasName',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• $timeAgo',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cerita['is_published'] 
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cerita['is_published'] ? 'Published' : 'Draft',
                      style: TextStyle(
                        color: cerita['is_published'] ? Colors.green : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
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
                    'Ketuk untuk lihat & tanggapi',
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

}
