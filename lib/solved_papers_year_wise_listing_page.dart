import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart'; // 🔹 Added
import '../providers/solved_papers_yearwise_provider.dart';
import 'widgets.dart/appbar_page.dart';
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
    Future.microtask(() => context
        .read<SolvedPaperSetProvider>()
        .fetchSets(widget.subjectId, widget.year));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SolvedPaperSetProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF7),
      appBar: CustomAppBar(
        height: 40,
        title:
        "${widget.subjectName.toUpperCase()} - ${widget.year}",
      ),
      body: provider.isLoading
          ? _buildShimmerList() // 🔹 Replaced loader
          : provider.paperSets.isEmpty
          ? const Center(
        child: Text("No solved papers available."),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 25),
        itemCount: provider.paperSets.length,
        itemBuilder: (context, index) {
          final paper = provider.paperSets[index];
          final String title =
              paper['title'] ??
                  "Solved Paper ${index + 1}";
          final String url =
              paper['file_url'] ?? "";
          final bool isDownloading =
              provider.downloadingStatus[url] ??
                  false;

          return _buildPaperItem(
              context,
              provider,
              title,
              url,
              isDownloading);
        },
      ),
    );
  }

  // 🔹 SHIMMER LIST
  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 25),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaperItem(
      BuildContext context,
      SolvedPaperSetProvider provider,
      String title,
      String url,
      bool isDownloading,
      ) {
    bool isDownloaded = provider.isFileDownloaded(url);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 18),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            GestureDetector(
              onTap: isDownloading
                  ? null
                  : () async {
                final file =
                await provider.downloadPaper(url);

                if (file != null && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PdfViewerPage(
                            title: title,
                            url: file.path,
                            isLocal: true,
                          ),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDownloaded
                      ? Colors.green.shade600
                      : const Color(0xFF1B75BB),
                  shape: BoxShape.circle,
                ),
                child: isDownloading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Icon(
                  isDownloaded
                      ? Icons.visibility
                      : Icons.file_download,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}