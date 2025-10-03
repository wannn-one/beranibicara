import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:beranibicara/widgets/admin_drawer.dart';
import 'package:beranibicara/screens/admin/detail_cerita_admin.dart';
import 'package:beranibicara/screens/admin/buat_cerita_admin.dart';

final supabase = Supabase.instance.client;

class MadingKelasAdminScreen extends StatefulWidget {
  static const String routeName = '/admin-mading-kelas';
  const MadingKelasAdminScreen({super.key});

  @override
  State<MadingKelasAdminScreen> createState() => _MadingKelasAdminScreenState();
}

class _MadingKelasAdminScreenState extends State<MadingKelasAdminScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _ceritaList = [];
  List<Map<String, dynamic>> _kelasList = [];
  int? _selectedKelasId;
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
      // Fetch semua kelas (exclude admin kelas)
      final kelasResponse = await supabase
          .from('kelas')
          .select('id, tingkat, jurusan')
          .neq('tingkat', 99)
          .neq('jurusan', 'X')
          .order('tingkat', ascending: true)
          .order('jurusan', ascending: true);
      
      setState(() {
        _kelasList = (kelasResponse as List).map((item) => item as Map<String, dynamic>).toList();
      });
      
      // Fetch cerita
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
          .order('created_at', ascending: false);
      
      final response = await request;
      List<Map<String, dynamic>> allCerita = (response as List).map((item) => item as Map<String, dynamic>).toList();
      
      // Apply filters client-side
      List<Map<String, dynamic>> filteredCerita = allCerita;
      
      // Filter by kelas jika dipilih
      if (_selectedKelasId != null) {
        filteredCerita = filteredCerita.where((cerita) => cerita['kelas_id'] == _selectedKelasId).toList();
      }
      
      // Filter by search query
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
      debugPrint('Error fetching cerita: $error');
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _fetchCerita();
  }

  void _onKelasChanged(int? kelasId) {
    setState(() {
      _selectedKelasId = kelasId;
    });
    _fetchCerita();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Mading Kelas'),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
      ),
      drawer: const AdminDrawer(currentRoute: MadingKelasAdminScreen.routeName),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const BuatCeritaAdminScreen(),
            ),
          );
          if (result == true && mounted) {
            _fetchCerita();
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
              color: const Color(0xFF36A395),
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
                      const SizedBox(height: 12),
                      
                      // Kelas Filter
                      Row(
                        children: [
                          // const Icon(Icons.school, color: Color(0xFF36A395)),
                          // const SizedBox(width: 8),
                          // const Text('Filter Kelas:', style: TextStyle(fontWeight: FontWeight.w500)),
                          // const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _selectedKelasId,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              hint: const Text('Filter Berdasarkan Kelas'),
                              items: [
                                const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text('Filter Berdasarkan Kelas'),
                                ),
                                ..._kelasList.map((kelas) => DropdownMenuItem<int>(
                                  value: kelas['id'],
                                  child: Text('${kelas['tingkat']}${kelas['jurusan']}'),
                                )),
                              ],
                              onChanged: _onKelasChanged,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Stats Cards
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Cerita',
                          _ceritaList.length.toString(),
                          Icons.article,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Kelas Aktif',
                          _kelasList.length.toString(),
                          Icons.school,
                          Colors.green,
                        ),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
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
            Text(
              _selectedKelasId != null 
                ? 'Belum Ada Cerita di Kelas Terpilih'
                : 'Belum Ada Cerita',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Mulai dengan menulis cerita pertama!',
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
              builder: (context) => DetailCeritaAdminScreen(ceritaId: cerita['id']),
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
                    'Ketuk untuk kelola',
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
