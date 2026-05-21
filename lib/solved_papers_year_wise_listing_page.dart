import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/solved_papers_yearwise_provider.dart';
import 'widgets.dart/appbar_page.dart';
import 'widgets.dart/document_card.dart'; // Ensure this is the correct path
import 'pdf_view_page.dart';

class SolvedPapersYearWiseListingPage extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String year;

  const SolvedPapersYearWiseListingPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.year,
  });

  @override
  State<SolvedPapersYearWiseListingPage> createState() =>
      _SolvedPapersYearWiseListingPageState();
}

class _SolvedPapersYearWiseListingPageState
    extends State<SolvedPapersYearWiseListingPage> {
  @override
  void initState() {
    super.initState();
    // Triggers the API fetch on load
    Future.microtask(() => context
        .read<SolvedPaperSetProvider>()
        .fetchSets(widget.subjectId, widget.year));
  }

  Future<void> _handlePaperTap(
      BuildContext context,
      SolvedPaperSetProvider provider,
      String title,
      String url
      ) async {
    // Logic handles hashing, 12hr/2-day expiry, and download
    final file = await provider.downloadPaper(url);

    if (file != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(
            title: title,
            url: file.path,
            isLocal: true,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open the document.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SolvedPaperSetProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF7),
      appBar: CustomAppBar(
        height: 40,
        title: "${widget.subjectName.toUpperCase()} - ${widget.year}",
      ),
      body: provider.isLoading
          ? _buildShimmerList()
          : provider.paperSets.isEmpty
          ? const Center(child: Text("No solved papers available."))
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        itemCount: provider.paperSets.length,
        itemBuilder: (context, index) {
          final paper = provider.paperSets[index];
          final String title = paper['title'] ?? "Solved Paper ${index + 1}";
          final String url = (paper['file_url'] ?? "").toString();

          // 🔹 Use the Global DocumentCard here
          return DocumentCard(
            title: title,
            subtitle: "", // Or pass any relevant sub-info like "PDF"
            isDownloading: provider.isDownloading(url),

            // 🔹 FIX: Parameter name must match 'isDownloadedFuture'
            // as defined in your DocumentCard class
            isDownloadedFuture: provider.isPaperDownloaded(url),

            onTap: () => _handlePaperTap(context, provider, title, url),
          );
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      itemCount: 8,
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            height: 65, // Standard height for DocumentCard
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