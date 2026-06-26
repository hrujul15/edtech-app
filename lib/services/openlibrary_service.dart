import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/content_model.dart';

class OpenLibraryService {
  final Map<String, List<Content>> _cache = {};

  /// Search Open Library for free books/ebooks related to the query.
  /// Returns results as Content objects with links to readable pages.
  Future<List<Content>> searchBooks(String query) async {
    if (_cache.containsKey(query)) {
      return _cache[query]!;
    }

    try {
      final url = Uri.parse(
        'https://openlibrary.org/search.json'
        '?q=${Uri.encodeComponent(query)}'
        '&limit=8'
        '&fields=key,title,author_name,cover_i,first_sentence,edition_count,subject',
      );

      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Open Library error: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final List<dynamic> docs = data['docs'] as List<dynamic>? ?? [];

      final results = docs.map((doc) {
        final title = doc['title'] as String? ?? 'Untitled';
        final authors = (doc['author_name'] as List<dynamic>?)
                ?.map((a) => a.toString())
                .take(2)
                .join(', ') ??
            'Unknown Author';
        final coverId = doc['cover_i'] as int?;
        final thumbnail = coverId != null
            ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
            : '';
        final firstSentence =
            (doc['first_sentence'] as List<dynamic>?)?.firstOrNull?.toString() ?? '';
        final description = firstSentence.isNotEmpty
            ? firstSentence
            : 'By $authors';
        final workKey = doc['key'] as String? ?? '';
        final editionCount = doc['edition_count'] as int? ?? 1;
        // Popularity based on edition count (more editions = more popular)
        final popularityScore = (editionCount / 100).clamp(0.0, 1.0);

        return Content(
          id: 'book_${workKey.replaceAll('/', '_')}',
          title: title,
          description: description,
          thumbnail: thumbnail,
          source: 'openlibrary',
          contentType: 'book',
          url: 'https://openlibrary.org$workKey',
          category: query,
          popularityScore: popularityScore,
        );
      }).toList();

      _cache[query] = results;
      return results;
    } catch (e) {
      debugPrint('Open Library search error: $e');
      return [];
    }
  }
}
