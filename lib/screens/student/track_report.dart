import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:beranibicara/services/image_download_service.dart';

final supabase = Supabase.instance.client;

class TrackingReportScreen extends StatefulWidget {
  static const String routeName = '/track-report';
  final int reportId; // Halaman ini menerima ID laporan

  const TrackingReportScreen({super.key, required this.reportId});

  @override
  State<TrackingReportScreen> createState() => _TrackingReportScreenState();
}

class _TrackingReportScreenState extends State<TrackingReportScreen> {
  late Future<Map<String, dynamic>> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _fetchReportDetails();
  }

  Future<Map<String, dynamic>> _fetchReportDetails() async {
    try {
      // Fetch report details, evidence, and replies simultaneously
      final results = await Future.wait<dynamic>([
        supabase
            .from('reports')
            .select()
            .eq('id', widget.reportId)
            .single(),
        
        // Fetch evidence images
        supabase
            .from('evidence')
            .select('file_url')
            .eq('report_id', widget.reportId),
        
        // Fetch replies from admin
        supabase
            .from('balasan_laporan')
            .select('*, author:author_id(full_name)')
            .eq('report_id', widget.reportId)
            .order('created_at', ascending: true), // Show oldest first for conversation flow
      ]);

      final reportData = results[0] as Map<String, dynamic>;
      final evidenceData = (results[1] as List).cast<Map<String, dynamic>>();
      final repliesData = (results[2] as List).cast<Map<String, dynamic>>();

      // Add evidence and replies to report data
      reportData['evidence'] = evidenceData;
      reportData['replies'] = repliesData;

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

  /// Mengubah status string menjadi indeks untuk Stepper
  int _getStatusIndex(String status) {
    switch (status) {
      case 'baru':
        return 0;
      case 'diproses':
        return 1;
      case 'selesai':
      case 'ditolak':
        return 2;
      default:
        return 0;
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

  Widget _buildRepliesList(List replies) {
    if (replies.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Belum ada balasan dari tim TPPK.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: replies.map((reply) {
        final replyDate = DateTime.parse(reply['created_at']);
        final formattedDate = DateFormat('d MMM yyyy, HH:mm').format(replyDate);
        final authorName = reply['author']['full_name'] ?? 'Tim TPPK';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.blue[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[600],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Text(
                    reply['pesan'],
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Laporan Anda'),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
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
          final status = report['status'];
          final currentStep = _getStatusIndex(status);
          final reportDate = DateTime.parse(report['created_at']);
          final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(reportDate);
          final replies = report['replies'] as List;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Laporan tanggal: $formattedDate', 
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            report['title'] ?? 'Laporan Tanpa Judul', 
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            report['description'], 
                            style: const TextStyle(fontSize: 14, color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Evidence Images Section
                if (report['evidence'] != null && (report['evidence'] as List).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF36A395).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF36A395).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.photo_library,
                          color: Color(0xFF36A395),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Bukti Gambar (Tap untuk memperbesar)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF36A395),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      children: (report['evidence'] as List).map((evidence) {
                        return _buildEvidenceItem(evidence['file_url']);
                      }).toList(),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Stepper untuk menampilkan progres status
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stepper(
                      currentStep: currentStep,
                      controlsBuilder: (context, details) => const SizedBox.shrink(), // Sembunyikan tombol default
                      steps: [
                        Step(
                          title: const Text('Laporan Diterima'),
                          subtitle: const Text('Laporan Anda sudah masuk ke sistem.'),
                          content: const SizedBox.shrink(),
                          isActive: currentStep >= 0,
                          state: currentStep > 0 ? StepState.complete : StepState.indexed,
                        ),
                        Step(
                          title: const Text('Laporan Diproses'),
                          subtitle: const Text('Tim TPPK sedang meninjau dan memverifikasi laporan Anda.'),
                          content: const SizedBox.shrink(),
                          isActive: currentStep >= 1,
                          state: currentStep > 1 ? StepState.complete : StepState.indexed,
                        ),
                        Step(
                          title: Text(status == 'ditolak' ? 'Laporan Ditolak' : 'Laporan Selesai'),
                          subtitle: Text(
                            status == 'ditolak'
                              ? 'Laporan Anda tidak dapat diproses lebih lanjut.'
                              : 'Penanganan untuk laporan Anda telah selesai.',
                          ),
                          content: const SizedBox.shrink(),
                          isActive: currentStep >= 2,
                          // Ubah state menjadi error jika statusnya ditolak
                          state: status == 'ditolak' ? StepState.error : StepState.complete,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Bagian Balasan dari Tim TPPK
                const Text(
                  'Balasan dari Tim TPPK',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRepliesList(replies),

                if (replies.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.green[600], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Jika Anda memiliki pertanyaan lebih lanjut, silakan hubungi guru atau tim TPPK secara langsung.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}