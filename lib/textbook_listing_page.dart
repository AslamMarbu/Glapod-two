import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
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
        builder: (context) =>
            PdfViewerPage(url: file.path, title: title, isLocal: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TextbookProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),

      appBar: CustomAppBar(
        height: 40,
        title: '${widget.subjectName} Textbooks',
        isDashboard: false,
      ),

      body: widget.textbooks.isEmpty
          ? const Center(
              child: Text(
                'No textbooks found.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),

              itemCount: widget.textbooks.length,

              itemBuilder: (context, index) {
                final dynamic book = widget.textbooks[index];

                final String fileUrl = (book['file'] ?? '').toString();

                final String title =
                    (book['author_name'] ?? '${widget.subjectName} Textbook')
                        .toString();

                final String subtitle = 'Part ${index + 1}';

                if (fileUrl.isEmpty || fileUrl == 'null') {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),

                  child: DocumentCard(
                    title: title,
                    subtitle: subtitle,

                    isDownloading: provider.isLoading(fileUrl),

                    isDownloadedFuture: provider.isFileValid(fileUrl),

                    onTap: () =>
                        _handleAction(provider, fileUrl, '$title - $subtitle'),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
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
