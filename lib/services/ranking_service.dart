import 'package:edtech_app/models/content_model.dart';

class RankingService {
  /// Ranks a list of Content items by comparing them to a search query
  /// and weighting them based on the user's category scores and popularity.
  List<Content> rankContent(
    List<Content> items,
    String query,
    Map<String, double> userCategoryScores,
    // Map common abbreviations to full terms
    final Map<String, String> commonAbbreviations = {
      'dsa': 'data structure algorithm',
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
      normalizedQuery = normalizedQuery.replaceAll(RegExp('\\b$abbr\\b'), fullTerm);
    });

    // Split query into lowercase search terms/tokens
    final List<String> queryTokens = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((token) => token.trim().isNotEmpty)
        .toList();

    final scoredItems = items.map((item) {
      double score = 0.0;

      final titleLower = item.title.toLowerCase();
      final descLower = item.description.toLowerCase();

      // 1. Text Relevance (Keyword Matching)
      for (final token in queryTokens) {
        // Title match gets high weight (3 points per matched token)
        if (titleLower.contains(token)) {
          score += 3.0;
        }
        // Description match gets lower weight (1 point per matched token)
        if (descLower.contains(token)) {
          score += 1.0;
        }
      }

      // 2. Personalization (Category Affinity Boost)
      // Boost the content if it matches categories the user has interacted with/selected
      final double categoryBoost = userCategoryScores[item.category] ?? 0.0;
      score += categoryBoost;

      // 3. Popularity Score (breaks ties and favors higher-rated content)
      score += item.popularityScore;

      return MapEntry(item, score);
    }).toList();

    // Sort descending by calculated score
    scoredItems.sort((a, b) => b.value.compareTo(a.value));

    // Map back to just Content objects
    return scoredItems.map((entry) => entry.key).toList();
  }
}
