import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/content_model.dart';

class DevToService {
  final Map<String, List<Content>> _cache = {};

  Future<List<Content>> searchDevTo(String query) async {
    if (_cache.containsKey(query)) {
      return _cache[query]!;
    }
    // Try tag-based search first, then fallback to general articles if tag fails
    final tagUrl = Uri.parse(
      'https://dev.to/api/articles?search=${Uri.encodeComponent(query)}&per_page=10&page=1',
    );
    
    final generalUrl = Uri.parse(
      'https://dev.to/api/articles?per_page=10&page=1',
    );

    try {
      var response = await http.get(tagUrl).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('timeout', 408),
      );

      // If tag search fails, try general articles as fallback
      if (response.statusCode != 200) {
        response = await http.get(generalUrl).timeout(
          const Duration(seconds: 10),
          onTimeout: () => http.Response('timeout', 408),
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Dev.to API error ${response.statusCode}: ${response.body}',
        );
      }

      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      final results = data.map((item) {
        final Map<String, dynamic> article = item as Map<String, dynamic>;
        final int reactions = article['positive_reactions_count'] as int? ?? 0;
        // Scale reactions to 0-1 range using 100 as reference point
        // This gives dev.to articles comparable scoring to YouTube (0.5 base)
        final double popularityScore = ((reactions + 45) / 100).clamp(0.0, 1.0);

        return Content(
          id: 'devto_${article['id']}',
          title: article['title'] as String? ?? '',
          description: article['description'] as String? ?? '',
          thumbnail: article['cover_image'] as String? ?? '',
          source: 'devto',
          contentType: 'article',
          url: article['url'] as String? ?? '',
          category: query,
          popularityScore: popularityScore,
        );
      }).toList();

      _cache[query] = results;
      return results;
    } catch (e) {
      debugPrint('Dev.to search error: $e');
      return [];
    }
  }
}
