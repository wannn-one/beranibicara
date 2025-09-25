import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/widgets/teacher_drawer.dart';
import 'package:beranibicara/widgets/teacher_report_card.dart';

final supabase = Supabase.instance.client;

class TeacherReportListScreen extends StatefulWidget {
  static const String routeName = '/teacher-report-list';
  const TeacherReportListScreen({super.key});

  @override
  State<TeacherReportListScreen> createState() => _TeacherReportListScreenState();
}

class _TeacherReportListScreenState extends State<TeacherReportListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allReports = [];
  List<Map<String, dynamic>> _filteredReports = [];
  String _className = '';
  
  // Filter controllers
  String _selectedStatus = 'semua';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _statusOptions = [
    {'value': 'semua', 'label': 'Semua Status'},
    {'value': 'baru', 'label': 'Baru'},
    {'value': 'diproses', 'label': 'Diproses'},
    {'value': 'selesai', 'label': 'Selesai'},
    {'value': 'ditolak', 'label': 'Ditolak'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchReports();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final teacherId = supabase.auth.currentUser!.id;
      
      // Get class info first
      final kelasResponse = await supabase
          .from('kelas')
          .select('id, tingkat, jurusan')
          .eq('wali_kelas_id', teacherId)
          .single();

      final kelasId = kelasResponse['id'];
      final tingkat = kelasResponse['tingkat'];
      final jurusan = kelasResponse['jurusan'];
      _className = '$tingkat $jurusan';

      // Get all students in the class
      final siswaResponse = await supabase
          .from('profiles')
          .select('id')
          .eq('kelas_id', kelasId)
          .eq('role', 'siswa');

      final siswaIds = (siswaResponse as List)
          .map((item) => item['id'])
          .toList();

      // Get all reports from students in the class
      List<Map<String, dynamic>> reports = [];
      if (siswaIds.isNotEmpty) {
        final laporanResponse = await supabase
            .from('reports')
            .select('*, profiles(full_name)')
            .inFilter('reporter_id', siswaIds)
            .order('created_at', ascending: false);

        reports = (laporanResponse as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }

      setState(() {
        _allReports = reports;
        _filteredReports = reports;
        _isLoading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data laporan: $error')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredReports = _allReports.where((report) {
        // Status filter
        if (_selectedStatus != 'semua' && report['status'] != _selectedStatus) {
          return false;
        }

        // Date filter
        final reportDate = DateTime.parse(report['created_at']);
        if (_startDate != null && reportDate.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && reportDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
          return false;
        }

        // Text search filter
        final query = _searchController.text.toLowerCase();
        if (query.isNotEmpty) {
          final reporterName = report['profiles']?['full_name']?.toLowerCase() ?? '';
          final category = report['category']?.toLowerCase() ?? '';
          final description = report['description']?.toLowerCase() ?? '';
          
          if (!reporterName.contains(query) && 
              !category.contains(query) && 
              !description.contains(query)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyFilters();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _applyFilters();
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'baru':
        return 'Baru';
      case 'diproses':
        return 'Diproses';
      case 'selesai':
        return 'Selesai';
      case 'ditolak':
        return 'Ditolak';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan Siswa - Kelas $_className'),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
        elevation: 1.0,
      ),
      drawer: const TeacherDrawer(currentRoute: TeacherReportListScreen.routeName),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filters section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Search bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari berdasarkan nama, kategori, atau deskripsi...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Filter row
                      Row(
                        children: [
                          // Status filter
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8
                                ),
                              ),
                              items: _statusOptions.map((status) {
                                return DropdownMenuItem<String>(
                                  value: status['value'],
                                  child: Text(status['label']!),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value!;
                                });
                                _applyFilters();
                              },
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Date filter button
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              onPressed: _selectDateRange,
                              icon: const Icon(Icons.date_range),
                              label: Text(
                                _startDate != null && _endDate != null
                                    ? '${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}'
                                    : 'Pilih Tanggal',
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 12
                                ),
                              ),
                            ),
                          ),
                          
                          // Clear date filter
                          if (_startDate != null || _endDate != null)
                            IconButton(
                              onPressed: _clearDateFilter,
                              icon: const Icon(Icons.clear),
                              tooltip: 'Hapus filter tanggal',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Reports count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'Menampilkan ${_filteredReports.length} dari ${_allReports.length} laporan',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Reports list
                Expanded(
                  child: _filteredReports.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.report_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _allReports.isEmpty
                                    ? 'Belum ada laporan dari siswa'
                                    : 'Tidak ada laporan yang sesuai filter',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchReports,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _filteredReports.length,
                            itemBuilder: (context, index) {
                              final report = _filteredReports[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TeacherReportCard(laporan: report),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
} 