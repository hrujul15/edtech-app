class Content {
  final String id;
  final String title;
  final String description;
  final String thumbnail;
  final String source; // 'youtube' or 'devto'
  final String contentType; // 'video', 'article', etc.
  final String url;
  final String category;
  final double popularityScore;

  Content({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.source,
    required this.contentType,
    required this.url,
    required this.category,
    required this.popularityScore,
  });

  /// Convert Content instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'source': source,
      'contentType': contentType,
      'url': url,
      'category': category,
      'popularityScore': popularityScore,
    };
  }

  /// Create Content instance from JSON
  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumbnail: json['thumbnail'] as String,
      source: json['source'] as String,
      contentType: json['contentType'] as String,
      url: json['url'] as String,
      category: json['category'] as String,
      popularityScore: (json['popularityScore'] as num).toDouble(),
    );
  }

  /// Create a copy of Content with modified fields
  Content copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnail,
    String? source,
    String? contentType,
    String? url,
    String? category,
    double? popularityScore,
  }) {
    return Content(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnail: thumbnail ?? this.thumbnail,
      source: source ?? this.source,
      contentType: contentType ?? this.contentType,
      url: url ?? this.url,
      category: category ?? this.category,
      popularityScore: popularityScore ?? this.popularityScore,
    );
  }

  @override
  String toString() =>
      'Content(id: $id, title: $title, source: $source, category: $category)';
}
