import 'package:flutter/foundation.dart';
import 'package:edtech_app/models/content_model.dart';

class RankingService {
  /// Ranks a list of Content items by comparing them to a search query
  /// and weighting them based on the user's category scores and popularity.
  List<Content> rankContent(
    List<Content> items,
    String query,
    Map<String, double> userCategoryScores,
  ) {
    // Map common abbreviations to full terms
    final Map<String, String> commonAbbreviations = {
      'dsa': 'data structures and algorithms',
      'ml': 'machine learning',
      'ai': 'artificial intelligence',
      'ui': 'user interface',
      'ux': 'user experience',
      'db': 'database',
      'js': 'javascript',
      'ts': 'typescript',
      'html': 'hyper text markup language',
      'css': 'cascading style sheets',
      'api': 'application programming interface',
    };

    String normalizedQuery = query.toLowerCase();

    // Replace whole words that are abbreviations
    commonAbbreviations.forEach((abbr, fullTerm) {
      normalizedQuery = normalizedQuery.replaceAll(
        RegExp('\\b$abbr\\b'),
        fullTerm,
      );
    });

    // Split query into lowercase search terms/tokens
    final List<String> queryTokens = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((token) => token.trim().isNotEmpty)
        .toList();

    // Filter out YouTube Shorts entirely so they don't appear in results
    final filteredItems = items.where((item) {
      if (item.source == 'youtube') {
        if (item.contentType == 'short') return false;
        final urlLower = item.url.toLowerCase();
        final titleLower = item.title.toLowerCase();
        if (urlLower.contains('/shorts/') || titleLower.contains('shorts')) {
          return false;
        }
      }
      return true;
    }).toList();

    // Remove non-English content to keep recommendations universal
    final englishOnlyItems = filteredItems.where((item) {
      final combined = '${item.title.toLowerCase()} ${item.description.toLowerCase()}';
      final List<String> englishIndicators = [
        ' the ',
        ' and ',
        ' is ',
        ' in ',
        ' to ',
        ' for ',
        ' of ',
        ' a ',
        ' an ',
        ' with ',
        ' on ',
      ];
      return englishIndicators.any((w) => combined.contains(w));
    }).toList();

    final scoredItems = englishOnlyItems.map((item) {
      double score = 0.0;

      final titleLower = item.title.toLowerCase();
      final descLower = item.description.toLowerCase();

      // 1. Text Relevance (Keyword Matching)
      for (final token in queryTokens) {
        if (titleLower.contains(token)) {
          score += 5.0;
        }
        if (descLower.contains(token)) {
          score += 1.0;
        }
      }

      // 2. Personalization (Category Affinity Boost)
      final double categoryBoost = userCategoryScores[item.category] ?? 0.0;
      score += categoryBoost;

      // 3. Popularity Score (breaks ties and favors higher-rated content)
      score += item.popularityScore;

      // 4. Educational content boost: prefer tutorials/guides/courses
      final List<String> eduKeywords = [
        'tutorial',
        'how to',
        'how-to',
        'learn',
        'course',
        'guide',
        'lesson',
        'beginner',
        'advanced',
        'walkthrough',
        'tutorials',
      ];
      final bool isEducational = eduKeywords.any(
        (k) => titleLower.contains(k) || descLower.contains(k),
      );
      // Give a meaningful boost for clearly educational items
      if (isEducational || item.contentType == 'course') {
        score += 4.0;
      }

      // 4b. Abbreviation-based boost: prefer items mentioning common abbreviations
      final bool hasAbbreviation = commonAbbreviations.keys.any((abbr) {
        final pattern = RegExp('\\b${RegExp.escape(abbr)}\\b');
        return pattern.hasMatch(titleLower) || pattern.hasMatch(descLower);
      });
      if (hasAbbreviation) {
        score += 2.5;
      }
      // 4c. eduKeywords-based boost: prefer items mentioning educational keywords
      final bool hasEduKeyword = eduKeywords.any((keyword) {
        final pattern = RegExp('\\b${RegExp.escape(keyword.toLowerCase())}\\b');
        return pattern.hasMatch(titleLower) || pattern.hasMatch(descLower);
      });

      if (hasEduKeyword) {
        score += 2.5;
      }

      // 5. English language heuristic boost
      // Simple heuristic: presence of common English stopwords
      final combined = '${titleLower} ${descLower}';
      final List<String> englishIndicators = [
        ' the ',
        ' and ',
        ' is ',
        ' in ',
        ' to ',
        ' for ',
        ' of ',
        ' a ',
        ' an ',
        ' with ',
        ' on ',
      ];
      final bool looksEnglish = englishIndicators.any(
        (w) => combined.contains(w),
      );
      if (looksEnglish) {
        score += 2.5;
      }

      // Debug: print final computed score for visibility during development
      debugPrint(
        'Ranking debug: id=${item.id}, source=${item.source}, score=${score.toStringAsFixed(3)}, edu=$isEducational, english=$looksEnglish, pop=${item.popularityScore}, catBoost=${categoryBoost.toStringAsFixed(3)}',
      );

      return MapEntry(item, score);
    }).toList();

    // Sort descending by calculated score
    scoredItems.sort((a, b) => b.value.compareTo(a.value));

    // Map back to just Content objects
    return scoredItems.map((entry) => entry.key).toList();
  }
}
