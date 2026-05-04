import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'widgets.dart/appbar_page.dart';

class PdfViewerPage extends StatefulWidget {
  final String url;
  final String title;
  final bool isLocal; // 🔹 Added to distinguish between URL and local path

  const PdfViewerPage({
    super.key,
    required this.url,
    required this.title,
    this.isLocal = false, // 🔹 Defaults to false for web URLs
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  PdfController? _pdfController;
  bool _isLoading = true;
  String _status = "Initializing...";
  bool _hasError = false;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initializePdf();
  }

  void _initializePdf() {
    if (widget.isLocal) {
      _loadLocalFile();
    } else {
      _startDownload();
    }
  }

  // 🔹 New: Loads file directly from the path provided
  Future<void> _loadLocalFile() async {
    try {
      setState(() {
        _isLoading = true;
        _status = "Opening file...";
      });

      // Check if file actually exists at the path
      if (await File(widget.url).exists()) {
        _pdfController = PdfController(
          document: PdfDocument.openFile(widget.url),
        );
        setState(() => _isLoading = false);
      } else {
        throw Exception("File not found");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _status = "Error opening local PDF.";
      });
    }
  }

  Future<void> _startDownload() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _status = "Connecting...";
      });

      final dir = await getTemporaryDirectory();
      final fileName = "${widget.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf";
      final savePath = '${dir.path}/$fileName';

      await Dio().download(widget.url, savePath, onReceiveProgress: (received, total) {
        if (total != -1) {
          setState(() {
            _status = "Downloading: ${(received / total * 100).toStringAsFixed(0)}%";
          });
        }
      });

      _pdfController = PdfController(
        document: PdfDocument.openFile(savePath),
      );

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _status = "Failed to download PDF.";
      });
    }
  }

  void _showGoToPageDialog() {
    final TextEditingController _tempPageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Jump to Page"),
        content: TextField(
          controller: _tempPageController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Enter page (1 - $_totalPages)",
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A6ED1)),
            onPressed: () {
              final int? target = int.tryParse(_tempPageController.text);
              if (target != null && target > 0 && target <= _totalPages) {
                _pdfController?.animateToPage(target, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                Navigator.pop(context);
              }
            },
            child: const Text("Go", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Stack(
          children: [
            CustomAppBar(
              height: 40,
              title: widget.title,
              isDashboard: false,
            ),
            if (!_isLoading && !_hasError)
              Positioned(
                right: 20,
                bottom: 15,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.find_in_page, color: Colors.white),
                      onPressed: _showGoToPageDialog,
                    ),
                    PdfPageNumber(
                      controller: _pdfController!,
                      builder: (context, state, page, pagesCount) {
                        _totalPages = pagesCount ?? 0;
                        _currentPage = page;
                        return Text(
                          "$page / ${pagesCount ?? 0}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF0A6ED1)),
            const SizedBox(height: 20),
            Text(_status),
          ],
        ),
      )
          : _hasError
          ? Center(
        child: ElevatedButton(
          onPressed: _initializePdf, // 🔹 Retries based on type
          child: const Text("Retry"),
        ),
      )
          : PdfView(
        controller: _pdfController!,
        scrollDirection: Axis.horizontal,
        pageSnapping: true,
      ),
    );
  }
}