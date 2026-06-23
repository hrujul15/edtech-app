class UserModel {
  final String uid;
  final String name;
  final String email;
  final List<String> interests;
  final Map<String, double> categoryScores;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.interests,
    required this.categoryScores,
  });

  /// Convert UserModel instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'interests': interests,
      'categoryScores': categoryScores,
    };
  }

  /// Create UserModel instance from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      interests: List<String>.from(json['interests'] as List),
      categoryScores: Map<String, double>.from(
        (json['categoryScores'] as Map).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
      ),
    );
  }

  /// Create a copy of UserModel with modified fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    List<String>? interests,
    Map<String, double>? categoryScores,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      interests: interests ?? this.interests,
      categoryScores: categoryScores ?? this.categoryScores,
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, name: $name, email: $email, interests: $interests)';
}
