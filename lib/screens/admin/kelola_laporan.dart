import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:beranibicara/screens/widgets/admin_drawer.dart';
import 'package:beranibicara/screens/admin/detail_laporan.dart';

final supabase = Supabase.instance.client;

class ManageReportsScreen extends StatefulWidget {
  static const String routeName = '/manage-reports';
  const ManageReportsScreen({super.key});

  @override
  State<ManageReportsScreen> createState() => _ManageReportsScreenState();
}

class _ManageReportsScreenState extends State<ManageReportsScreen> {
  late Future<List<Map<String, dynamic>>> _reportsFuture;
  List<Map<String, dynamic>> _allReports = [];
  List<Map<String, dynamic>> _filteredReports = [];
  
  // Filter state variables
  String? _selectedStatus;
  String _selectedDateRange = 'Semua';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  
  // Date range options
  final List<String> _dateRangeOptions = [
    'Semua',
    'Hari ini',
    'Minggu ini', 
    'Bulan ini',
    'Custom'
  ];

  @override
  void initState() {
    super.initState();
    _reportsFuture = _fetchReports();
  }

  // Fungsi untuk mengambil semua laporan beserta nama pelapornya
  Future<List<Map<String, dynamic>>> _fetchReports() async {
    try {
      // Ini adalah 'magic' join. Kita mengambil semua kolom dari 'reports'
      // dan kolom 'full_name' dari tabel 'profiles' yang terhubung.
      final response = await supabase
          .from('reports')
          .select('*, profiles(full_name)')
          .order('created_at', ascending: false); // Urutkan dari yang terbaru

      final realReports = (response as List).map((item) => item as Map<String, dynamic>).toList();

      _allReports = realReports;
      
      // Apply current filters
      _applyFilters();
      return _filteredReports;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data laporan: $error')),
        );
      }
      return [];
    }
  }

  // Apply filters to the reports list
  void _applyFilters() {
    _filteredReports = _allReports.where((report) {
      // Filter by status
      if (_selectedStatus != null && report['status'] != _selectedStatus) {
        return false;
      }
      
      // Filter by date range
      if (_selectedDateRange != 'Semua') {
        final reportDate = DateTime.parse(report['created_at']);
        final now = DateTime.now();
        
        switch (_selectedDateRange) {
          case 'Hari ini':
            if (!_isSameDay(reportDate, now)) return false;
            break;
          case 'Minggu ini':
            final weekAgo = now.subtract(const Duration(days: 7));
            if (reportDate.isBefore(weekAgo)) return false;
            break;
          case 'Bulan ini':
            final monthAgo = now.subtract(const Duration(days: 30));
            if (reportDate.isBefore(monthAgo)) return false;
            break;
          case 'Custom':
            if (_customStartDate != null && _customEndDate != null) {
              // Set time to start and end of day for proper comparison
              final startOfDay = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day);
              final endOfDay = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day, 23, 59, 59);
              
              if (reportDate.isBefore(startOfDay) || reportDate.isAfter(endOfDay)) {
                return false;
              }
            } else {
              // If custom is selected but dates not set, show all
              return true;
            }
            break;
        }
      }
      
      return true;
    }).toList();
  }

  // Helper method to check if two dates are on the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // Update filters and refresh the list
  void _updateFilters() {
    _applyFilters();
    // No need for setState here as it's already called from the filter widgets
  }

  // Show custom date range picker
  Future<void> _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: (_customStartDate != null && _customEndDate != null)
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedDateRange = 'Custom';
        _updateFilters();
      });
    }
  }

  // Get custom date range display text
  String _getCustomDateText() {
    if (_customStartDate != null && _customEndDate != null) {
      final startText = DateFormat('d MMM yyyy').format(_customStartDate!);
      final endText = DateFormat('d MMM yyyy').format(_customEndDate!);
      return '$startText - $endText';
    }
    return 'Pilih Periode';
  }



  // Fungsi untuk mendapatkan warna berdasarkan status
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Laporan Masuk'),
      ),
      drawer: const AdminDrawer(currentRoute: ManageReportsScreen.routeName),
      body: Column(
        children: [
          // Filter Section
          _buildFilterSection(),
          // Reports List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _reportsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Tidak ada laporan yang sesuai filter.'));
                }

                final reports = _filteredReports;

                return RefreshIndicator(
                              onRefresh: () async {
              setState(() {
                _reportsFuture = _fetchReports();
              });
            },
                  child: ListView.builder(
                    itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                // Mengambil nama dari data relasi
                final reporterName = report['profiles']?['full_name'] ?? 'Anonim';
                final reportDate = DateTime.parse(report['created_at']);
                final formattedDate = DateFormat('d MMMM yyyy, HH:mm').format(reportDate);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(report['description'], maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text('Dilaporkan oleh: $reporterName\nPada: $formattedDate'),
                    isThreeLine: true,
                    trailing: Chip(
                      label: Text(
                        report['status'],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: _getStatusColor(report['status']),
                    ),
                    onTap: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (context) => ReportDetailScreen(reportId: report['id'] as int),
                        ),
                      );
                      if (result == true && mounted) {
                        setState(() {
                          _reportsFuture = _fetchReports();
                        });
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
            ),
          ],
        ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Status Filter
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      hint: const Text('Semua Status'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Semua Status'),
                        ),
                        ...['baru', 'diproses', 'selesai', 'ditolak'].map((status) =>
                          DropdownMenuItem<String>(
                            value: status,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(status.toUpperCase()),
                              ],
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value;
                          _updateFilters();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Date Range Filter
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Periode',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _selectedDateRange,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _dateRangeOptions.map((range) =>
                        DropdownMenuItem<String>(
                          value: range,
                          child: Text(range),
                        ),
                      ).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDateRange = value!;
                          if (value == 'Custom') {
                            // Show date picker immediately when Custom is selected
                            _showCustomDatePicker();
                          } else {
                            // Clear custom dates when other option is selected
                            _customStartDate = null;
                            _customEndDate = null;
                            _updateFilters();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Custom Date Range Display
          if (_selectedDateRange == 'Custom')
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getCustomDateText(),
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _showCustomDatePicker,
                    child: const Text('Ubah'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          // Filter Summary & Clear Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filteredReports.length} dari ${_allReports.length} laporan',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (_selectedStatus != null || _selectedDateRange != 'Semua')
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = null;
                      _selectedDateRange = 'Semua';
                      _customStartDate = null;
                      _customEndDate = null;
                      _updateFilters();
                    });
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear Filter'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}