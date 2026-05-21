import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:glapod/pdf_view_page.dart';
import '../providers/textbook_provider.dart';
import 'widgets.dart/appbar_page.dart';
import 'widgets.dart/document_card.dart'; // 🔹 Import your global card

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

  Future<void> _handleAction(TextbookProvider provider, String url, String title) async {
    final file = await provider.getBook(url);

    if (file != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(
            url: file.path,
            title: title,
            isLocal: true,
          ),
        ),
      );
    } else if (mounted && url.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error opening textbook")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TextbookProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
      appBar: CustomAppBar(
        height: 40,
        title: "${widget.subjectName} Textbooks",
        isDashboard: false,
      ),
      body: widget.textbooks.isEmpty
          ? _buildShimmerList()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.textbooks.length,
        itemBuilder: (context, index) {
          final fileUrl = widget.textbooks[index]['file'] ?? "";
          final String title =  widget.textbooks[index]['author_name'] ?? "${widget.subjectName} Textbook";
          final String subtitle = "Part ${index + 1}";

          // 🔹 Using the standardized Global Card
          return DocumentCard(
            title: title,
            subtitle: subtitle,
            isDownloading: provider.isLoading(fileUrl),
            isDownloadedFuture: provider.isFileValid(fileUrl),
            onTap: () => _handleAction(provider, fileUrl, "$title - $subtitle"),
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