import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beranibicara/widgets/teacher_drawer.dart';

final supabase = Supabase.instance.client;

class TeacherStudentListScreen extends StatefulWidget {
  static const String routeName = '/teacher-student-list';
  const TeacherStudentListScreen({super.key});

  @override
  State<TeacherStudentListScreen> createState() => _TeacherStudentListScreenState();
}

class _TeacherStudentListScreenState extends State<TeacherStudentListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  String _className = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
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
          .select('id, full_name, created_at')
          .eq('kelas_id', kelasId)
          .eq('role', 'siswa')
          .order('full_name');

      final students = (siswaResponse as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();

      setState(() {
        _allStudents = students;
        _filteredStudents = students;
        _isLoading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data siswa: $error')),
        );
      }
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        final name = student['full_name']?.toLowerCase() ?? '';
        return name.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Siswa - Kelas $_className'),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
        elevation: 1.0,
      ),
      drawer: const TeacherDrawer(currentRoute: TeacherStudentListScreen.routeName),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari siswa berdasarkan nama...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                
                // Students count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'Menampilkan ${_filteredStudents.length} dari ${_allStudents.length} siswa',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Students list
                Expanded(
                  child: _filteredStudents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_search,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'Belum ada siswa di kelas ini'
                                    : 'Tidak ada siswa yang sesuai pencarian',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchStudents,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _filteredStudents.length,
                            itemBuilder: (context, index) {
                              final student = _filteredStudents[index];
                              return _buildStudentCard(student);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final createdAt = DateTime.parse(student['created_at']);
    final formattedDate = '${createdAt.day}/${createdAt.month}/${createdAt.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF36A395),
          child: Text(
            student['full_name']?.substring(0, 1).toUpperCase() ?? 'S',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student['full_name'] ?? 'Nama tidak tersedia',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Bergabung: $formattedDate',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.person,
          color: Color(0xFF36A395),
        ),
      ),
    );
  }
} 