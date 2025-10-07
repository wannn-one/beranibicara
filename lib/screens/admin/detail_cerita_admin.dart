import 'package:beranibicara/services/image_download_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class DetailCeritaAdminScreen extends StatefulWidget {
  final int ceritaId;

  const DetailCeritaAdminScreen({super.key, required this.ceritaId});

  @override
  State<DetailCeritaAdminScreen> createState() =>
      _DetailCeritaAdminScreenState();
}

class _DetailCeritaAdminScreenState extends State<DetailCeritaAdminScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _cerita;
  List<Map<String, dynamic>> _tanggapanList = [];

  final _tanggapanController = TextEditingController();
  bool _isSubmittingTanggapan = false;

  late final String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = supabase.auth.currentUser!.id;
    _fetchCeritaDetail();
  }

  @override
  void dispose() {
    _tanggapanController.dispose();
    super.dispose();
  }

  Future<void> _fetchCeritaDetail() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final ceritaResponse = await supabase
          .from('cerita_kelas')
          .select('*, author:author_id(full_name), kelas:kelas_id(tingkat, jurusan)')
          .eq('id', widget.ceritaId)
          .single();

      final tanggapanResponse = await supabase
          .from('tanggapan_cerita')
          .select('*, author:author_id(full_name, role)')
          .eq('cerita_id', widget.ceritaId)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _cerita = ceritaResponse;
          _tanggapanList = tanggapanResponse;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: ${error.toString()}')),
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
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
      await _fetchCeritaDetail(); // Refresh to show new comment
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal mengirim tanggapan: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingTanggapan = false);
      }
    }
  }

  Future<void> _togglePublishStatus() async {
    if (_cerita == null) return;

    try {
      final newStatus = !_cerita!['is_published'];
      
      await supabase
          .from('cerita_kelas')
          .update({'is_published': newStatus})
          .eq('id', widget.ceritaId);

      if (mounted) {
        setState(() {
          _cerita!['is_published'] = newStatus;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'Cerita berhasil dipublikasikan' : 'Cerita berhasil disembunyikan'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status publikasi: ${error.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Cerita'),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
        actions: [
          if (_cerita != null)
            IconButton(
              icon: Icon(_cerita!['is_published'] ? Icons.visibility_off : Icons.visibility),
              onPressed: _togglePublishStatus,
              tooltip: _cerita!['is_published'] ? 'Sembunyikan Cerita' : 'Publikasikan Cerita',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cerita == null
              ? const Center(child: Text('Cerita tidak ditemukan.'))
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _fetchCeritaDetail,
                        child: ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: [
                            _buildCeritaContent(),
                            const SizedBox(height: 24),
                            _buildTanggapanSection(),
                          ],
                        ),
                      ),
                    ),
                    _buildTanggapanForm(),
                  ],
                ),
    );
  }

  Widget _buildCeritaContent() {
    final authorName = _cerita!['author']?['full_name'] ?? 'Siswa';
    final kelasInfo = _cerita!['kelas'];
    final kelasName = kelasInfo != null ? '${kelasInfo['tingkat']}${kelasInfo['jurusan']}' : 'Unknown';
    final createdAt = DateTime.parse(_cerita!['created_at']);
    final formattedDate = DateFormat('EEEE, d MMMM yyyy, HH:mm').format(createdAt);
    final hasImage = _cerita!['gambar_url'] != null;
    final isPublished = _cerita!['is_published'] ?? false;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF36A395),
                  child: Text(
                    authorName.isNotEmpty ? authorName[0].toUpperCase() : 'S',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
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
                            '• $formattedDate',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPublished 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPublished ? 'Published' : 'Draft',
                    style: TextStyle(
                      color: isPublished ? Colors.green : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _cerita!['judul'] ?? 'Tanpa Judul',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _cerita!['konten'] ?? '',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            if (hasImage) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _showFullScreenImage(context, _cerita!['gambar_url']),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
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
          const Center(child: Text('Belum ada tanggapan.'))
        else
          ...(_tanggapanList.map((t) => _buildTanggapanCard(t))),
      ],
    );
  }

  Widget _buildTanggapanCard(Map<String, dynamic> tanggapan) {
    final authorName = tanggapan['author']?['full_name'] ?? 'User';
    final authorRole = tanggapan['author']?['role'] ?? '';
    final createdAt = DateTime.parse(tanggapan['created_at']);
    final timeAgo = _getTimeAgo(createdAt);
    
    String roleBadge;
    Color roleColor;

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
                    authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
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
                          Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              roleBadge,
                              style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      Text(timeAgo, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(tanggapan['tanggapan'] ?? '', style: const TextStyle(fontSize: 14, height: 1.4)),
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
            blurRadius: 5,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _tanggapanController,
              decoration: InputDecoration(
                hintText: 'Tulis tanggapan sebagai admin...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            onPressed: _isSubmittingTanggapan ? null : _submitTanggapan,
            backgroundColor: const Color(0xFF36A395),
            foregroundColor: Colors.white,
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

void _showFullScreenImage(BuildContext context, String imageUrl) {
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
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator(color: Colors.white)),
                errorWidget: (context, url, error) =>
                    const Center(child: Icon(Icons.error, color: Colors.white)),
              ),
            ),
          ),
        );
      },
    ),
  );
}
