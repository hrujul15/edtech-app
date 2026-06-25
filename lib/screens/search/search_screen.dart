import 'dart:async';
import 'package:edtech_app/models/content_model.dart';
import 'package:flutter/material.dart';
import 'package:edtech_app/services/devto_service.dart';
import 'package:edtech_app/services/ranking_service.dart';
import 'package:edtech_app/services/youtube_service.dart';
import 'package:edtech_app/widgets/content_card.dart';
import 'package:edtech_app/services/auth_service.dart';
import 'package:edtech_app/services/firestore_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final YouTubeService _youtubeService = YouTubeService();
  final DevToService _devtoService = DevToService();
  final RankingService _rankingService = RankingService();

  bool _isLoading = false;
  List<Content> _results = [];
  String _lastQuery = '';
  
  StreamSubscription<Set<String>>? _savedItemsSub;
  Set<String> _savedItemIds = {};

  @override
  void initState() {
    super.initState();
    _listenToSavedItems();
  }

  void _listenToSavedItems() {
    final uid = AuthService().currentUid;
    if (uid != null) {
      _savedItemsSub = FirestoreService().getSavedContentIdsStream(uid).listen((ids) {
        if (mounted) {
          setState(() {
            _savedItemIds = ids;
          });
        }
      });
    }
  }

  /// Toggle save content to Firestore
  Future<void> _toggleSaveContent(Content content, bool isSaved) async {
    final uid = AuthService().currentUid;
    if (uid == null) return;

    try {
      if (isSaved) {
        await FirestoreService().deleteSavedContent(uid, content.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed "${content.title}"')),
          );
        }
      } else {
        await FirestoreService().saveContent(uid, content);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved "${content.title}"')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling content: $e');
    }
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _results = [];
      _lastQuery = trimmed;
    });

    try {
      final responses = await Future.wait<List<Content>>([
        _youtubeService.searchYouTube(trimmed),
        _devtoService.searchDevTo(trimmed),
      ]);

      final combined = [...responses[0], ...responses[1]];
      final ranked = _rankingService.rankContent(combined, trimmed, {});
      setState(() {
        _results = ranked;
      });
    } catch (error) {
      debugPrint('Search error: $error');
      setState(() {
        _results = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _savedItemsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _search,
                      decoration: InputDecoration(
                        hintText: 'Search articles and videos',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () => _search(_searchController.text),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_results.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    _lastQuery.isEmpty
                        ? 'Start a search to discover content.'
                        : 'No results found for "$_lastQuery".',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final content = _results[index];
                    final isSaved = _savedItemIds.contains(content.id);
                    return ContentCard(
                      content: content, 
                      isSaved: isSaved,
                      onSave: () => _toggleSaveContent(content, isSaved),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
