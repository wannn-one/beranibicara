/// Domain Entity for Balasan Laporan (Report Reply)
/// 
/// Represents a reply/message in a report conversation between
/// reporter (student) and TPPK.
class BalasanLaporan {
  final int id;
  final int reportId;
  final String authorId;
  final String pesan;
  final DateTime createdAt;

  // Derived properties for UI
  final String? authorName;
  final String? authorRole;

  const BalasanLaporan({
    required this.id,
    required this.reportId,
    required this.authorId,
    required this.pesan,
    required this.createdAt,
    this.authorName,
    this.authorRole,
  });

  /// Check if current user is the author of this reply
  bool isAuthor(String userId) => authorId == userId;

  /// Check if reply is from TPPK
  bool get isFromTppk => authorRole == 'tppk';

  /// Check if reply is recent (within last 5 minutes)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inMinutes < 5;
  }

  /// Format created_at for display
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      final local = createdAt.toLocal();
      return '${local.day}/${local.month}/${local.year}';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BalasanLaporan &&
        other.id == id &&
        other.reportId == reportId &&
        other.authorId == authorId &&
        other.pesan == pesan &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        reportId.hashCode ^
        authorId.hashCode ^
        pesan.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'BalasanLaporan(id: $id, reportId: $reportId, authorId: $authorId, pesan: $pesan, createdAt: $createdAt)';
  }
}
