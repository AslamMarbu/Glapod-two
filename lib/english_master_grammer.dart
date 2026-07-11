import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/english_master_provider.dart';
import 'pdf_view_page.dart';
import 'widgets.dart/appbar_page.dart';
import 'package:glapod/widgets.dart/document_card.dart';
import 'package:shimmer/shimmer.dart';

class EnglishMasterGrammarPage extends StatefulWidget {
  const EnglishMasterGrammarPage({super.key});

  @override
  State<EnglishMasterGrammarPage> createState() =>
      _EnglishMasterGrammarPageState();
}

class _EnglishMasterGrammarPageState extends State<EnglishMasterGrammarPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGrammar();
    });
  }

  Future<void> _openPdf(
    EnglishMasterProvider provider,
    Map<String, dynamic> pdf,
  ) async {
    final String url = pdf['pdf'].toString();

    final file = await provider.downloadFile(url);

    if (file == null) return;

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          url: file.path,
          title: pdf['title'] ?? "Grammar",
          isLocal: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EnglishMasterProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
      appBar: const CustomAppBar(
        height: 70,
        title: "Grammar",
        subtitleText: "English Master",
      ),
      body: provider.isFetchingList
          ? _buildShimmerLoading()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.grammarList.length,
              itemBuilder: (context, index) {
                final pdf = provider.grammarList[index];

                final id = pdf['id'].toString();
                final url = pdf['pdf'].toString();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DocumentCard(
                    title: pdf['title'] ?? "Grammar PDF",
                    subtitle: "English Grammar",
                    isDownloading: provider.isLoading(url),
                    isDownloadedFuture: provider.isPdfValid(url),
                    onTap: () => _openPdf(provider, pdf),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadGrammar() async {
    final provider = context.read<EnglishMasterProvider>();

    await provider.fetchGrammarPdfs();

    for (var pdf in provider.grammarList) {
      final url = (pdf['pdf'] ?? "").toString();

      if (url.isEmpty) continue;

      final cached = await provider.isPdfValid(url);

      if (!cached) {
        provider.downloadFile(url);
      }
    }
  }
}
