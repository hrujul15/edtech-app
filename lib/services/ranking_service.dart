import 'package:edtech_app/models/content_model.dart';

class RankingService {
  /// Common abbreviations used in education/tech.
  /// Used both for query expansion AND for boosting matching items.
  static const Map<String, String> commonAbbreviations = {
    'dsa': 'data structures and algorithms',
    'ml': 'machine learning',
    'ai': 'artificial intelligence',
    'dl': 'deep learning',
    'nlp': 'natural language processing',
    'cv': 'computer vision',
    'rl': 'reinforcement learning',
    'ui': 'user interface',
    'ux': 'user experience',
    'db': 'database',
    'dbms': 'database management system',
    'os': 'operating system',
    'oop': 'object oriented programming',
    'cn': 'computer networks',
    'js': 'javascript',
    'ts': 'typescript',
    'py': 'python',
    'html': 'hypertext markup language',
    'css': 'cascading style sheets',
    'api': 'application programming interface',
    'sdk': 'software development kit',
    'ci': 'continuous integration',
    'cd': 'continuous deployment',
    'devops': 'development operations',
    'sql': 'structured query language',
    'nosql': 'non relational database',
    'aws': 'amazon web services',
    'gcp': 'google cloud platform',
    'k8s': 'kubernetes',
    'tf': 'tensorflow',
    'react': 'react javascript',
    'jwt': 'json web token',
    'rest': 'representational state transfer',
    'graphql': 'graph query language',
  };

  /// Expand a user query by replacing abbreviations with full terms.
  /// Returns the expanded query string — useful for sending to APIs too.
  static String expandQuery(String query) {
    String normalized = query.toLowerCase().trim();
    commonAbbreviations.forEach((abbr, fullTerm) {
      normalized = normalized.replaceAllMapped(
        RegExp('\\b${RegExp.escape(abbr)}\\b', caseSensitive: false),
        (match) => '$abbr $fullTerm', // keep abbreviation + add full term
      );
    });
    return normalized;
  }

  /// Educational keywords that signal high-quality learning content.
  static const List<String> _eduKeywords = [
    'tutorial',
    'how to',
    'how-to',
    'learn',
    'course',
    'guide',
    'lesson',
    'beginner',
    'intermediate',
    'advanced',
    'walkthrough',
    'explained',
    'introduction',
    'intro to',
    'fundamentals',
    'crash course',
    'cheat sheet',
    'roadmap',
    'masterclass',
    'deep dive',
  ];

  /// Common English stopwords for language detection.
  static const List<String> _englishIndicators = [
    ' the ', ' and ', ' is ', ' in ', ' to ',
    ' for ', ' of ', ' a ', ' an ', ' with ', ' on ',
  ];

  /// Ranks a list of Content items by relevance to the search query,
  /// user preferences, content quality, and popularity.
  List<Content> rankContent(
    List<Content> items,
    String query,
    Map<String, double> userCategoryScores,
  ) {
    // 1. Expand abbreviations in the query
    final expandedQuery = expandQuery(query);
    final queryTokens = expandedQuery
        .split(RegExp(r'\s+'))
        .where((t) => t.trim().isNotEmpty)
        .toSet() // deduplicate
        .toList();

    // 2. Filter out YouTube Shorts
    final filtered = items.where((item) {
      if (item.source == 'youtube') {
        if (item.contentType == 'short') return false;
        if (item.url.toLowerCase().contains('/shorts/')) return false;
      }
      return true;
    }).toList();

    // 3. Keep only English-looking content
    final english = filtered.where((item) {
      final text = '${item.title.toLowerCase()} ${item.description.toLowerCase()}';
      return _englishIndicators.any((w) => text.contains(w));
    }).toList();

    // 4. Score each item
    final scored = english.map((item) {
      double score = 0.0;
      final titleLower = item.title.toLowerCase();
      final descLower = item.description.toLowerCase();

      // --- Exact title match (highest signal) ---
      if (titleLower == query.toLowerCase()) {
        score += 20.0;
      } else if (titleLower.contains(query.toLowerCase())) {
        score += 10.0;
      }

      // --- Token matching (title worth 5x description) ---
      for (final token in queryTokens) {
        if (token.length < 2) continue; // skip tiny tokens
        if (titleLower.contains(token)) score += 5.0;
        if (descLower.contains(token)) score += 1.0;
      }

      // --- Category affinity boost ---
      final categoryBoost = userCategoryScores[item.category] ?? 0.0;
      score += categoryBoost;

      // --- Popularity ---
      score += item.popularityScore;

      // --- Educational content boost ---
      final isEducational = _eduKeywords.any(
        (k) => titleLower.contains(k) || descLower.contains(k),
      );
      if (isEducational) score += 4.0;

      // --- Source diversity bonus ---
      // Wikipedia and books get a small boost to ensure they appear
      // (since YouTube and Dev.to usually have more items)
      if (item.source == 'wikipedia') score += 2.0;
      if (item.source == 'openlibrary') score += 1.5;

      return MapEntry(item, score);
    }).toList();

    // 5. Sort by score descending
    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.map((e) => e.key).toList();
  }
}
