import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/notes_provider.dart';
import 'widgets.dart/appbar_page.dart';
import 'pdf_view_page.dart';
import 'viewers/image_viewer_page.dart';
import 'viewers/video_viewer_page.dart';
import 'viewers/ppt_viewer_page.dart';

class NotesListingPage extends StatefulWidget {
  final dynamic chapterId;
  final String chapterTitle;
  const NotesListingPage({super.key, required this.chapterId, required this.chapterTitle});

  @override
  State<NotesListingPage> createState() => _NotesListingPageState();
}

class _NotesListingPageState extends State<NotesListingPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<NotesProvider>().fetchNotes(widget.chapterId)
    );
  }

  Future<void> _onFileTap(dynamic note) async {
    final provider = context.read<NotesProvider>();
    final String url = note['note_url'];
    final String ext = url.split('.').last.toLowerCase();

    if (ext.contains('ppt')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PptWebViewer(url: url, title: "PPT"),
        ),
      );
      return;
    }

    final file = await provider.downloadFile(note);
    if (file == null) {
      _showMsg("Download failed.");
      return;
    }

    if (!mounted) return;

    Widget? destination;
    if (ext == 'pdf') {
      destination = PdfViewerPage(
        url: file.path,
        title: note['title'] ?? "PDF Document",
        isLocal: true,
      );
    } else if (['jpg', 'jpeg', 'png'].contains(ext)) {
      destination = ImageViewerPage(path: file.path, title: "Image");
    } else if (['mp4', 'mov', 'avi'].contains(ext)) {
      destination = VideoViewerPage(path: file.path, title: "Video");
    }

    if (destination != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => destination!));
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
      appBar: CustomAppBar(height: 40, title: widget.chapterTitle, isDashboard: false),
      body: notesProvider.isLoading
          ? _buildShimmerLoading()
          : notesProvider.notes.isEmpty
          ? const Center(child: Text("No notes found for this chapter."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notesProvider.notes.length,
        itemBuilder: (context, index) {
          final note = notesProvider.notes[index];
          final int id = note['id'];
          final bool isDownloading = notesProvider.downloadingStatus[id] ?? false;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              // 🔹 Leading (Icon) removed as requested
              title: Text(
                  note['title'] ?? "Material Part ${index + 1}",
                  style: const TextStyle(fontWeight: FontWeight.bold)
              ),
              // 🔹 Subtitle (File type) removed as requested
              trailing: isDownloading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: isDownloading ? null : () => _onFileTap(note),
            ),
          );
        },
      ),
    );
  }

  // 🔹 PROFESSIONAL SHIMMER FOR NOTES
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
            height: 60, // Slightly reduced height since subtitle is gone
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