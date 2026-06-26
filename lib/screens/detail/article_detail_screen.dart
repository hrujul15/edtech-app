import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:edtech_app/models/content_model.dart';
import 'package:edtech_app/services/firestore_service.dart';
import 'package:edtech_app/services/gemini_service.dart';
import 'package:edtech_app/services/transcript_service.dart';
import 'package:edtech_app/screens/detail/note_detail_screen.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Content content;

  const ArticleDetailScreen({super.key, required this.content});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late final WebViewController _webViewController;
  bool _isSaving = false;
  bool _isLoading = true;
  Timer? _loadingTimer;

  void _stopLoading() {
    if (mounted && _isLoading) {
      setState(() => _isLoading = false);
    }
    _loadingTimer?.cancel();
  }

  @override
  void initState() {
    super.initState();

    // Fallback: hide spinner after 8 seconds regardless of callbacks
    _loadingTimer = Timer(const Duration(seconds: 8), _stopLoading);

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            _loadingTimer?.cancel();
            // Restart fallback timer on each new page load
            _loadingTimer = Timer(const Duration(seconds: 8), _stopLoading);
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) => _stopLoading(),
          onWebResourceError: (_) => _stopLoading(),
        ),
      )
      ..loadRequest(Uri.parse(widget.content.url));
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
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
      // For Dev.to articles, combine title + description
      final transcriptService = TranscriptService();
      final articleText = transcriptService.getArticleText(widget.content);

      final notes = await GeminiService.generateNotesFromText(
        articleText,
        widget.content.title,
      );
      // Auto-save immediately after generation
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        print("done");
        // final noteId = DateTime.now().millisecondsSinceEpoch.toString();
        final noteId = widget.content.url.replaceAll(RegExp(r'[^\w]'), '_');
        await _firestoreService.saveNote(
          uid,
          noteId,
          widget.content.title,
          notes,
          widget.content.url,
          'devto',
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(); // close dialog

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NoteDetailScreen(
            noteContent: notes,
            title: widget.content.title,
            sourceUrl: widget.content.url,
            sourceType: 'devto',
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.content.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
      // Generate Notes FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateNotes,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Generate Notes'),
      ),
    );
  }
}
