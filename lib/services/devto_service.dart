import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/content_model.dart';

class DevToService {
  Future<List<Content>> searchDevTo(String query) async {
    final url = Uri.parse(
      'https://dev.to/api/articles?tag=${Uri.encodeComponent(query)}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception(
          'Dev.to API error ${response.statusCode}: ${response.body}',
        );
      }

      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data.map((item) {
        final Map<String, dynamic> article = item as Map<String, dynamic>;
        final int reactions = article['positive_reactions_count'] as int? ?? 0;
        final double popularityScore = (reactions / 1000).clamp(0.0, 1.0);

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
    } catch (e) {
      print('Dev.to search error: $e');
      return [];
    }
  }
}
