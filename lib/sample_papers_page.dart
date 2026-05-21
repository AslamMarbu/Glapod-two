import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sample_paper_provider.dart';
import 'pdf_view_page.dart';
import 'widgets.dart/appbar_page.dart';
import 'package:glapod/widgets.dart/document_card.dart';

class SamplePapersPage extends StatefulWidget {
  final String subjectId, subjectName, classId;
  const SamplePapersPage({super.key, required this.subjectId, required this.subjectName, required this.classId});

  @override
  State<SamplePapersPage> createState() => _SamplePapersPageState();
}

class _SamplePapersPageState extends State<SamplePapersPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<SamplePaperProvider>().fetchPapers(widget.classId, widget.subjectId));
  }

  Future<void> _handlePaperTap(dynamic paper) async {
    final provider = context.read<SamplePaperProvider>();
    final file = await provider.downloadPaper(paper);

    if (file != null && mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PdfViewerPage(url: file.path, title: paper['title'] ?? "Paper", isLocal: true),
      ));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open file.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final paperProvider = context.watch<SamplePaperProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
      appBar: CustomAppBar(height: 40, title: "Sample Papers", subtitleText: widget.subjectName),
      body: paperProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: paperProvider.papers.length,
        itemBuilder: (context, index) {
          final paper = paperProvider.papers[index];
          final String id = paper['id']?.toString() ?? "";
          final String url = (paper['file'] ?? paper['file_url'] ?? paper['paper_url'] ?? "").toString();

          return DocumentCard(
            title: paper['title'] ?? "Paper ${index + 1}",
            subtitle: "${paper['mark'] ?? 'N/A'} Marks",
            isDownloading: paperProvider.isDownloading(id),
            isDownloadedFuture: paperProvider.isPaperDownloaded(url),
            onTap: () => _handlePaperTap(paper),
          );
        },
      ),
    );
  }
}