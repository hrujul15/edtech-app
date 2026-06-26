import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edtech_app/models/content_model.dart';

class CacheService {
  static const int cacheHours = 12; // change to 24 if you prefer

  // Save results for a category
  Future<void> saveCategoryResults(String category, List<Content> items) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'items': items.map((e) => e.toJson()).toList(),
    };
    await prefs.setString('cache_$category', jsonEncode(data));
  }

  // Get cached results for a category, returns null if expired or missing
  Future<List<Content>?> getCategoryResults(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cache_$category');
    if (raw == null) return null;

    final data = jsonDecode(raw);
    final savedAt = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
    final isExpired = DateTime.now().difference(savedAt).inHours >= cacheHours;

    if (isExpired) {
      await prefs.remove('cache_$category'); // clean up expired cache
      return null;
    }

    return (data['items'] as List).map((e) => Content.fromJson(e)).toList();
  }

  // Call this if user changes interests — wipe everything
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
