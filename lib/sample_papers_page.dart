import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/sample_paper_provider.dart';
import 'pdf_view_page.dart';
import 'widgets.dart/appbar_page.dart';
import 'package:Edmaster/widgets.dart/document_card.dart';

class SamplePapersPage extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String classId;

  const SamplePapersPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.classId,
  });

  @override
  State<SamplePapersPage> createState() => _SamplePapersPageState();
}

class _SamplePapersPageState extends State<SamplePapersPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => context.read<SamplePaperProvider>().fetchPapers(
        widget.classId,
        widget.subjectId,
      ),
    );
  }

  Future<void> _handlePaperTap(dynamic paper) async {
    final provider = context.read<SamplePaperProvider>();

    final String url =
        (paper['file'] ?? paper['file_url'] ?? paper['paper_url'] ?? '')
            .toString();

    if (url.isEmpty || url == 'null') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF file is not available.')),
        );
      }

      return;
    }

    final file = await provider.downloadPaper(paper);

    if (!mounted) {
      return;
    }

    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to download PDF. Please try again.'),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          url: file.path,
          title: (paper['title'] ?? 'Paper').toString(),
          isLocal: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paperProvider = context.watch<SamplePaperProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),

      appBar: CustomAppBar(
        height: 40,
        title: 'Sample Papers',
        subtitleText: widget.subjectName,
      ),

      body: paperProvider.isLoading
          ? _buildShimmerLoading()
          : paperProvider.papers.isEmpty
          ? const Center(
              child: Text(
                'No sample papers found.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: paperProvider.papers.length,
              itemBuilder: (context, index) {
                final paper = paperProvider.papers[index];

                final String id = paper['id']?.toString() ?? '';

                final String url =
                    (paper['file'] ??
                            paper['file_url'] ??
                            paper['paper_url'] ??
                            '')
                        .toString();

                final String title = (paper['title'] ?? 'Paper ${index + 1}')
                    .toString();

                final String subtitle = '${paper['mark'] ?? 'N/A'} Marks';

                if (url.isEmpty || url == 'null') {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DocumentCard(
                    title: title,
                    subtitle: subtitle,

                    // Shows loading animation only
                    // for the tapped PDF.
                    isDownloading: paperProvider.isDownloading(id),

                    // Checks whether the PDF exists
                    // in the valid 12-hour cache.
                    isDownloadedFuture: paperProvider.isPaperDownloaded(url),

                    onTap: () => _handlePaperTap(paper),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        );
      },
    );
  }
}
