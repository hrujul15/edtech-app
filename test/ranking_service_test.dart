import 'package:flutter_test/flutter_test.dart';
import 'package:edtech_app/models/content_model.dart';
import 'package:edtech_app/services/ranking_service.dart';

void main() {
  group('RankingService Tests', () {
    final rankingService = RankingService();

    final content1 = Content(
      id: '1',
      title: 'Learn Flutter Programming',
      description: 'An introductory video on Flutter mobile development.',
      thumbnail: '',
      source: 'youtube',
      contentType: 'video',
      url: '',
      category: 'Programming',
      popularityScore: 0.5,
    );

    final content2 = Content(
      id: '2',
      title: 'Advanced Dart Development',
      description: 'Learn programming concepts in Dart.',
      thumbnail: '',
      source: 'devto',
      contentType: 'article',
      url: '',
      category: 'Programming',
      popularityScore: 0.8,
    );

    final content3 = Content(
      id: '3',
      title: 'Introduction to Calculus',
      description: 'Learn fundamental math concepts.',
      thumbnail: '',
      source: 'youtube',
      contentType: 'video',
      url: '',
      category: 'Math',
      popularityScore: 0.6,
    );

    test('should rank by keyword matches (title is weighted higher than description)', () {
      final items = [content1, content2, content3];
      // "programming" matches:
      // content1 title -> 3 points
      // content2 description -> 1 point
      // content3 -> 0 points
      final ranked = rankingService.rankContent(items, 'programming', {});

      expect(ranked[0].id, '1'); // 3.0 + 0.5 = 3.5 score
      expect(ranked[1].id, '2'); // 1.0 + 0.8 = 1.8 score
      expect(ranked[2].id, '3'); // 0.0 + 0.6 = 0.6 score
    });

    test('should apply category boost based on user category scores', () {
      final items = [content1, content2, content3];
      // "Learn" matches:
      // content1 title -> 3.0 + 0.5 pop = 3.5
      // content2 description -> 1.0 + 0.8 pop = 1.8
      // content3 description -> 1.0 + 0.6 pop = 1.6
      
      // Let's add a large category boost for Math (category of content3)
      final userScores = {'Math': 5.0};
      
      // With boost, content3 gets: 1.0 (text match) + 5.0 (boost) + 0.6 (pop) = 6.6
      // content1 gets: 3.0 (text match) + 0.0 (boost) + 0.5 (pop) = 3.5
      final ranked = rankingService.rankContent(items, 'Learn', userScores);

      expect(ranked[0].id, '3'); // 6.6 score (first)
      expect(ranked[1].id, '1'); // 3.5 score (second)
      expect(ranked[2].id, '2'); // 1.8 score (third)
    });
  });
}
