import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/questions_year_wise_lprovider.dart';
import 'pdf_view_page.dart';
import 'widgets.dart/appbar_page.dart';
import 'widgets.dart/empty_state_widget.dart';
import 'widgets.dart/document_card.dart';

class YearSetListingPage extends StatefulWidget {
  final String subjectId;
  final String year;

  const YearSetListingPage({
    super.key,
    required this.subjectId,
    required this.year
  });

  @override
  State<YearSetListingPage> createState() => _YearSetListingPageState();
}

class _YearSetListingPageState extends State<YearSetListingPage> {
  @override
  void initState() {
    super.initState();
    // API fetch triggered via microtask to avoid build-phase collisions
    Future.microtask(() =>
        context.read<YearwiseQPaperProvider>().fetchSets(widget.subjectId, widget.year)
    );
  }

  Future<void> _handlePaperTap(YearwiseQPaperProvider provider, String title, String url) async {
    // 🔹 Centralized: FileUtils handles hashing, 2-day expiry, and download via Provider
    final file = await provider.downloadPaper(url);

    if (file != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(
            title: title,
            url: file.path, // 🔹 Passes the hashed local path
            isLocal: true,
          ),
        ),
      );
    } else if (mounted && url.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open the file.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<YearwiseQPaperProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
      appBar: CustomAppBar(
        height: 40,
        title: "Year ${widget.year}",
        isDashboard: false,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B75BB)))
          : provider.paperSets.isEmpty
          ? const EmptyStateWidget(msg: "No papers available for this year.")
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        itemCount: provider.paperSets.length,
        itemBuilder: (context, index) {
          final setItem = provider.paperSets[index];
          final String title = setItem['title'] ?? "Set ${index + 1}";
          final String url = (setItem['file_url'] ?? "").toString();

          return DocumentCard(
            title: title,
            subtitle: "Question Paper",
            // 🔹 Standardized status check
            isDownloading: provider.isDownloading(url),
            // 🔹 Future that checks MD5 cache logic
            isDownloadedFuture: provider.isPaperDownloaded(url),
            onTap: () => _handlePaperTap(provider, title, url),
          );
        },
      ),
    );
  }
}