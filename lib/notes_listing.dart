import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/notes_provider.dart';
import 'widgets.dart/appbar_page.dart';
import 'pdf_view_page.dart';
import 'viewers/image_viewer_page.dart';
import 'viewers/video_viewer_page.dart';
import 'viewers/ppt_viewer_page.dart';
import 'widgets.dart/document_card.dart';
import 'dart:convert';

class NotesListingPage extends StatefulWidget {
  final dynamic chapterId;
  final String chapterTitle;
  const NotesListingPage({
    super.key,
    required this.chapterId,
    required this.chapterTitle,
  });

  @override
  State<NotesListingPage> createState() => _NotesListingPageState();
}

class _NotesListingPageState extends State<NotesListingPage> {
  final Map<String, bool> _localLoadingMap = {};
  final List<Color> themeColors = const [
    Color(0xFF4F46E5), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF43F5E), // Rose
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF59E0B), // Amber
  ];

  @override
  void initState() {
    super.initState();
    _loadAndPrefetchNotes();
  }

  // Fetches the list and immediately triggers background caching for all files
  Future<void> _loadAndPrefetchNotes() async {
    final provider = context.read<NotesProvider>();

    // 1. Fetch the notes metadata array from API
    await provider.fetchNotes(widget.chapterId);

    if (!mounted || provider.notes.isEmpty) return;

    // 2. Silently pre-fetch all small-to-medium files (PDFs, Images, PPTs) in the background
    for (var note in provider.notes) {
      final String url = (note['note_url'] ?? "").toString();
      if (url.isEmpty || url == "null") continue;

      final String ext = url.split('.').last.toLowerCase();

      // Skip large video files to save user data, pre-fetch everything else
      if (['mp4', 'mov', 'avi'].contains(ext)) continue;

      // Run validation check
      final bool alreadyCached = await provider.isNoteValid(url);
      if (!alreadyCached) {
        // Trigger download asynchronously WITHOUT 'await' so they download in parallel streams
        provider
            .downloadFile(url)
            .then((file) {
              if (mounted) {
                setState(
                  () {},
                ); // Refresh checkmarks on cards silently once ready
              }
            })
            .catchError((e) => debugPrint("Silent pre-fetch failed: $e"));
      }
    }
  }

  Future<void> _onFileTap(
    NotesProvider provider,
    Map<String, dynamic> note,
  ) async {
    final String url = (note['note_url'] ?? "").toString();
    final String title = (note['title'] ?? "Study Material").toString();

    if (url.isEmpty || url == "null") return;

    final String ext = url.split('.').last.toLowerCase();

    if (ext.contains('ppt')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PptWebViewer(url: url, title: title),
        ),
      );
      return;
    }

    try {
      // Direct look up: If the background pre-fetch already finished, this is INSTANT (0 seconds)
      final bool alreadyDownloaded = await provider.isNoteValid(url);

      if (alreadyDownloaded) {
        final file = await provider.downloadFile(url);
        if (file != null && mounted) {
          _navigateToViewer(file.path, ext, title);
        }
        return;
      }

      // Fallback: If user clicked before the background pre-fetch finished, show the loader
      if (mounted) {
        setState(() {
          _localLoadingMap[url] = true;
        });
      }

      final file = await provider.downloadFile(url);

      if (file != null && mounted) {
        _navigateToViewer(file.path, ext, title);
      }
    } catch (e) {
      debugPrint("Error viewing file: $e");
    } finally {
      if (mounted) {
        setState(() {
          _localLoadingMap[url] = false;
        });
      }
    }
  }

  void _navigateToViewer(String filePath, String ext, String title) {
    Widget? destination;
    if (ext == 'pdf') {
      destination = PdfViewerPage(url: filePath, title: title, isLocal: true);
    } else if (['jpg', 'jpeg', 'png'].contains(ext)) {
      destination = ImageViewerPage(path: filePath, title: title);
    } else if (['mp4', 'mov', 'avi'].contains(ext)) {
      destination = VideoViewerPage(path: filePath, title: title);
    }

    if (destination != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => destination!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: CustomAppBar(
        height: 40,
        title: widget.chapterTitle,
        isDashboard: false,
      ),
      body: _buildBody(notesProvider),
    );
  }

  Widget _buildBody(NotesProvider provider) {
    if (provider.isFetchingList) {
      return _buildShimmerLoading();
    }

    if (provider.notes.isEmpty) {
      return const Center(child: Text("No notes found."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.notes.length,
      itemBuilder: (context, index) {
        if (index >= provider.notes.length) return const SizedBox.shrink();

        final Map<String, dynamic> note = provider.notes[index];

        String noteUrl = "";
        String noteTitle = "";

        for (var entry in note.entries) {
          if (entry.key == 'note_url') noteUrl = entry.value.toString();
          if (entry.key == 'title') noteTitle = entry.value.toString();
        }

        if (noteUrl.isEmpty || noteUrl == "null") {
          return const SizedBox.shrink();
        }

        final accentColor = themeColors[index % themeColors.length];

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accentColor.withOpacity(0.18), width: 2),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: DocumentCard(
            title: noteTitle.isEmpty ? "Material Part ${index + 1}" : noteTitle,
            subtitle: "Study Material",
            isDownloading: _localLoadingMap[noteUrl] ?? false,
            isDownloadedFuture: provider.isNoteValid(noteUrl),
            onTap: () => _onFileTap(provider, note),
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      },
    );
  }
}
