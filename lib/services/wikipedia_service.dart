import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/content_model.dart';

class WikipediaService {
  final Map<String, List<Content>> _cache = {};

  /// Search Wikipedia and return results as Content objects.
  /// Uses the Wikipedia REST API for summaries.
  Future<List<Content>> searchWikipedia(String query) async {
    if (_cache.containsKey(query)) {
      return _cache[query]!;
    }

    try {
      // Use the Wikipedia search API to find relevant pages
      final searchUrl = Uri.parse(
        'https://en.wikipedia.org/w/api.php'
        '?action=query'
        '&list=search'
        '&srsearch=${Uri.encodeComponent(query)}'
        '&srlimit=5'
        '&format=json'
        '&origin=*',
      );

      final searchResponse = await http
          .get(searchUrl)
          .timeout(const Duration(seconds: 10));

      if (searchResponse.statusCode != 200) {
        throw Exception('Wikipedia search error: ${searchResponse.statusCode}');
      }

      final searchData = json.decode(searchResponse.body);
      final List<dynamic> searchResults =
          searchData['query']?['search'] as List<dynamic>? ?? [];

      final results = <Content>[];

      for (final result in searchResults) {
        final title = result['title'] as String? ?? '';
        final pageId = result['pageid'] as int? ?? 0;
        // Strip HTML tags from the snippet
        final rawSnippet = result['snippet'] as String? ?? '';
        final snippet = rawSnippet.replaceAll(RegExp(r'<[^>]*>'), '');

        // Fetch thumbnail from page images API
        String thumbnail = '';
        try {
          final thumbUrl = Uri.parse(
            'https://en.wikipedia.org/w/api.php'
            '?action=query'
            '&titles=${Uri.encodeComponent(title)}'
            '&prop=pageimages'
            '&pithumbsize=400'
            '&format=json'
            '&origin=*',
          );
          final thumbResponse = await http
              .get(thumbUrl)
              .timeout(const Duration(seconds: 5));
          if (thumbResponse.statusCode == 200) {
            final thumbData = json.decode(thumbResponse.body);
            final pages = thumbData['query']?['pages'] as Map<String, dynamic>?;
            if (pages != null && pages.isNotEmpty) {
              final page = pages.values.first as Map<String, dynamic>;
              thumbnail = page['thumbnail']?['source'] as String? ?? '';
            }
          }
        } catch (_) {
          // Thumbnail fetch failed; continue without it
        }

        results.add(Content(
          id: 'wiki_$pageId',
          title: title,
          description: snippet,
          thumbnail: thumbnail,
          source: 'wikipedia',
          contentType: 'article',
          url: 'https://en.wikipedia.org/wiki/${Uri.encodeComponent(title.replaceAll(' ', '_'))}',
          category: query,
          popularityScore: 0.6, // Wikipedia is generally high-quality
        ));
      }

      _cache[query] = results;
      return results;
    } catch (e) {
      debugPrint('Wikipedia search error: $e');
      return [];
    }
  }
}
