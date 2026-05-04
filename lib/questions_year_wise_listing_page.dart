import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/questions_year_wise_lprovider.dart';
import 'pdf_view_page.dart';
import 'widgets.dart/appbar_page.dart';
import 'package:glapod/utils/app_colors.dart';
import 'widgets.dart/empty_state_widget.dart';

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
    Future.microtask(() =>
        context.read<YearwiseQPaperProvider>().fetchSets(widget.subjectId, widget.year)
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: provider.paperSets.length,
        itemBuilder: (context, index) {
          final setItem = provider.paperSets[index];
          final String title = setItem['title'] ?? "Set ${index + 1}";
          final String url = setItem['file_url'] ?? "";
          final bool isDownloading = provider.downloadingStatus[url] ?? false;

          return _buildPaperCard(context, provider, title, url, isDownloading);
        },
      ),
    );
  }

  Widget _buildPaperCard(BuildContext context, YearwiseQPaperProvider provider, String title, String url, bool isDownloading) {
    // 🔹 Check download status from provider
    final bool isDownloaded = provider.isFileDownloaded(url);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        title: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.textHeadingBlack
          ),
        ),
        subtitle: const Text("Question Paper", style: TextStyle(color: AppColors.textSubtitle, fontSize: 14)),
        trailing: isDownloading
            ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue)
        )
            : Icon(
          // 🔹 Toggle: Eye icon if downloaded, Cloud download if not
            isDownloaded ? Icons.visibility : Icons.file_download,
            size: 24,
            color: isDownloaded ? Colors.green : AppColors.primaryBlue
        ),
        onTap: isDownloading ? null : () async {
          final file = await provider.downloadPaper(url);

          if (file != null && mounted) {
            // 🔹 Ensuring the path is handled correctly to avoid "overlay/empty" issues
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
          }
        },
      ),
    );
  }
}