import 'package:flutter/material.dart';
import 'package:edtech_app/models/content_model.dart';


class ContentCard extends StatelessWidget {
  final Content content;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback? onTap;

  const ContentCard({
    super.key,
    required this.content,
    this.isSaved = false,
    required this.onSave,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Image
            if (content.thumbnail.isNotEmpty)
              Image.network(
                content.thumbnail,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(height: 180, color: Colors.grey),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source & Content Type Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _sourceIcon(content.source),
                            size: 16,
                            color: _sourceColor(content.source),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _sourceLabel(content.source),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      // Bookmark Button
                      IconButton(
                        icon: Icon(isSaved
                            ? Icons.bookmark
                            : Icons.bookmark_border),
                        color: isSaved ? Colors.blue : null,
                        onPressed: onSave,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    content.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Description snippet
                  if (content.description.isNotEmpty)
                    Text(
                      content.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _sourceIcon(String source) {
    switch (source) {
      case 'youtube':
        return Icons.play_circle_fill;
      case 'wikipedia':
        return Icons.public;
      case 'openlibrary':
        return Icons.menu_book;
      default:
        return Icons.article;
    }
  }

  static Color _sourceColor(String source) {
    switch (source) {
      case 'youtube':
        return Colors.red;
      case 'wikipedia':
        return Colors.grey.shade700;
      case 'openlibrary':
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  static String _sourceLabel(String source) {
    switch (source) {
      case 'youtube':
        return 'YOUTUBE';
      case 'devto':
        return 'DEV.TO';
      case 'wikipedia':
        return 'WIKIPEDIA';
      case 'openlibrary':
        return 'BOOK';
      default:
        return source.toUpperCase();
    }
  }
}