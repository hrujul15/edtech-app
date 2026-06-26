import 'package:youtube_transcript_api/youtube_transcript_api.dart';
import '../models/content_model.dart';

class TranscriptService {
  /// Fetches a YouTube transcript for the given [videoId] and returns it as
  /// a plain String ready to pass to Gemini.
  /// Falls back to auto-generated captions if no manual transcript exists.
  Future<String> getYouTubeTranscript(String videoId) async {
    final api = YouTubeTranscriptApi();
    try {
      // Strip any "youtube_" prefix if present
      final cleanId = videoId.startsWith('youtube_')
          ? videoId.substring('youtube_'.length)
          : videoId;

      final snippets = await api.fetch(cleanId, languages: ['en']);
      return snippets.map((s) => s.text).join(' ');
    } catch (e) {
      print('Error fetching YouTube transcript: $e');
      return '';
    } finally {
      api.dispose();
    }
  }

  /// Combines the title and description from a Dev.to [Content] object into
  /// a plain String ready to pass to Gemini.
  String getArticleText(Content content) {
    return '${content.title}\n\n${content.description}';
  }
}
