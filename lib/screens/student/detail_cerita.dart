import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:beranibicara/services/image_download_service.dart';

final supabase = Supabase.instance.client;

class DetailCeritaScreen extends StatefulWidget {
  final int ceritaId;
  
  const DetailCeritaScreen({super.key, required this.ceritaId});

  @override
  State<DetailCeritaScreen> createState() => _DetailCeritaScreenState();
}

class _DetailCeritaScreenState extends State<DetailCeritaScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _cerita;
  List<Map<String, dynamic>> _tanggapanList = [];
  
  final _tanggapanController = TextEditingController();
  bool _isSubmittingTanggapan = false;
  
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _fetchCeritaDetail();
  }

  @override
  void dispose() {
    _tanggapanController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUser() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      // final userResponse = await supabase
      //     .from('profiles')
      //     .select('role')
      //     .eq('id', userId)
      //     .single();
      
      setState(() {
        _currentUserId = userId;
      });
    } catch (e) {
      debugPrint('Error getting current user: $e');
    }
  }

  Future<void> _fetchCeritaDetail() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch cerita
      final ceritaResponse = await supabase
          .from('cerita_kelas')
          .select('''
            *,
            author:author_id(full_name),
            kelas:kelas_id(tingkat, jurusan)
          ''')
          .eq('id', widget.ceritaId)
          .single();
      
      // Fetch tanggapan
      final tanggapanResponse = await supabase
          .from('tanggapan_cerita')
          .select('''
            *,
            author:author_id(full_name, role)
          ''')
          .eq('cerita_id', widget.ceritaId)
          .order('created_at', ascending: true);
      
      setState(() {
        _cerita = ceritaResponse;
        _tanggapanList = (tanggapanResponse as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      });
      
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

  Future<void> _submitTanggapan() async {
    final tanggapan = _tanggapanController.text.trim();
    if (tanggapan.isEmpty) return;
    
    setState(() => _isSubmittingTanggapan = true);
    
    try {
      await supabase.from('tanggapan_cerita').insert({
        'cerita_id': widget.ceritaId,
        'author_id': _currentUserId,
        'tanggapan': tanggapan,
      });
      
      _tanggapanController.clear();
      await _fetchCeritaDetail(); // Refresh untuk melihat tanggapan baru
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tanggapan berhasil dikirim!')),
        );
      }
      
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim tanggapan: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingTanggapan = false);
      }
    }
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: const Text('Gambar Cerita'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () async {
                    await ImageDownloadService.downloadImage(
                      context,
                      imageUrl,
                      customFileName: 'cerita_${DateTime.now().millisecondsSinceEpoch}.jpg',
                    );
                  },
                ),
              ],
            ),
            body: Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Memuat gambar...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.white, size: 60),
                        SizedBox(height: 16),
                        Text(
                          'Gagal memuat gambar',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Cerita'),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCeritaDetail,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cerita == null
              ? const Center(child: Text('Cerita tidak ditemukan'))
              : Column(
                  children: [
                    // Konten cerita
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          _buildCeritaContent(),
                          const SizedBox(height: 24),
                          _buildTanggapanSection(),
                        ],
                      ),
                    ),
                    
                    // Form tanggapan
                    _buildTanggapanForm(),
                  ],
                ),
    );
  }

  Widget _buildCeritaContent() {
    final authorName = _cerita!['author']?['full_name'] ?? 'Unknown';
    final createdAt = DateTime.parse(_cerita!['created_at']);
    final formattedDate = DateFormat('EEEE, d MMMM yyyy, HH:mm').format(createdAt);
    final hasImage = _cerita!['gambar_url'] != null;
    
    return Card(
      elevation: 2,
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
                        formattedDate,
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
              _cerita!['judul'] ?? 'Tanpa Judul',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Konten cerita
            Text(
              _cerita!['konten'] ?? '',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            
            // Gambar jika ada
            if (hasImage) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _showFullScreenImage(_cerita!['gambar_url']),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: _cerita!['gambar_url'],
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 250,
                          color: Colors.grey[300],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 250,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.zoom_in,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTanggapanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tanggapan (${_tanggapanList.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        if (_tanggapanList.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.comment_outlined, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada tanggapan',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ...(_tanggapanList.map((tanggapan) => _buildTanggapanCard(tanggapan))),
      ],
    );
  }

  Widget _buildTanggapanCard(Map<String, dynamic> tanggapan) {
    final authorName = tanggapan['author']?['full_name'] ?? 'Unknown';
    final authorRole = tanggapan['author']?['role'] ?? '';
    final createdAt = DateTime.parse(tanggapan['created_at']);
    final timeAgo = _getTimeAgo(createdAt);
    
    // Determine role badge
    String roleBadge = '';
    Color roleColor = Colors.grey;
    
    switch (authorRole) {
      case 'guru':
        roleBadge = 'Guru';
        roleColor = Colors.blue;
        break;
      case 'tppk':
        roleBadge = 'Admin';
        roleColor = Colors.purple;
        break;
      default:
        roleBadge = 'Siswa';
        roleColor = const Color(0xFF36A395);
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: roleColor,
                  child: Text(
                    authorName.isNotEmpty ? authorName[0].toUpperCase() : 'A',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            authorName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              roleBadge,
                              style: TextStyle(
                                color: roleColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tanggapan['tanggapan'] ?? '',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTanggapanForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _tanggapanController,
              decoration: InputDecoration(
                hintText: 'Tulis tanggapan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: null,
              maxLength: 1000,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                return null; // Hide counter
              },
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _isSubmittingTanggapan ? null : _submitTanggapan,
            backgroundColor: const Color(0xFF36A395),
            foregroundColor: Colors.white,
            mini: true,
            child: _isSubmittingTanggapan
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send),
          ),
        ],
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