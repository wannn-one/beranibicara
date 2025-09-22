import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

final supabase = Supabase.instance.client;

// Custom cache manager for evidence images with optimized settings
class EvidenceCacheManager extends CacheManager {
  static const key = 'evidence_cache';
  
  static EvidenceCacheManager? _instance;
  
  factory EvidenceCacheManager() {
    _instance ??= EvidenceCacheManager._();
    return _instance!;
  }
  
  EvidenceCacheManager._() : super(
    Config(
      key,
      stalePeriod: const Duration(days: 7), // Cache for 7 days
      maxNrOfCacheObjects: 200, // Maximum 200 cached images
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

class ReportDetailScreen extends StatefulWidget {
  final int reportId;
  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late Future<Map<String, dynamic>> _reportFuture;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _reportFuture = _fetchReportDetails();
  }

  Future<Map<String, dynamic>> _fetchReportDetails() async {
    try {
      // Ambil data laporan dan data bukti secara bersamaan
      final results = await Future.wait<dynamic>([
        supabase
            .from('reports')
            .select('*, profiles(full_name), kelas:kelas_id(tingkat, jurusan)')
            .eq('id', widget.reportId)
            .single(),
        supabase.from('evidence').select('file_url').eq('report_id', widget.reportId),
      ]);

      final reportData = results[0] as Map<String, dynamic>;
      final evidenceData = (results[1] as List).map((item) => item as Map<String, dynamic>).toList();
      
      reportData['evidence'] = evidenceData; // Gabungkan data bukti ke dalam data laporan
      setState(() {
        _selectedStatus = reportData['status'];
      });
      return reportData;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat detail laporan: $error')),
        );
      }
      rethrow;
    }
  }


  
  Future<void> _updateStatus() async {
    try {
      await supabase
          .from('reports')
          .update({'status': _selectedStatus})
          .eq('id', widget.reportId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status berhasil diperbarui!')),
        );
        // Kirim 'true' kembali ke halaman sebelumnya untuk menandakan ada perubahan
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui status: $error')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Gagal memuat data.'));
          }

          final report = snapshot.data!;
          final reporterName = report['profiles']?['full_name'] ?? 'Anonim';
          final reportDate = DateTime.parse(report['created_at']);
          final formattedDate = DateFormat('EEEE, d MMMM yyyy, HH:mm').format(reportDate);
          final evidenceList = report['evidence'] as List;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Pelapor:', reporterName),
                _buildDetailRow('Tanggal:', formattedDate),
                const Divider(height: 32),
                _buildDetailRow('Deskripsi Kejadian:', report['description']),
                
                if (evidenceList.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('Bukti Terlampir:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: evidenceList.map((evidence) {
                      return _buildEvidenceItem(evidence['file_url']);
                    }).toList(),
                  ),
                ],

                const Divider(height: 32),
                
                const Text('Ubah Status Laporan:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  items: ['baru', 'diproses', 'selesai', 'ditolak']
                      .map((status) => DropdownMenuItem(value: status, child: Text(status.toUpperCase())))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() { _selectedStatus = value; });
                    }
                  },
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _updateStatus,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: const Text('Simpan Perubahan Status'),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildEvidenceItem(String url) {
    return GestureDetector(
      onTap: () => _showFullScreenEvidence(url),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 100,
                height: 100,
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 100,
                height: 100,
                color: Colors.red.shade100,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 16),
                    SizedBox(height: 4),
                    Text(
                      'Error',
                      style: TextStyle(color: Colors.red, fontSize: 8),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }



  void _showFullScreenEvidence(String url) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Full screen evidence container
              Container(
                width: double.infinity,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildFullScreenRealImage(url),
              ),
              // Close button
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildFullScreenRealImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: url,
        width: double.infinity,
        height: 400,
        fit: BoxFit.contain,
        cacheManager: EvidenceCacheManager(),
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
        // High quality for full screen viewing
        memCacheWidth: 800,
        memCacheHeight: 800,
      ),
    );
  }


}