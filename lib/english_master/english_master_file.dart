import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../pdf_view_page.dart';
import '../providers/english_master_provider.dart';
import '../widgets.dart/appbar_page.dart';
import 'package:Edmaster/widgets.dart/document_card.dart';

class EnglishMasterFilePage extends StatelessWidget {
  final Map<String, dynamic> category;

  const EnglishMasterFilePage({super.key, required this.category});

  static const List<Color> cardColors = [
    Color(0xFF4F46E5),
    Color(0xFF10B981),
    Color(0xFFF43F5E),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFF59E0B),
  ];

  List<Map<String, dynamic>> get files {
    final dynamic rawFiles = category['files'];

    if (rawFiles is! List) {
      return [];
    }

    return rawFiles
        .whereType<Map>()
        .map((file) => Map<String, dynamic>.from(file))
        .toList();
  }

  Future<void> _openPdf(
    BuildContext context,
    EnglishMasterProvider provider,
    Map<String, dynamic> pdf,
  ) async {
    final String url = (pdf['pdf'] ?? '').toString();

    if (url.isEmpty || url == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF file is not available.')),
      );
      return;
    }

    /*
     * FileUtils.downloadFile() will:
     *
     * 1. Check the 12-hour cache.
     * 2. Return cached PDF if still valid.
     * 3. Download only if missing/expired.
     *
     * provider.isLoading(url) becomes true
     * while downloading, so DocumentCard
     * shows its loading animation.
     */
    final file = await provider.downloadFile(url);

    if (file == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to download PDF. Please try again.'),
          ),
        );
      }
      return;
    }

    if (!context.mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          url: file.path,
          title: (pdf['title'] ?? 'English Master').toString(),
          isLocal: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EnglishMasterProvider>();

    final String categoryName = (category['name'] ?? 'English Files')
        .toString();

    final List<Map<String, dynamic>> categoryFiles = files;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      appBar: CustomAppBar(
        height: 70,
        title: categoryName,
        subtitleText: 'English Master',
      ),

      body: provider.isFetchingList
          ? _buildShimmerLoading()
          : categoryFiles.isEmpty
          ? const Center(
              child: Text(
                'No English Master files found.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: categoryFiles.length,
              itemBuilder: (context, index) {
                final Map<String, dynamic> pdf = categoryFiles[index];

                final String url = (pdf['pdf'] ?? '').toString();

                final String title = (pdf['title'] ?? 'English Master PDF')
                    .toString();

                final Color accentColor = cardColors[index % cardColors.length];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.18),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: DocumentCard(
                    title: title,
                    subtitle: categoryName,

                    // Shows animation only
                    // for the PDF being downloaded.
                    isDownloading: provider.isLoading(url),

                    // Shows downloaded state
                    // when 12-hour cache is valid.
                    isDownloadedFuture: provider.isPdfValid(url),

                    onTap: () => _openPdf(context, provider, pdf),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 7,
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        );
      },
    );
  }
}
