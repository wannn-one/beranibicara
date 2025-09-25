import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:beranibicara/widgets/student_drawer.dart';
import 'package:beranibicara/screens/student/socialization_detail.dart';

final supabase = Supabase.instance.client;

class SocializationListScreen extends StatefulWidget {
  static const String routeName = '/student-socialization';
  const SocializationListScreen({super.key});

  @override
  State<SocializationListScreen> createState() => _SocializationListScreenState();
}

class _SocializationListScreenState extends State<SocializationListScreen> {
  late Future<List<Map<String, dynamic>>> _contentFuture;
  List<Map<String, dynamic>> _allContent = [];
  List<Map<String, dynamic>> _filteredContent = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _contentFuture = _fetchContent();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchContent() async {
    try {
      final response = await supabase
          .from('socialization')
          .select('*, profiles(full_name)')
          .order('published_at', ascending: false);

      final content = (response as List).map((item) => item as Map<String, dynamic>).toList();
      
      setState(() {
        _allContent = content;
        _filteredContent = content;
      });
      
      return content;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data konten: $error')),
        );
      }
      return [];
    }
  }

  void _searchContent(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContent = _allContent;
      } else {
        _filteredContent = _allContent.where((content) {
          final title = content['title']?.toString().toLowerCase() ?? '';
          final contentText = content['content']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return title.contains(searchLower) || contentText.contains(searchLower);
        }).toList();
      }
    });
  }

  void _refreshContent() {
    setState(() {
      _contentFuture = _fetchContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sosialisasi & Edukasi'),
        backgroundColor: const Color(0xFF36A395),
        foregroundColor: Colors.white,
        elevation: 1.0,
      ),
      drawer: const StudentDrawer(currentRoute: SocializationListScreen.routeName),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari konten sosialisasi...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _searchContent,
            ),
          ),
          
          // Content List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _contentFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshContent,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (_filteredContent.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty 
                              ? 'Belum ada konten sosialisasi'
                              : 'Tidak ada konten yang sesuai pencarian',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _refreshContent(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _filteredContent.length,
                    itemBuilder: (context, index) {
                      final content = _filteredContent[index];
                      final publishedAt = DateTime.parse(content['published_at'] ?? content['created_at']);
                      final formattedDate = DateFormat('d MMM yyyy, HH:mm').format(publishedAt);
                      final authorName = content['profiles']?['full_name'] ?? 'TPPK';
                      final coverImageUrl = content['cover_image_url'] as String?;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SocializationDetailScreen(content: content),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            children: [
                              // Cover Image
                              if (coverImageUrl != null)
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: coverImageUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                                ),
                              
                              // Content
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(16).copyWith(
                                    left: coverImageUrl != null ? 0 : 16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        content['title'] ?? 'Tanpa Judul',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF36A395),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        content['content'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const CircleAvatar(
                                            backgroundColor: Color(0xFF36A395),
                                            radius: 12,
                                            child: Icon(Icons.person, size: 14, color: Colors.white),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  authorName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Text(
                                                  formattedDate,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Color(0xFF36A395),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
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
} 