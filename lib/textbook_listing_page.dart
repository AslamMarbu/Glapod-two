import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:glapod/pdf_view_page.dart';
import '../providers/textbook_provider.dart';
import 'widgets.dart/appbar_page.dart';

// --- SHIMMER PLACEHOLDER WIDGET ---
class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TextbookProvider>();
      for (var book in widget.textbooks) {
        provider.checkExistingStatus(book['file'] ?? "");
      }
    });
  }

  Future<void> _handleAction(TextbookProvider provider, String url, int index) async {
    final file = await provider.downloadBook(url);

    if (file != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(
            url: file.path,
            title: "${widget.subjectName} - Part ${index + 1}",
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
    // If you have a loading state in your provider, use it here:
    // final provider = context.watch<TextbookProvider>();
    // bool isInitialLoading = provider.isInitialLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
      appBar: CustomAppBar(
        height: 40,
        title: "${widget.subjectName} Textbooks",
        isDashboard: false,
      ),
      body: widget.textbooks.isEmpty
          ? _buildShimmerList() // 🔹 Show shimmer when list is empty/loading
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: widget.textbooks.length,
        itemBuilder: (context, index) {
          final fileUrl = widget.textbooks[index]['file'] ?? "";

          return Consumer<TextbookProvider>(
            builder: (context, provider, child) {
              bool isDownloaded = provider.isDownloaded(fileUrl);
              bool isLoading = provider.isLoading(fileUrl);

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: ListTile(
                  title: Text("${widget.subjectName} Textbook",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Part ${index + 1}"),
                  trailing: isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : IconButton(
                    icon: Icon(
                      isDownloaded ? Icons.visibility : Icons.file_download,
                      color: const Color(0xFF1B75BB),
                    ),
                    onPressed: () => _handleAction(provider, fileUrl, index),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🔹 Added Shimmer Skeleton List
  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5, // Show 5 skeleton items
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Skeleton for Title
                    ShimmerPlaceholder(
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: 16,
                    ),
                    const SizedBox(height: 8),
                    // Skeleton for Subtitle
                    const ShimmerPlaceholder(
                      width: 80,
                      height: 12,
                    ),
                  ],
                ),
              ),
              // Skeleton for Trailing Action Icon
              const ShimmerPlaceholder(
                width: 30,
                height: 30,
                borderRadius: 15,
              ),
            ],
          ),
        );
      },
    );
  }
}