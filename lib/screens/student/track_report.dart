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
      final response = await supabase
          .from('reports')
          .select()
          .eq('id', widget.reportId)
          .single();
      return response;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Laporan Anda'),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Laporan tanggal: $formattedDate', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(report['description'], style: const TextStyle(fontSize: 16)),
                const Divider(height: 32),
                
                // Stepper untuk menampilkan progres status
                Stepper(
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
              ],
            ),
          );
        },
      ),
    );
  }
}