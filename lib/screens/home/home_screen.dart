import 'dart:async';
import 'package:edtech_app/services/cache_service.dart';
import 'package:flutter/material.dart';
import 'package:edtech_app/models/content_model.dart';
import 'package:edtech_app/models/user_model.dart';
import 'package:edtech_app/services/auth_service.dart';
import 'package:edtech_app/services/firestore_service.dart';
import 'package:edtech_app/services/youtube_service.dart';
import 'package:edtech_app/services/devto_service.dart';
import 'package:edtech_app/services/wikipedia_service.dart';
// import 'package:edtech_app/services/openlibrary_service.dart';
import 'package:edtech_app/services/ranking_service.dart';
import 'package:edtech_app/widgets/content_card.dart';
import 'package:edtech_app/screens/detail/video_detail_screen.dart';
import 'package:edtech_app/screens/detail/article_detail_screen.dart';
import 'package:edtech_app/screens/saved/saved_screen.dart';
import 'package:edtech_app/screens/notes/saved_notes_screen.dart';

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
  final WikipediaService _wikipediaService = WikipediaService();
  // final OpenLibraryService _openLibraryService = OpenLibraryService();
  final RankingService _rankingService = RankingService();
  final CacheService _cacheService = CacheService();
  int _currentIndex = 0; // Bottom nav index

  bool _isLoading = true;
  UserModel? _userModel;

  /// Top 2 categories mapped to their fetched content
  List<_CategorySection> _categorySections = [];
  // Keep the raw, unranked items for each category so we can re-rank locally
  final Map<String, List<Content>> _rawCategoryItems = {};
  final Map<String, List<Content>> _searchCache = {};
  List<Content> _searchResults = [];
  bool _isSearching = false;
  bool _isSearchLoading = false;
  String _lastQuery = '';

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
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      final user = await _firestoreService.getUser(uid);

      if (mounted && user.interests.isEmpty) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
        return;
      }

      if (mounted) {
        setState(() {
          _userModel = user;
          _isLoading = false; // 👈 stop spinner early, show page immediately
          _categorySections = [];
        });
      }

      // Start listening to saved items early too
      _savedItemsSub?.cancel();
      _savedItemsSub = _firestoreService.getSavedContentIdsStream(uid).listen((
        ids,
      ) {
        if (mounted) setState(() => _savedItemIds = ids);
      });

      final topCategories = _getTopCategories(
        user.categoryScores,
        2,
        user.interests,
      );
      // Replace the category fetching loop in _loadHomeData with this:
      for (final category in topCategories) {
        // Check cache first
        final cached = await _cacheService.getCategoryResults(category);

        if (cached != null) {
          // Cache hit — show instantly, no API calls
          _rawCategoryItems[category] = cached;
          final ranked = _rankingService.rankContent(
            cached,
            category,
            user.categoryScores,
          );
          if (mounted) {
            setState(() {
              _categorySections.add(
                _CategorySection(category: category, items: ranked),
              );
            });
          }
          continue; // skip API calls for this category
        }

        // Cache miss — fetch from APIs progressively
        List<Content> categoryItems = [];

        final futures = [
          _youtubeService.searchYouTube(category),
          _devtoService.searchDevTo(category),
          _wikipediaService.searchWikipedia(category),
        ];

        for (final future in futures) {
          future.then((results) {
            if (!mounted) return;
            categoryItems = [...categoryItems, ...results];
            _rawCategoryItems[category] = categoryItems;

            final ranked = _rankingService.rankContent(
              categoryItems,
              category,
              user.categoryScores,
            );

            final existingIndex = _categorySections.indexWhere(
              (s) => s.category == category,
            );

            setState(() {
              if (existingIndex >= 0) {
                _categorySections[existingIndex] = _CategorySection(
                  category: category,
                  items: ranked,
                );
              } else {
                _categorySections.add(
                  _CategorySection(category: category, items: ranked),
                );
              }
            });
          });
        }

        // After all 3 APIs finish, save to cache
        Future.wait(futures).then((_) {
          if (categoryItems.isNotEmpty) {
            _cacheService.saveCategoryResults(category, categoryItems);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading home data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Return up to [count] categories sorted by highest score descending.
  /// Falls back to user interests if categoryScores is empty.
  List<String> _getTopCategories(
    Map<String, double> categoryScores,
    int count,
    List<String> interests,
  ) {
    if (categoryScores.isEmpty) {
      // Fall back to user interests
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

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() => _isSearching = false);
      return;
    }
    if (_searchCache.containsKey(trimmed)) {
      setState(() {
        _isSearching = true;
        _isSearchLoading = false;
        _searchResults = _searchCache[trimmed]!;
        _lastQuery = trimmed;
      });
      return; // skip API calls entirely
    }

    setState(() {
      _isSearching = true;
      _isSearchLoading = true;
      _searchResults = [];
      _lastQuery = trimmed;
    });

    // Each API updates results as soon as IT finishes
    final futures = [
      _youtubeService.searchYouTube(trimmed),
      _devtoService.searchDevTo(trimmed),
      _wikipediaService.searchWikipedia(trimmed),
    ];

    for (final future in futures) {
      future.then((results) {
        if (!mounted) return;
        setState(() {
          _searchResults = _rankingService.rankContent(
            [..._searchResults, ...results],
            trimmed,
            _userModel?.categoryScores ?? {},
          );
          _isSearchLoading = _searchResults.isEmpty;
        });
      });
    }

    // Stop spinner after all finish regardless
    Future.wait(futures)
        .then((_) {
          if (mounted) {
            _searchCache[trimmed] = _searchResults;
            setState(() => _isSearchLoading = false);
          }
        })
        .catchError((e) {
          debugPrint('Search error: $e');
          if (mounted) setState(() => _isSearchLoading = false);
        });
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
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Search articles and videos...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              ),
            ),
          ),

          const SizedBox(height: 8),

          if (_isSearching) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Search Results',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchResults.clear();
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            if (_isSearchLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_searchResults.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text('No results found for "$_lastQuery".'),
                ),
              )
            else
              ..._searchResults.map((content) {
                final isSaved = _savedItemIds.contains(content.id);
                return ContentCard(
                  content: content,
                  isSaved: isSaved,
                  onSave: () => _toggleSaveContent(content, isSaved),
                  onTap: () => _openContent(content),
                );
              }),
          ] else ...[
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
        ],
      ),
    );
  }

  /// Build a horizontal scrollable section for one category
  Widget _buildCategorySection(_CategorySection section) {
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
          child: section.items.isEmpty
              ? const Center(child: Text('No content found'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: section.items.length,
                  itemBuilder: (context, index) {
                    final content = section.items[index];
                    final isSaved = _savedItemIds.contains(content.id);
                    return SizedBox(
                      width: 280,
                      child: ContentCard(
                        content: content,
                        isSaved: isSaved,
                        onSave: () => _toggleSaveContent(content, isSaved),
                        onTap: () => _openContent(content),
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

  Future<void> _openContent(Content content) async {
    if (!mounted) return;

    if (content.source == 'youtube') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VideoDetailScreen(content: content)),
      );
      return;
    }

    // Dev.to, Wikipedia, Open Library → ArticleDetailScreen
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ArticleDetailScreen(content: content)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pages for bottom nav tabs
    final List<Widget> pages = [
      _buildHomeBody(),
      const SavedScreen(),
      const SavedNotesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.55),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            _reRankHomeSections();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.notes), label: 'Notes'),
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
