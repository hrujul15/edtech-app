import 'package:flutter/material.dart';
import 'package:edtech_app/models/content_model.dart';
import 'package:edtech_app/services/auth_service.dart';
import 'package:edtech_app/services/firestore_service.dart';
import 'package:edtech_app/widgets/content_card.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({Key? key}) : super(key: key);

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  List<Content> _savedItems = [];

  @override
  void initState() {
    super.initState();
    _loadSavedContent();
  }

  /// Fetch all saved content for the current user from Firestore
  Future<void> _loadSavedContent() async {
    final uid = _authService.currentUid;
    if (uid == null) return;

    try {
      final items = await _firestoreService.getSavedContent(uid);
      if (mounted) {
        setState(() {
          _savedItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved content: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Delete a saved item via swipe or long-press
  Future<void> _deleteSavedItem(Content content) async {
    final uid = _authService.currentUid;
    if (uid == null) return;

    try {
      await _firestoreService.deleteSavedContent(uid, content.id);
      if (mounted) {
        setState(() {
          _savedItems.removeWhere((item) => item.id == content.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed "${content.title}"')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting saved content: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete item')),
        );
      }
    }
  }

  /// Show confirmation dialog on long press
  void _onLongPress(Content content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove saved item?'),
        content: Text('Delete "${content.title}" from your saved list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteSavedItem(content);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: _savedItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No saved content yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadSavedContent,
              child: ListView.builder(
                itemCount: _savedItems.length,
                itemBuilder: (context, index) {
                  final content = _savedItems[index];
                  return Dismissible(
                    key: Key(content.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => _deleteSavedItem(content),
                    child: GestureDetector(
                      onLongPress: () => _onLongPress(content),
                      child: ContentCard(
                        content: content,
                        onSave: () {}, // Already saved — no-op
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
