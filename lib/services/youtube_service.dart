import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/content_model.dart';

class YouTubeService {
  // Key is loaded from the .env file at runtime
  String get _apiKey => dotenv.env['YOUTUBE_API_KEY'] ?? '';

  // Simple memory cache to save API quota during development
  final Map<String, List<Content>> _cache = {};

  Future<List<Content>> searchYouTube(String query) async {
    if (_cache.containsKey(query)) {
      return _cache[query]!;
    }

    if (_apiKey.isEmpty || _apiKey == 'YOUR_YOUTUBE_API_KEY_HERE') {
      debugPrint('Warning: YOUTUBE_API_KEY is not set in your .env file.');
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

        final videoIds = <String>[];
        final snippets = <String, Map<String, dynamic>>{};

        for (final item in items) {
          final snippet = item['snippet'] ?? {};
          final videoId = item['id']?['videoId'] as String? ?? '';
          if (videoId.isNotEmpty) {
            videoIds.add(videoId);
            snippets[videoId] = snippet as Map<String, dynamic>;
          }
        }

        final Map<String, int> durationsSec = {};
        final Map<String, int> viewsMap = {};
        final Map<String, int> likesMap = {};
        if (videoIds.isNotEmpty) {
          final idsParam = videoIds.join(',');
          final detailsUrl = Uri.parse(
            'https://www.googleapis.com/youtube/v3/videos?part=contentDetails,statistics&id=$idsParam&key=$_apiKey',
          );

          final detailsResponse = await http.get(detailsUrl);
          if (detailsResponse.statusCode == 200) {
            final Map<String, dynamic> detailsData = json.decode(
              detailsResponse.body,
            );
            final List<dynamic> detailsItems = detailsData['items'] ?? [];
            for (final detailsItem in detailsItems) {
              final id = detailsItem['id'] as String? ?? '';
              final durationIso =
                  detailsItem['contentDetails']?['duration'] as String? ?? '';
              if (id.isNotEmpty && durationIso.isNotEmpty) {
                durationsSec[id] = _parseIsoDurationToSeconds(durationIso);
              }

              final stats = detailsItem['statistics'] ?? {};

              viewsMap[id] =
                  int.tryParse(stats['viewCount']?.toString() ?? '0') ?? 0;

              likesMap[id] =
                  int.tryParse(stats['likeCount']?.toString() ?? '0') ?? 0;
            }
          }
        }

        final results = <Content>[];
        for (final videoId in videoIds) {
          final snippet = snippets[videoId] ?? {};
          final thumbnails = snippet['thumbnails'] ?? {};
          final thumbnail =
              thumbnails['high']?['url'] ??
              thumbnails['medium']?['url'] ??
              thumbnails['default']?['url'] ??
              '';
          final duration = durationsSec[videoId] ?? 0;
          final bool isShort = duration > 0 && duration < 60;
          final views = viewsMap[videoId] ?? 0;
          final likes = likesMap[videoId] ?? 0;

          results.add(
            Content(
              id: 'youtube_$videoId',
              title: snippet['title'] as String? ?? '',
              description: snippet['description'] as String? ?? '',
              thumbnail: thumbnail,
              source: 'youtube',
              contentType: isShort ? 'short' : 'video',
              url: 'https://youtube.com/watch?v=$videoId',
              category: query,
              popularityScore: 0.35 + log(likes + 1) / (10 * log(views + 1)),
            ),
          );
        }

        _cache[query] = results;
        return results;
      } else {
        throw Exception(
          'YouTube API error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('YouTube search error: $e');
      return [];
    }
  }

  int _parseIsoDurationToSeconds(String iso) {
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(iso);
    if (match == null) return 0;
    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
    return hours * 3600 + minutes * 60 + seconds;
  }
}
