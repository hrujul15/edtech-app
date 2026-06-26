import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edtech_app/models/content_model.dart';
import 'package:edtech_app/services/firestore_service.dart';
import 'package:edtech_app/services/gemini_service.dart';
import 'package:edtech_app/services/transcript_service.dart';
import 'package:edtech_app/screens/detail/note_detail_screen.dart';

class VideoDetailScreen extends StatefulWidget {
  final Content content;

  const VideoDetailScreen({super.key, required this.content});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TranscriptService _transcriptService = TranscriptService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _saveContent() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to save content.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _firestoreService.saveContent(uid, widget.content);
      await _firestoreService.updateCategoryScore(uid, widget.content.category);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content saved successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save content: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _generateNotes() async {
    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Generating notes…'),
          ],
        ),
      ),
    );

    try {
      // Fetch transcript
      final transcript = await _transcriptService.getYouTubeTranscript(
        widget.content.id,
      );

      if (transcript.isEmpty) {
        if (mounted) {
          Navigator.of(context).pop(); // close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transcript not available for this video.'),
            ),
          );
        }
        return;
      }

      // Generate notes via Gemini
      final notes = await GeminiService.generateNotesFromText(
        transcript,
        widget.content.title,
      );
      // Auto-save immediately after generation
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // final noteId = DateTime.now().millisecondsSinceEpoch.toString();
        final noteId = widget.content.url.replaceAll(RegExp(r'[^\w]'), '_');
        await _firestoreService.saveNote(
          uid,
          noteId,
          widget.content.title,
          notes,
          widget.content.url,
          'youtube',
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(); // close dialog

      // Navigate to NoteDetailScreen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NoteDetailScreen(
            noteContent: notes,
            title: widget.content.title,
            sourceUrl: widget.content.url,
            sourceType: 'youtube',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // close dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to generate notes: $e')));
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Detail'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bookmark_add),
            onPressed: _isSaving ? null : _saveContent,
            tooltip: 'Save',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.content.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.content.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  // Generate Notes button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate Notes'),
                      onPressed: _generateNotes,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
