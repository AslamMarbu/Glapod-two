import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.medMasterList.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final item = provider.medMasterList[index];

                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _handleCategoryTap(provider, item),
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
                              _getCategoryIcon(index),
                              size: 52,
                              color: const Color(0xFF00ACC1),
                            ),

                            const SizedBox(height: 14),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                (item['name'] ?? '').toString(),
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
}
