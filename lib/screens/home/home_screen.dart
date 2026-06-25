import 'dart:async';
import 'package:flutter/material.dart';
import 'package:edtech_app/models/content_model.dart';
import 'package:edtech_app/models/user_model.dart';
import 'package:edtech_app/services/auth_service.dart';
import 'package:edtech_app/services/firestore_service.dart';
import 'package:edtech_app/services/youtube_service.dart';
import 'package:edtech_app/services/devto_service.dart';
import 'package:edtech_app/services/ranking_service.dart';
import 'package:edtech_app/widgets/content_card.dart';
import 'package:edtech_app/screens/search/search_screen.dart';
import 'package:edtech_app/screens/saved/saved_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final YouTubeService _youtubeService = YouTubeService();
  final DevToService _devtoService = DevToService();
  final RankingService _rankingService = RankingService();

  int _currentIndex = 0; // Bottom nav index

  bool _isLoading = true;
  UserModel? _userModel;

  /// Top 2 categories mapped to their fetched content
  List<_CategorySection> _categorySections = [];
  // Keep the raw, unranked items for each category so we can re-rank locally
  final Map<String, List<Content>> _rawCategoryItems = {};

  StreamSubscription<Set<String>>? _savedItemsSub;
  Set<String> _savedItemIds = {};

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  /// Check interests, fetch user, pick top 2 categories, call APIs
  Future<void> _loadHomeData() async {
    try {
      final uid = _authService.currentUid;
      if (uid == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      final user = await _firestoreService.getUser(uid);

      if (mounted && user.interests.isEmpty) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
        return;
      }

      // Determine top 2 categories by score
      final topCategories = _getTopCategories(user.categoryScores, 2);

      // For each top category, fetch content from both APIs
      final sections = <_CategorySection>[];
      for (final category in topCategories) {
        final results = await Future.wait<List<Content>>([
          _youtubeService.searchYouTube(category),
          _devtoService.searchDevTo(category),
        ]);
        final combined = [...results[0], ...results[1]];
        // store raw combined items so we can re-rank locally later
        _rawCategoryItems[category] = combined;
        final ranked = _rankingService.rankContent(
          combined,
          category,
          user.categoryScores,
        );
        sections.add(_CategorySection(category: category, items: ranked));
      }

      if (mounted) {
        setState(() {
          _userModel = user;
          _categorySections = sections;
          _isLoading = false;
        });
      }

      // Start listening to saved items
      _savedItemsSub?.cancel();
      _savedItemsSub = _firestoreService.getSavedContentIdsStream(uid).listen((
        ids,
      ) {
        if (mounted) {
          setState(() {
            _savedItemIds = ids;
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading home data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Return up to [count] categories sorted by highest score descending.
  /// Falls back to user interests if categoryScores is empty.
  List<String> _getTopCategories(
    Map<String, double> categoryScores,
    int count,
  ) {
    if (categoryScores.isEmpty) {
      // Fall back to user interests
      final interests = _userModel?.interests ?? [];
      return interests.take(count).toList();
    }

    final sorted = categoryScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(count).map((e) => e.key).toList();
  }

  void _handleLogout() async {
    _savedItemsSub?.cancel();
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  /// Re-rank existing fetched items locally without refetching
  void _reRankHomeSections() {
    if (_rawCategoryItems.isEmpty) return;

    final sections = <_CategorySection>[];
    for (final entry in _rawCategoryItems.entries) {
      final category = entry.key;
      final rawItems = entry.value;
      final ranked = _rankingService.rankContent(
        rawItems,
        category,
        _userModel?.categoryScores ?? {},
      );
      sections.add(_CategorySection(category: category, items: ranked));
    }

    if (mounted) {
      setState(() {
        _categorySections = sections;
      });
    }
  }

  @override
  void dispose() {
    _savedItemsSub?.cancel();
    super.dispose();
  }

  // ──────────────────────────────────────
  //  Build methods for each tab
  // ──────────────────────────────────────

  /// HOME tab body
  Widget _buildHomeBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadHomeData,
      child: ListView(
        children: [
          // Search bar at top
          GestureDetector(
            onTap: () {
              setState(() => _currentIndex = 1); // Switch to search tab
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Text(
                    'Search articles and videos...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Welcome header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Welcome, ${_userModel?.name ?? 'Learner'}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),

          const SizedBox(height: 16),

          // Category sections
          if (_categorySections.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Start exploring to get personalised recommendations!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ..._categorySections.map(
              (section) => _buildCategorySection(section),
            ),

          const SizedBox(height: 24),

          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Build a horizontal scrollable section for one category
  Widget _buildCategorySection(_CategorySection section) {
    // Re-apply ranking here to ensure filters (shorts, language) and boosts are applied
    final rankedItems = _rankingService.rankContent(
      section.items,
      section.category,
      _userModel?.categoryScores ?? {},
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Because you like ${section.category}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 380,
          child: rankedItems.isEmpty
              ? const Center(child: Text('No content found'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: rankedItems.length,
                  itemBuilder: (context, index) {
                    final content = rankedItems[index];
                    final isSaved = _savedItemIds.contains(content.id);
                    return SizedBox(
                      width: 280,
                      child: ContentCard(
                        content: content,
                        isSaved: isSaved,
                        onSave: () => _toggleSaveContent(content, isSaved),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Toggle save content to Firestore
  Future<void> _toggleSaveContent(Content content, bool isSaved) async {
    final uid = _authService.currentUid;
    if (uid == null) return;

    try {
      if (isSaved) {
        await _firestoreService.deleteSavedContent(uid, content.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Removed "${content.title}"')));
        }
      } else {
        await _firestoreService.saveContent(uid, content);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Saved "${content.title}"')));
        }
      }
    } catch (e) {
      debugPrint('Error toggling content: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pages for bottom nav tabs
    final List<Widget> pages = [
      _buildHomeBody(),
      const SearchScreen(),
      const SavedScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            // Re-rank existing items locally instead of re-fetching from APIs
            _reRankHomeSections();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Saved'),
        ],
      ),
    );
  }
}

/// Internal model to pair a category name with its fetched content items
class _CategorySection {
  final String category;
  final List<Content> items;

  _CategorySection({required this.category, required this.items});
}
