import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:beranibicara/services/image_download_service.dart';
import 'package:beranibicara/utils/datetime_utils.dart';

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

  final _noteController = TextEditingController();
  final _replyController = TextEditingController();
  String _selectedTahapan = 'verifikasi'; // Nilai default untuk dropdown
  bool _isAddingNote = false;
  bool _isAddingReply = false;

  @override
  void initState() {
    super.initState();
    _reportFuture = _fetchReportDetails();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchReportDetails() async {
    try {
      // Ambil data laporan dan data bukti secara bersamaan
      final results = await Future.wait<dynamic>([
        supabase
            .from('reports')
            .select('*, profiles(full_name, kelas:kelas_id(tingkat, jurusan))')
            .eq('id', widget.reportId)
            .single(),
        
        supabase.from('evidence').select('file_url').eq('report_id', widget.reportId),

        supabase
          .from('log_penanganan')
          .select('*, author:author_id(full_name)') // Join dengan profil penulis catatan
          .eq('report_id', widget.reportId)
          .order('created_at', ascending: false),

        // Fetch replies to student
        supabase
          .from('balasan_laporan')
          .select('*, author:author_id(full_name)')
          .eq('report_id', widget.reportId)
          .order('created_at', ascending: false),
      ]);

      final reportData = results[0] as Map<String, dynamic>;
      final evidenceData = (results[1] as List).map((item) => item as Map<String, dynamic>).toList();
      final logData = (results[2] as List).cast<Map<String, dynamic>>();
      final repliesData = (results[3] as List).cast<Map<String, dynamic>>();

      // Gabungkan data bukti ke dalam data laporan
      reportData['evidence'] = evidenceData;
      reportData['log_penanganan'] = logData;
      reportData['replies'] = repliesData;

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

  Future<void> _addHandlingLog() async {
  if (_noteController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Catatan tidak boleh kosong')),
    );
    return;
  }
  
  setState(() { _isAddingNote = true; });

  try {
    await supabase.from('log_penanganan').insert({
      'report_id': widget.reportId,
      'author_id': supabase.auth.currentUser!.id,
      'catatan': _noteController.text.trim(),
      'tahapan': _selectedTahapan,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan baru berhasil ditambahkan!')),
      );
      _noteController.clear();
      // Refresh seluruh data untuk menampilkan catatan baru
      setState(() {
        _reportFuture = _fetchReportDetails();
      });
    }
  } catch (error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan catatan: $error')),
      );
    }
  } finally {
    if (mounted) {
      setState(() { _isAddingNote = false; });
    }
    }
}

  Future<void> _addReply() async {
    if (_replyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Balasan tidak boleh kosong')),
      );
      return;
    }
    
    setState(() { _isAddingReply = true; });

    try {
      final insertedReply = await supabase.from('balasan_laporan').insert({
        'report_id': widget.reportId,
        'author_id': supabase.auth.currentUser!.id,
        'pesan': _replyController.text.trim(),
      }).select().single();

      // Panggil Edge Function untuk kirim notifikasi ke siswa
      try {
        
        // Manual format untuk memastikan data clean
        final cleanReplyData = {
          'id': insertedReply['id'],
          'report_id': insertedReply['report_id'],
          'author_id': insertedReply['author_id'],
          'pesan': insertedReply['pesan'],
          'created_at': insertedReply['created_at'],
        };
        
        await supabase.functions.invoke('send-reply-notification', body: {
          'record': cleanReplyData
        });
      } catch (notifError) {
        // Don't fail the whole process if notification fails
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Balasan berhasil dikirim ke siswa!')),
        );
        _replyController.clear();
        // Refresh seluruh data untuk menampilkan balasan baru
        setState(() {
          _reportFuture = _fetchReportDetails();
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim balasan: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isAddingReply = false; });
      }
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

  Widget _buildLogsList(List logs) {
  if (logs.isEmpty) {
    return const Text('Belum ada catatan penanganan.');
  }
  
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: logs.length,
    itemBuilder: (context, index) {
      final log = logs[index];
      final formattedDate = DateTimeUtils.formatUtcToIndonesian(log['created_at']);

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(log['catatan']),
          subtitle: Text(
            'Oleh: ${log['author']['full_name']} • $formattedDate\n'
            'Tahap: ${log['tahapan'].toUpperCase()}',
          ),
          isThreeLine: true,
        ),
      );
    },
  );
}

Widget _buildRepliesList(List replies) {
  if (replies.isEmpty) {
    return const Text('Belum ada balasan yang dikirim ke siswa.');
  }
  
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: replies.length,
    itemBuilder: (context, index) {
      final reply = replies[index];
      final formattedDate = DateTimeUtils.formatUtcToIndonesian(reply['created_at']);

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(Icons.reply, color: Colors.blue[600]),
          title: Text(reply['pesan']),
          subtitle: Text(
            'Oleh: ${reply['author']['full_name']} • $formattedDate',
          ),
        ),
      );
    },
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: const Text('Bukti Laporan'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () async {
                    await ImageDownloadService.downloadImage(
                      context,
                      url,
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
                child: _buildFullScreenRealImage(url),
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildFullScreenRealImage(String url) {
    
    return CachedNetworkImage(
      imageUrl: url,
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
            SizedBox(height: 8),
            Text(
              'Periksa koneksi internet',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
      // High quality for full screen viewing - no size limit for original size
      memCacheWidth: null,
      memCacheHeight: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _showDeleteReportDialog,
            tooltip: 'Hapus Laporan',
          ),
        ],
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
          final isAnonymous = report['is_anonymous'] ?? false;
          final reporterName = isAnonymous ? 'Anonim' : (report['profiles']?['full_name'] ?? 'Unknown');
          final formattedDate = DateTimeUtils.formatUtcToIndonesian(
            report['created_at'], 
            pattern: 'EEEE, d MMMM yyyy, HH:mm'
          );
          final evidenceList = report['evidence'] as List;
          
          // Get class information if available
          String? kelasInfo;
          if (report['profiles']?['kelas'] != null) {
            final kelas = report['profiles']['kelas'];
            kelasInfo = '${kelas['tingkat']}${kelas['jurusan']}';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Pelapor:', reporterName),
                if (kelasInfo != null)
                  _buildDetailRow('Kelas:', kelasInfo),
                _buildDetailRow('Tanggal:', formattedDate),
                
                const Divider(height: 32),
                
                _buildDetailRow('Judul Laporan:', report['title'] ?? 'Tanpa Judul'),
                _buildDetailRow('Deskripsi Kejadian:', report['description']),
                
                if (evidenceList.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('Bukti Terlampir:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: evidenceList.map((evidence) {
                      return _buildEvidenceItem(evidence['file_url']);
                    }).toList(),
                  ),
                ],

                const Divider(height: 32),

                // --- BAGIAN BALASAN KE SISWA ---
                const Text('Balasan ke Siswa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildRepliesList(report['replies'] as List),

                const SizedBox(height: 16),
                const Text('Kirim Balasan Baru ke Siswa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _replyController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Tulis balasan untuk siswa di sini...',
                    border: OutlineInputBorder(),
                    helperText: 'Balasan ini akan dilihat oleh siswa yang melaporkan',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isAddingReply ? null : _addReply,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                  child: _isAddingReply 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Kirim Balasan ke Siswa'),
                ),

                const Divider(height: 32),

                // --- BAGIAN RIWAYAT PENANGANAN ---
                const Text('Riwayat Penanganan (Log)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildLogsList(report['log_penanganan'] as List), // Panggil fungsi bantuan

                const Divider(height: 32),

                const Text('Tambah Catatan Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Tahapan: '),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedTahapan,
                      items: ['verifikasi', 'mediasi', 'rehabilitasi', 'lainnya']
                          .map((tahap) => DropdownMenuItem(value: tahap, child: Text(tahap.toUpperCase())))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() { _selectedTahapan = value; });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Tulis catatan penanganan di sini...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isAddingNote ? null : _addHandlingLog,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF36A395),
                    foregroundColor: Colors.white,
                  ),
                  child: _isAddingNote ? const CircularProgressIndicator() : const Text('Tambah Catatan'),
                ),

                const Divider(height: 32),
                
                const Text('Ubah Status Laporan:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
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
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF36A395),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simpan Perubahan Status'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aksi Moderasi Lainnya',
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
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteReportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Laporan'),
          content: const Text(
              'Apakah Anda yakin ingin menghapus laporan ini? Tindakan ini tidak dapat dibatalkan dan akan menghapus semua data terkait, termasuk bukti dan log penanganan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await supabase.rpc('delete_report_completely', params: {
                    'report_id_to_delete': widget.reportId,
                  });

                  if (mounted && context.mounted) {
                    Navigator.pop(context); // Close the dialog
                    Navigator.pop(context, true); // Go back to the previous screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Laporan berhasil dihapus.')),
                    );
                  }
                } catch (error) {
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Gagal menghapus laporan: $error')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markAsFalseReport() async {
    // Show confirmation dialog
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
        // 1. Add a log entry
        await supabase.from('log_penanganan').insert({
          'report_id': widget.reportId,
          'author_id': supabase.auth.currentUser!.id,
          'catatan': 'Laporan ditandai sebagai laporan palsu oleh admin.',
          'tahapan': 'lainnya',
        });

        // 2. Update the status to 'ditolak'
        await supabase
            .from('reports')
            .update({'status': 'ditolak'})
            .eq('id', widget.reportId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Laporan telah ditandai sebagai palsu.')),
          );
          // Refresh the details to show the new status and log
          setState(() {
            _reportFuture = _fetchReportDetails();
          });
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
}
