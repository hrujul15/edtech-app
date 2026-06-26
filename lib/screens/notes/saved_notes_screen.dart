import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edtech_app/models/note_model.dart';
import 'package:edtech_app/services/firestore_service.dart';
import 'package:edtech_app/screens/detail/note_detail_screen.dart';

class SavedNotesScreen extends StatefulWidget {
  const SavedNotesScreen({super.key});

  @override
  State<SavedNotesScreen> createState() => _SavedNotesScreenState();
}

class _SavedNotesScreenState extends State<SavedNotesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<NoteModel> _notes = [];
  bool _isLoading = true;
  String? _error;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime dt) =>
      '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _error = 'You must be signed in to view notes.';
          _isLoading = false;
        });
        return;
      }
      final notes = await _firestoreService.getNotes(uid);
      if (mounted) {
        setState(() {
          _notes = notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load notes: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteNote(NoteModel note) async {
    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text(
          'Delete "${note.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await _firestoreService.deleteNote(uid, note.id);
      if (mounted) {
        setState(() => _notes.removeWhere((n) => n.id == note.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete note: $e')),
        );
      }
    }
  }

  void _openNote(NoteModel note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(
          noteContent: note.content,
          title: note.title,
          sourceUrl: note.sourceUrl,
          sourceType: note.sourceType,
        ),
      ),
    );
  }

  Widget _buildBadge(String sourceType, ColorScheme colorScheme) {
    final isVideo = sourceType == 'youtube';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isVideo
            ? colorScheme.errorContainer
            : colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVideo ? Icons.play_circle_outline : Icons.article_outlined,
            size: 12,
            color: isVideo
                ? colorScheme.onErrorContainer
                : colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            isVideo ? 'VIDEO' : 'ARTICLE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isVideo
                  ? colorScheme.onErrorContainer
                  : colorScheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Notes'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                )
              : _notes.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadNotes,
                      child: ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.notes_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No saved notes yet.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Generate notes from any video or article.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotes,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final note = _notes[index];
                          return GestureDetector(
                            onLongPress: () => _deleteNote(note),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _openNote(note),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              note.title,
                                              style:
                                                  theme.textTheme.titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildBadge(
                                            note.sourceType,
                                            colorScheme,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        note.content,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: Colors.grey[600]),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 12,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(note.createdAt),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey[500],
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
