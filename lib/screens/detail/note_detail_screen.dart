import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:edtech_app/services/firestore_service.dart';

class NoteDetailScreen extends StatefulWidget {
  /// The generated note content (plain text / markdown from Gemini).
  final String noteContent;

  /// Title of the source content.
  final String title;

  /// URL of the source content.
  final String sourceUrl;

  /// 'youtube' or 'devto'
  final String sourceType;

  const NoteDetailScreen({
    super.key,
    required this.noteContent,
    required this.title,
    required this.sourceUrl,
    required this.sourceType,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late final TextEditingController _controller;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    // _autoSave(); // call once on screen load
    super.initState();
    _controller = TextEditingController(text: widget.noteContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to save notes.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // final noteId = DateTime.now().millisecondsSinceEpoch.toString();
      final noteId = widget.sourceUrl.replaceAll(RegExp(r'[^\w]'), '_');
      await _firestoreService.saveNote(
        uid,
        noteId,
        widget.title,
        _controller.text,
        widget.sourceUrl,
        widget.sourceType,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save note: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _launchSourceUrl() async {
    final uri = Uri.tryParse(widget.sourceUrl);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open source link.')),
        );
      }
    }
  }

  // Future<void> _autoSave() async {
  //   final uid = FirebaseAuth.instance.currentUser?.uid;
  //   if (uid == null) return;

  //   final noteId = DateTime.now().millisecondsSinceEpoch.toString();
  //   try {
  //     await _firestoreService.saveNote(
  //       uid,
  //       noteId,
  //       widget.title,
  //       _controller.text,
  //       widget.sourceUrl,
  //       widget.sourceType,
  //     );
  //   } catch (e) {
  //     debugPrint('Auto-save failed: $e');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          // Edit / Done toggle
          IconButton(
            icon: Icon(_isEditing ? Icons.done : Icons.edit),
            tooltip: _isEditing ? 'Done editing' : 'Edit note',
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
          // Save to Firestore
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save_outlined),
                  tooltip: 'Save note',
                  onPressed: _saveNote,
                ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source chip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Chip(
              avatar: Icon(
                widget.sourceType == 'youtube'
                    ? Icons.play_circle_outline
                    : Icons.article_outlined,
                size: 16,
                color: colorScheme.onSecondaryContainer,
              ),
              label: Text(
                widget.sourceType == 'youtube' ? 'YouTube' : 'Dev.to Article',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              backgroundColor: colorScheme.secondaryContainer,
            ),
          ),

          // Notes body — Markdown display or raw edit
          Expanded(
            child: _isEditing
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Edit your notes here…',
                      ),
                    ),
                  )
                : Markdown(
                    data: _controller.text,
                    selectable: true,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    onTapLink: (text, href, title) async {
                      if (href != null) {
                        final uri = Uri.tryParse(href);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      }
                    },
                  ),
          ),

          // "View original" link at the bottom
          if (widget.sourceUrl.isNotEmpty)
            InkWell(
              onTap: _launchSourceUrl,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'View original',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
