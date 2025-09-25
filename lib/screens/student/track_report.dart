import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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
      // Fetch report details and replies simultaneously
      final results = await Future.wait<dynamic>([
        supabase
            .from('reports')
            .select()
            .eq('id', widget.reportId)
            .single(),
        
        // Fetch replies from admin
        supabase
            .from('balasan_laporan')
            .select('*, author:author_id(full_name)')
            .eq('report_id', widget.reportId)
            .order('created_at', ascending: true), // Show oldest first for conversation flow
      ]);

      final reportData = results[0] as Map<String, dynamic>;
      final repliesData = (results[1] as List).cast<Map<String, dynamic>>();

      // Add replies to report data
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