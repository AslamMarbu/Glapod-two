import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Edmaster/pdf_view_page.dart';

import '../providers/textbook_provider.dart';
import 'widgets.dart/appbar_page.dart';
import 'widgets.dart/document_card.dart';

class TextbookListingPage extends StatefulWidget {
  final String subjectName;
  final List<dynamic> textbooks;

  const TextbookListingPage({
    super.key,
    required this.subjectName,
    required this.textbooks,
  });

  @override
  State<TextbookListingPage> createState() => _TextbookListingPageState();
}

class _TextbookListingPageState extends State<TextbookListingPage> {
  // ---------------------------------------------------------------------------
  // REMOVE DUPLICATE CHAPTERS
  // ---------------------------------------------------------------------------

  List<dynamic> _removeDuplicateTextbooks(List<dynamic> textbooks) {
    final List<dynamic> uniqueTextbooks = [];

    // Stores already displayed chapter keys.
    final Set<String> displayedChapters = {};

    for (final dynamic book in textbooks) {
      if (book is! Map) {
        continue;
      }

      final dynamic chapterData = book['chapter'];

      final Map<String, dynamic> chapter = chapterData is Map<String, dynamic>
          ? chapterData
          : <String, dynamic>{};

      final String fileUrl = (book['file'] ?? '').toString().trim();

      final String chapterId = (chapter['id'] ?? book['chapter_id'] ?? '')
          .toString()
          .trim();

      final String chapterNumber = (chapter['chapter_number'] ?? '')
          .toString()
          .trim();

      final String chapterTitle = (chapter['chapter_title'] ?? '')
          .toString()
          .trim();

      /*
       * Priority:
       * 1. Chapter ID
       * 2. Chapter number + title
       * 3. File URL
       *
       * This prevents the same chapter from being displayed multiple times.
       */

      String uniqueKey;

      if (chapterId.isNotEmpty && chapterId != 'null') {
        uniqueKey = 'chapter_id_$chapterId';
      } else if (chapterNumber.isNotEmpty ||
          (chapterTitle.isNotEmpty && chapterTitle != 'null')) {
        uniqueKey =
            'chapter_${chapterNumber.toLowerCase()}_${chapterTitle.toLowerCase()}';
      } else {
        uniqueKey = 'file_${fileUrl.toLowerCase()}';
      }

      // Ignore duplicate chapter.
      if (displayedChapters.contains(uniqueKey)) {
        debugPrint('Duplicate textbook skipped: $uniqueKey');
        continue;
      }

      displayedChapters.add(uniqueKey);
      uniqueTextbooks.add(book);
    }

    debugPrint('Original textbooks count: ${textbooks.length}');
    debugPrint('Unique textbooks count: ${uniqueTextbooks.length}');

    return uniqueTextbooks;
  }

  // ---------------------------------------------------------------------------
  // OPEN TEXTBOOK
  // ---------------------------------------------------------------------------

  Future<void> _handleAction(
    TextbookProvider provider,
    String url,
    String title,
  ) async {
    if (url.isEmpty || url == 'null') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Textbook file is not available.')),
        );
      }

      return;
    }

    final file = await provider.getBook(url);

    if (!mounted) {
      return;
    }

    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to download textbook. Please try again.'),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(
          url: file.path,
          downloadUrl: url,
          allowDownload: true,
          title: title,
          isLocal: true,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TextbookProvider>();

    // Remove duplicates before building the ListView.
    final List<dynamic> uniqueTextbooks = _removeDuplicateTextbooks(
      widget.textbooks,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
      appBar: CustomAppBar(
        height: 40,
        title: '${widget.subjectName} Textbooks',
        isDashboard: false,
      ),
      body: uniqueTextbooks.isEmpty
          ? const Center(
              child: Text(
                'No textbooks found.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: uniqueTextbooks.length,
              itemBuilder: (context, index) {
                final dynamic book = uniqueTextbooks[index];

                if (book is! Map) {
                  return const SizedBox.shrink();
                }

                // -------------------------------------------------------------
                // TEXTBOOK DATA
                // -------------------------------------------------------------

                final String fileUrl = (book['file'] ?? '').toString().trim();

                final dynamic chapterData = book['chapter'];

                final Map<String, dynamic> chapter =
                    chapterData is Map<String, dynamic>
                    ? chapterData
                    : <String, dynamic>{};

                final String chapterNumber = (chapter['chapter_number'] ?? '')
                    .toString()
                    .trim();

                final String chapterTitle = (chapter['chapter_title'] ?? '')
                    .toString()
                    .trim();

                // -------------------------------------------------------------
                // SKIP INVALID FILE
                // -------------------------------------------------------------

                if (fileUrl.isEmpty || fileUrl == 'null') {
                  return const SizedBox.shrink();
                }

                // -------------------------------------------------------------
                // DISPLAY TEXT
                // -------------------------------------------------------------

                final String title =
                    chapterTitle.isNotEmpty && chapterTitle != 'null'
                    ? chapterTitle
                    : 'Chapter ${index + 1}';

                final String subtitle =
                    chapterNumber.isNotEmpty && chapterNumber != 'null'
                    ? 'Chapter $chapterNumber'
                    : '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DocumentCard(
                    title: title,
                    subtitle: subtitle,
                    isDownloading: provider.isLoading(fileUrl),
                    isDownloadedFuture: provider.isFileValid(fileUrl),
                    onTap: () {
                      _handleAction(
                        provider,
                        fileUrl,
                        subtitle.isNotEmpty ? '$subtitle - $title' : title,
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
