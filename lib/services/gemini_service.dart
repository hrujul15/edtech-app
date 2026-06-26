import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for calling Google Gemini API (gemini-3.5-flash).
///
/// Requires an environment variable `GEMINI_API_KEY` to be set.
class GeminiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Summarize [text] into structured markdown notes using Gemini.
  ///
  /// Returns the generated notes as a plain [String] (markdown).
  static Future<String> generateNotesFromText(String text, String title) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not set in .env.');
    }

    // Truncate to ~15 000 chars to stay within token limits
    final truncated = text.length > 15000 ? text.substring(0, 15000) : text;

    // final prompt =
    //     'Summarize the following educational content into clear, structured '
    //     'notes with headings (##) and bullet points. '
    //     'Title: $title.\n\nContent:\n$truncated';
    final prompt =
        'Summarize the following educational content into concise structured '
        'notes with headings (##) and bullet points. Be thorough but brief — '
        'aim for completeness over length. Always finish your last bullet point. '
        'Title: $title.\n\nContent:\n$truncated';
    // Gemini 1.5 Flash – generateContent endpoint
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-3.5-flash:generateContent?key=$apiKey',
    );

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 8192},
    });

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode != 200) {
      throw Exception(
        'Gemini API request failed: ${res.statusCode} ${res.body}',
      );
    }

    final Map<String, dynamic> data =
        jsonDecode(res.body) as Map<String, dynamic>;

    // Response shape: { candidates: [{ content: { parts: [{ text: "..." }] } }] }
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates != null && candidates.isNotEmpty) {
      final content =
          (candidates.first as Map<String, dynamic>)['content']
              as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts != null && parts.isNotEmpty) {
        final text = (parts.first as Map<String, dynamic>)['text'] as String?;
        if (text != null) return text;
      }
    }

    throw Exception('Unexpected Gemini response shape: ${res.body}');
  }
}
