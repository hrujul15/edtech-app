import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/content_model.dart';

class YouTubeService {
  // Key is loaded from the .env file at runtime — never hardcoded.
  String get _apiKey => dotenv.env['YOUTUBE_API_KEY'] ?? '';

  Future<List<Content>> searchYouTube(String query) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_YOUTUBE_API_KEY_HERE') {
      print('Warning: YOUTUBE_API_KEY is not set in your .env file.');
      return [];
    }

    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search'
      '?part=snippet'
      '&q=${Uri.encodeComponent(query)}'
      '&type=video'
      '&maxResults=10'
      '&key=$_apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        return items.map((item) {
          final snippet = item['snippet'] ?? {};
          final videoId = item['id']['videoId'] as String? ?? '';
          final thumbnails = snippet['thumbnails'] ?? {};
          final thumbnail =
              thumbnails['high']?['url'] ??
              thumbnails['medium']?['url'] ??
              thumbnails['default']?['url'] ??
              '';

          return Content(
            id: 'youtube_$videoId',
            title: snippet['title'] as String? ?? '',
            description: snippet['description'] as String? ?? '',
            thumbnail: thumbnail,
            source: 'youtube',
            contentType: 'video',
            url: 'https://youtube.com/watch?v=$videoId',
            category: query,
            popularityScore: 0.5,
          );
        }).toList();
      } else {
        throw Exception(
          'YouTube API error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('YouTube search error: $e');
      return [];
    }
  }
}