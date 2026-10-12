import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../pdf_view_page.dart';
import '../providers/english_master_provider.dart';
import '../translator_page.dart';
import '../widgets.dart/appbar_page.dart';
import 'english_master_file.dart';
import 'verb_forms_page.dart';
import 'word_family_page.dart';

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
    final categoryName = (category['name'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    if (categoryName == 'verb forms' ||
        categoryName == 'verb form' ||
        categoryName.contains('verb forms')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VerbFormsPage()),
      );

      return;
    }

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
        final int categoryCount = provider.englishMasterList.length;

        return Scaffold(
          backgroundColor: const Color(0xFFF1FAF2),
          appBar: const CustomAppBar(height: 70, title: 'English Master'),
          body: provider.isFetchingList
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              ...List.generate(categoryCount, (index) {
                                final category =
                                    provider.englishMasterList[index];
                                final title = (category['name'] ?? '')
                                    .toString();
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildImageMenuCard(
                                    title: title,
                                    imageUrl: (category['image'] ?? '')
                                        .toString(),
                                    icon: _getCategoryIcon(title),
                                    onTap: () =>
                                        _handleCategoryTap(provider, category),
                                  ),
                                );
                              }),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildImageMenuCard(
                                  title: 'Verb Forms',
                                  icon: Icons.table_chart_rounded,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const VerbFormsPage(),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildImageMenuCard(
                                  title: 'Translator',
                                  icon: Icons.translate_rounded,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const TranslatorPage(),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 40),
                                child: _buildImageMenuCard(
                                  title: 'Word Family',
                                  icon: Icons.account_tree_rounded,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const WordFamilyPage(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildImageMenuCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String imageUrl = '',
  }) {
    const accentColor = Color(0xFFF16704);
    final hasImage = imageUrl.isNotEmpty && imageUrl != 'null';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF0),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accentColor.withOpacity(0.35), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, size: 28, color: accentColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFFFF1E7),
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              _buildIconImageFallback(icon),
                        )
                      : _buildIconImageFallback(icon),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconImageFallback(IconData icon) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF1E7),
      alignment: Alignment.center,
      child: Icon(icon, size: 64, color: const Color(0xFFF16704)),
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

  Widget _buildWordFamilyCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WordFamilyPage()),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.account_tree_rounded,
                size: 42,
                color: Color(0xFFF16704),
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'Word Family',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),

            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildVerbFormsCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VerbFormsPage()),
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
            Icon(Icons.table_chart_rounded, size: 52, color: Color(0xFFF16704)),
            SizedBox(height: 14),
            Text(
              'Verb Forms',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
