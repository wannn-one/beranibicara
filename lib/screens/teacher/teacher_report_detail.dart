import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:beranibicara/services/image_download_service.dart';

final supabase = Supabase.instance.client;

class TeacherReportDetailScreen extends StatefulWidget {
  final int reportId;

  const TeacherReportDetailScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<TeacherReportDetailScreen> createState() => _TeacherReportDetailScreenState();
}

class _TeacherReportDetailScreenState extends State<TeacherReportDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    _fetchReportDetail();
  }

  Future<void> _fetchReportDetail() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await supabase
          .from('reports')
          .select('*, profiles(full_name), evidence(file_url)')
          .eq('id', widget.reportId)
          .single();

      setState(() {
        _reportData = response;
        _isLoading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat detail laporan: $error')),
        );
      }
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

  Widget _buildEvidenceItem(String url) {
    return GestureDetector(
      onTap: () => _showFullScreenEvidence(url),
      child: Container(
        width: 120,
        height: 120,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF36A395), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: url,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF36A395),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Loading...',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 120,
                  height: 120,
                  color: Colors.red.shade100,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.red, size: 24),
                      SizedBox(height: 4),
                      Text(
                        'Gagal memuat',
                        style: TextStyle(color: Colors.red, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Overlay untuk menunjukkan bahwa bisa di-tap
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF36A395),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.zoom_in,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenEvidence(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: const Text('Bukti Gambar'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () async {
                    await ImageDownloadService.downloadImage(
                      context,
                      imageUrl,
                      customFileName: 'bukti_laporan_${DateTime.now().millisecondsSinceEpoch}.jpg',
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
                        SizedBox(height: 8),
                        Text(
                          'Periksa koneksi internet',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
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
        title: const Text('Detail Laporan'),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportData == null
              ? const Center(
                  child: Text('Laporan tidak ditemukan'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_reportData!['status']).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(_reportData!['status']),
                          ),
                        ),
                        child: Text(
                          _getStatusText(_reportData!['status']),
                          style: TextStyle(
                            color: _getStatusColor(_reportData!['status']),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        'Judul Laporan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _reportData!['title'] ?? 'Tanpa Judul',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Reporter Info
                      Text(
                        'Dilaporkan oleh',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _reportData!['is_anonymous'] == true
                            ? 'Anonim'
                            : (_reportData!['profiles']?['full_name'] ?? 'Unknown'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),

                      // Date
                      Text(
                        'Tanggal Laporan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('d MMMM yyyy, HH:mm').format(
                          DateTime.parse(_reportData!['created_at']),
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),

                      // Description
                      Text(
                        'Deskripsi Kejadian',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          _reportData!['description'] ?? 'Tidak ada deskripsi',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Evidence Images
                      if (_reportData!['evidence'] != null && 
                          (_reportData!['evidence'] as List).isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF36A395).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF36A395).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.photo_library,
                                color: Color(0xFF36A395),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Bukti Gambar (Tap untuk memperbesar)',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF36A395),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: (_reportData!['evidence'] as List).map((evidence) {
                              return _buildEvidenceItem(evidence['file_url']);
                            }).toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Text(
                        'Aksi Moderasi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _markAsFalseReport,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          foregroundColor: Colors.amber.shade800,
                          side: BorderSide(color: Colors.amber.shade800),
                        ),
                        icon: const Icon(Icons.flag),
                        label: const Text('Tandai Sebagai Laporan Palsu'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _deleteReport,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Hapus Laporan (Tidak Pantas)'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _markAsFalseReport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Anda yakin ingin menandai laporan ini sebagai laporan palsu? Status akan diubah menjadi DITOLAK.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, Tandai'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await supabase
            .from('reports')
            .update({'status': 'ditolak'})
            .eq('id', widget.reportId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Laporan telah ditandai sebagai palsu.')),
          );
          _fetchReportDetail();
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menandai laporan: $error')),
          );
        }
      }
    }
  }

  Future<void> _deleteReport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Laporan'),
        content: const Text('Anda yakin ingin menghapus laporan ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await supabase.rpc('delete_report_completely', params: {
          'report_id_to_delete': widget.reportId,
        });

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Laporan berhasil dihapus.')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus laporan: $error')),
          );
        }
      }
    }
  }
}
