import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edtech_app/models/content_model.dart';
import 'package:edtech_app/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save interests selected during onboarding
  Future<void> saveInterests(String uid, List<String> interests) async {
    await _firestore.collection('users').doc(uid).update({
      'interests': interests,
    });
  }

  /// Fetch user profile details
  Future<UserModel> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw Exception('User profile not found in Firestore.');
    }
    return UserModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  /// Save/bookmark content under the user's savedContent subcollection
  Future<void> saveContent(String uid, Content content) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('savedContent')
        .doc(content.id)
        .set(content.toJson());
  }

  /// Retrieve all saved content for a user
  Future<List<Content>> getSavedContent(String uid) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('savedContent')
        .get();

    return querySnapshot.docs
        .map((doc) => Content.fromJson(doc.data()))
        .toList();
  }

  /// Get a real-time stream of a user's saved content IDs to check availability
  Stream<Set<String>> getSavedContentIdsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('savedContent')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  /// Get a real-time stream of a user's saved content list [loads actual content]
  Stream<List<Content>> getSavedContentStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('savedContent')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Content.fromJson(doc.data()))
            .toList());
  }

  /// Delete saved content from a user's collection
  Future<void> deleteSavedContent(String uid, String contentId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('savedContent')
        .doc(contentId)
        .delete();
  }

  /// Increment a category's popularity/preference score for a user by 1
  Future<void> updateCategoryScore(String uid, String category) async {
    // Firestore supports nested field updates and FieldValue.increment
    await _firestore.collection('users').doc(uid).update({
      'categoryScores.$category': FieldValue.increment(1.0),
    });
  }
}
