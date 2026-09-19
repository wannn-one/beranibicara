import 'package:flutter/material.dart';
import 'package:beranibicara/features/reports/domain/entities/evidence.dart';

/// File Preview Widget - displays evidence file previews
class FilePreviewWidget extends StatelessWidget {
  final Evidence evidence;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showDelete;

  const FilePreviewWidget({
    super.key,
    required this.evidence,
    this.onTap,
    this.onDelete,
    this.showDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Stack(
          children: [
            // Preview based on file type
            Center(
              child: _buildPreview(),
            ),

            // Delete button
            if (showDelete && onDelete != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    switch (evidence.fileType) {
      case FileType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            evidence.fileUrl,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackIcon(Icons.image, 'Image');
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
          ),
        );

      case FileType.video:
        return _buildFallbackIcon(Icons.videocam, 'Video');

      case FileType.audio:
        return _buildFallbackIcon(Icons.audiotrack, 'Audio');

      case FileType.document:
        return _buildFallbackIcon(Icons.description, 'Document');
    }
  }

  Widget _buildFallbackIcon(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

/// File Preview List Widget - horizontal scrollable list of evidence files
class FilePreviewListWidget extends StatelessWidget {
  final List<Evidence> evidenceList;
  final Function(Evidence)? onTap;
  final Function(Evidence)? onDelete;
  final bool showDelete;

  const FilePreviewListWidget({
    super.key,
    required this.evidenceList,
    this.onTap,
    this.onDelete,
    this.showDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    if (evidenceList.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: evidenceList.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final evidence = evidenceList[index];
          return FilePreviewWidget(
            evidence: evidence,
            onTap: onTap != null ? () => onTap!(evidence) : null,
            onDelete: onDelete != null ? () => onDelete!(evidence) : null,
            showDelete: showDelete,
          );
        },
      ),
    );
  }
}
