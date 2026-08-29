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
  final List<Color> themeColors = const [
    Color(0xFF4F46E5),
    Color(0xFF10B981),
    Color(0xFFF43F5E),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFF59E0B),
  ];

  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => context.read<NotesProvider>().fetchNotes(widget.chapterId),
    );
  }

  Future<void> _onFileTap(
    NotesProvider provider,
    Map<String, dynamic> note,
  ) async {
    final String url = (note['note_url'] ?? '').toString();

    final String title = (note['title'] ?? 'Study Material').toString();

    if (url.isEmpty || url == 'null') {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('File is not available.')));
      }

      return;
    }

    final Uri? uri = Uri.tryParse(url);

    String ext = '';

    if (uri != null && uri.pathSegments.isNotEmpty) {
      final String fileName = uri.pathSegments.last;

      if (fileName.contains('.')) {
        ext = fileName.split('.').last.toLowerCase();
      }
    }

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
      final file = await provider.downloadFile(url);

      if (!mounted) {
        return;
      }

      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to download file. Please try again.'),
          ),
        );

        return;
      }

      _navigateToViewer(file.path, ext, title);
    } catch (e) {
      debugPrint('Error viewing note file => $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unable to open file.')));
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
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unsupported file type.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      appBar: CustomAppBar(
        height: 40,
        title: widget.chapterTitle,
        isDashboard: false,
      ),

      body: provider.isFetchingList
          ? _buildShimmerLoading()
          : provider.notes.isEmpty
          ? const Center(child: Text('No notes found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),

              itemCount: provider.notes.length,

              itemBuilder: (context, index) {
                final Map<String, dynamic> note = provider.notes[index];

                final String noteUrl = (note['note_url'] ?? '').toString();

                final String noteTitle = (note['title'] ?? '').toString();

                if (noteUrl.isEmpty || noteUrl == 'null') {
                  return const SizedBox.shrink();
                }

                final Color accentColor =
                    themeColors[index % themeColors.length];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(22),

                    border: Border.all(
                      color: accentColor.withOpacity(0.18),
                      width: 2,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),

                  child: DocumentCard(
                    title: noteTitle.isEmpty
                        ? 'Material Part ${index + 1}'
                        : noteTitle,

                    subtitle: 'Study Material',

                    isDownloading: provider.isLoading(noteUrl),

                    isDownloadedFuture: provider.isNoteValid(noteUrl),

                    onTap: () => _onFileTap(provider, note),
                  ),
                );
              },
            ),
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
