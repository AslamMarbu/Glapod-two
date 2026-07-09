import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:glapod/widgets.dart/appbar_page.dart';
import 'package:glapod/utils/app_colors.dart';

class PdfViewerPage extends StatefulWidget {
  final String path, title;

  const PdfViewerPage({super.key, required this.path, required this.title});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  int totalPages = 0;
  int currentPage = 0;
  bool isReady = false;
  PDFViewController? _pdfViewController;

  void _showGoToPageDialog() {
    final tempController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Jump to Page"),
        content: TextField(
          controller: tempController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Enter page number (1 - $totalPages)",
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              tempController.dispose(); // 🔹 prevent leak
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A6ED1),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final targetPage = int.tryParse(tempController.text);

              if (targetPage != null &&
                  targetPage > 0 &&
                  targetPage <= totalPages) {
                _pdfViewController?.setPage(targetPage - 1);
                tempController.dispose();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please enter a valid page range"),
                  ),
                );
              }
            },
            child: const Text("Go"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Stack(
          children: [
            CustomAppBar(height: 60, title: widget.title, isDashboard: false),

            // 🔹 Overlay Controls
            Positioned(
              right: width * 0.05,
              bottom: 15,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.find_in_page, color: Colors.white),
                    onPressed: isReady ? _showGoToPageDialog : null,
                  ),
                  if (isReady)
                    Text(
                      "${currentPage + 1} / $totalPages",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.path,
            swipeHorizontal: true,
            pageSnap: true,
            pageFling: true,
            autoSpacing: true,

            onViewCreated: (controller) {
              _pdfViewController = controller;
            },

            onRender: (pages) {
              if (!mounted) return;
              setState(() {
                totalPages = pages ?? 0; // 🔹 null safe
                isReady = true;
              });
            },

            onPageChanged: (page, total) {
              if (!mounted) return;
              setState(() {
                currentPage = page ?? 0; // 🔹 null safe
              });
            },
          ),

          // 🔹 Loader
          if (!isReady)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF0A6ED1)),
            ),

          // 🔹 Bottom Page Indicator
          if (isReady)
            Positioned(
              bottom: width * 0.07,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.04,
                    vertical: width * 0.02,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    "Page ${currentPage + 1}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.03,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
