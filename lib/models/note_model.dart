class NoteModel {
  final String id;
  final String title;
  final String content;
  final String sourceUrl;
  final String sourceType; // 'youtube' or 'devto'
  final DateTime createdAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.sourceUrl,
    required this.sourceType,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'sourceUrl': sourceUrl,
      'sourceType': sourceType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      sourceUrl: json['sourceUrl'] as String,
      sourceType: json['sourceType'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? sourceUrl,
    String? sourceType,
    DateTime? createdAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceType: sourceType ?? this.sourceType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'NoteModel(id: $id, title: $title, sourceType: $sourceType, createdAt: $createdAt)';
}
