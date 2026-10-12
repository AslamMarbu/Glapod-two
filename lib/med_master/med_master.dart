import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/med_master_provider.dart';
import '../pdf_view_page.dart';
import '../widgets.dart/appbar_page.dart';
import 'med_master_file_page.dart';

class MedMasterPage extends StatefulWidget {
  const MedMasterPage({super.key});

  @override
  State<MedMasterPage> createState() => _MedMasterPageState();
}

class _MedMasterPageState extends State<MedMasterPage> {
  IconData _getCategoryIcon(int index) {
    switch (index) {
      case 0:
        return Icons.menu_book_rounded; // Card 1

      case 1:
        return Icons.accessibility_new_rounded; // Card 2

      case 2:
        return Icons.monitor_heart_rounded; // Card 3

      case 3:
        return Icons.medication_rounded; // Card 4

      case 4:
        return Icons.biotech_rounded; // Card 5

      case 5:
        return Icons.coronavirus_rounded; // Card 6

      case 6:
        return Icons.local_hospital_rounded; // Card 7

      case 7:
        return Icons.medical_services_rounded; // Card 8

      case 8:
        return Icons.child_care_rounded; // Card 9

      case 9:
        return Icons.pregnant_woman_rounded; // Card 10

      case 10:
        return Icons.document_scanner_rounded; // Card 11

      case 11:
        return Icons.emergency_rounded; // Card 12

      default:
        return Icons.health_and_safety_rounded;
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedMasterProvider>().fetchMedMasterPdfs();
    });
  }

  Future<void> _openPdf(
    MedMasterProvider provider,
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

    if (file == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          url: file.path,
          title: (pdf['title'] ?? 'Med Master').toString(),
          isLocal: true,
        ),
      ),
    );
  }

  void _handleCategoryTap(
    MedMasterProvider provider,
    Map<String, dynamic> category,
  ) {
    final dynamic singleFile = category['single_file'];

    if (singleFile is Map) {
      _openPdf(provider, Map<String, dynamic>.from(singleFile));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MedMasterFilePage(category: category)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedMasterProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF1FAF2),
          appBar: const CustomAppBar(height: 70, title: 'Med Master'),
          body: provider.isFetchingList
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          ...List.generate(provider.medMasterList.length, (
                            index,
                          ) {
                            final item = provider.medMasterList[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildImageMenuCard(
                                title: (item['name'] ?? '').toString(),
                                imageUrl: (item['image'] ?? '').toString(),
                                icon: _getCategoryIcon(index),
                                onTap: () => _handleCategoryTap(provider, item),
                              ),
                            );
                          }),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
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
    const accentColor = Color(0xFF00ACC1);
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
                            color: const Color(0xFFE5F8FA),
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
      color: const Color(0xFFE5F8FA),
      alignment: Alignment.center,
      child: Icon(icon, size: 64, color: const Color(0xFF00ACC1)),
    );
  }
}
