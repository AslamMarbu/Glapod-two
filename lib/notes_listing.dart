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
  @override
  void initState() {
    super.initState();
    // Microtask ensures the fetch doesn't conflict with the initial build frame
    Future.microtask(
      () => context.read<NotesProvider>().fetchNotes(widget.chapterId),
    );
  }

  Future<void> _onFileTap(
    NotesProvider provider,
    Map<String, dynamic> note,
  ) async {
    // Standardizing extraction to prevent Web/JS crashes
    final String url = (note['note_url'] ?? "").toString();
    final String title = (note['title'] ?? "Study Material").toString();

    if (url.isEmpty || url == "null") return;

    final String ext = url.split('.').last.toLowerCase();

    // 1. Handle PPTs through the specialized web viewer
    if (ext.contains('ppt')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PptWebViewer(url: url, title: title),
        ),
      );
      return;
    }

    // 2. Download or retrieve from the 2-day cache via provider
    // Passing only the URL string to match the standardized downloadFile(url) signature
    final file = await provider.downloadFile(url);
    if (file == null) return;

    if (!mounted) return;

    // 3. Navigation based on file extension
    Widget? destination;
    if (ext == 'pdf') {
      destination = PdfViewerPage(url: file.path, title: title, isLocal: true);
    } else if (['jpg', 'jpeg', 'png'].contains(ext)) {
      destination = ImageViewerPage(path: file.path, title: title);
    } else if (['mp4', 'mov', 'avi'].contains(ext)) {
      destination = VideoViewerPage(path: file.path, title: title);
    }

    if (destination != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => destination!));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider for state changes like isFetchingList
    final notesProvider = context.watch<NotesProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
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
      // Inside your ListView.builder in NotesListingPage
      itemBuilder: (context, index) {
        if (index >= provider.notes.length) return const SizedBox.shrink();

        final Map<String, dynamic> note = provider.notes[index];

        // 🔹 Bypassing the [] operator to prevent the JS Symbol crash
        String noteUrl = "";
        String noteTitle = "";

        // Using .entries is safer on Web than note['note_url']
        for (var entry in note.entries) {
          if (entry.key == 'note_url') noteUrl = entry.value.toString();
          if (entry.key == 'title') noteTitle = entry.value.toString();
        }

        if (noteUrl.isEmpty || noteUrl == "null")
          return const SizedBox.shrink();

        return DocumentCard(
          title: noteTitle.isEmpty ? "Material Part ${index + 1}" : noteTitle,
          subtitle: "Study Material",
          isDownloading: provider.isLoading(noteUrl),
          isDownloadedFuture: provider.isNoteValid(noteUrl),
          onTap: () => _onFileTap(provider, note),
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
            height:
                72, // Matches the DocumentCard height for a smooth transition
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
