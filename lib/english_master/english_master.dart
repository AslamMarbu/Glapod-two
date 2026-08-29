import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pdf_view_page.dart';
import '../providers/english_master_provider.dart';
import '../translator_page.dart';
import '../widgets.dart/appbar_page.dart';
import 'english_master_file.dart';

class EnglishMasterPage extends StatefulWidget {
  const EnglishMasterPage({super.key});

  @override
  State<EnglishMasterPage> createState() => _EnglishMasterPageState();
}

class _EnglishMasterPageState extends State<EnglishMasterPage> {
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'grammar':
        return Icons.menu_book_rounded;

      case 'vocabulary':
        return Icons.translate_rounded;

      case 'spoken english':
        return Icons.record_voice_over_rounded;

      case 'writing skills':
        return Icons.edit_note_rounded;

      case 'reading':
        return Icons.auto_stories_rounded;

      case 'listening':
        return Icons.headphones_rounded;

      case 'pronunciation':
        return Icons.mic_rounded;

      default:
        return Icons.book_rounded;
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnglishMasterProvider>().fetchEnglishMasterCategories();
    });
  }

  Future<void> _openPdf(
    EnglishMasterProvider provider,
    Map<String, dynamic> pdf,
  ) async {
    final String url = (pdf['pdf'] ?? '').toString();

    if (url.isEmpty || url == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF file is not available.')),
      );

      return;
    }

    final file = await provider.downloadFile(url);

    if (file == null || !mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          url: file.path,
          title: (pdf['title'] ?? 'English Master').toString(),
          isLocal: true,
        ),
      ),
    );
  }

  void _handleCategoryTap(
    EnglishMasterProvider provider,
    Map<String, dynamic> category,
  ) {
    final dynamic singleFile = category['single_file'];

    if (singleFile is Map) {
      _openPdf(provider, Map<String, dynamic>.from(singleFile));

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnglishMasterFilePage(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnglishMasterProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF1FAF2),
          appBar: const CustomAppBar(height: 70, title: 'English Master'),
          body: provider.isFetchingList
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.englishMasterList.length + 1,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    if (index == provider.englishMasterList.length) {
                      return _buildTranslatorCard();
                    }

                    final category = provider.englishMasterList[index];

                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        _handleCategoryTap(provider, category);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2EAE3)),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 10,
                              color: Colors.black12,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getCategoryIcon(
                                (category['name'] ?? '').toString(),
                              ),
                              size: 52,
                              color: const Color(0xFFF16704),
                            ),

                            const SizedBox(height: 14),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                (category['name'] ?? '').toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF263238),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildTranslatorCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TranslatorPage()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2EAE3)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.translate_rounded, size: 52, color: Color(0xFFF16704)),
            SizedBox(height: 14),
            Text(
              'Translator',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
