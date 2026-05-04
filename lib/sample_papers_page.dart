import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/sample_paper_provider.dart';
import 'pdf_view_page.dart';
import 'widgets.dart/appbar_page.dart';
import 'package:glapod/utils/app_colors.dart';

// --- SHIMMER PLACEHOLDER WIDGET ---
class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8
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

// --- SAMPLE PAPERS PAGE ---
class SamplePapersPage extends StatefulWidget {
  final String subjectId, subjectName, classId;

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
    Future.microtask(() =>
        context.read<SamplePaperProvider>().fetchPapers(widget.classId, widget.subjectId)
    );
  }

  Future<void> _handlePaperTap(dynamic paper) async {
    final provider = context.read<SamplePaperProvider>();
    final file = await provider.downloadPaper(paper);

    if (file != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerPage(
            url: file.path,
            title: paper['title'] ?? "Sample Paper",
            isLocal: true,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open file.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paperProvider = context.watch<SamplePaperProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
      appBar: CustomAppBar(
        height: 40,
        title: "Sample Papers",
        isDashboard: false,
        subtitleText: widget.subjectName,
      ),
      body: paperProvider.isLoading
          ? _buildShimmerList() // 🔹 Replaced Spinner with Shimmer
          : paperProvider.papers.isEmpty
          ? const Center(child: Text("No sample papers found."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: paperProvider.papers.length,
        itemBuilder: (context, index) {
          final paper = paperProvider.papers[index];
          final String id = paper['id'].toString();
          final bool isDownloading = paperProvider.downloadingStatus[id] ?? false;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              title: Text(
                paper['title'] ?? "Paper ${index + 1}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeadingBlack),
              ),
              subtitle: Text("${paper['mark'] ?? 'N/A'} Marks • ${paper['time'] ?? 'N/A'}"),
              trailing: isDownloading
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.actionBlue)
              )
                  : const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.actionBlue),
              onTap: isDownloading ? null : () => _handlePaperTap(paper),
            ),
          );
        },
      ),
    );
  }

  // 🔹 ADDED SHIMMER SKELETON LIST
  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8, // Show 8 skeleton items
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title skeleton
                    ShimmerPlaceholder(
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: 16,
                    ),
                    const SizedBox(height: 10),
                    // Subtitle skeleton
                    const ShimmerPlaceholder(
                      width: 120,
                      height: 12,
                    ),
                  ],
                ),
              ),
              // Trailing icon skeleton
              const ShimmerPlaceholder(
                width: 16,
                height: 16,
                borderRadius: 4,
              ),
            ],
          ),
        );
      },
    );
  }
}