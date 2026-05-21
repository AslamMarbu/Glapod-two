import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets.dart/appbar_page.dart';

class PptWebViewer extends StatefulWidget {
  final String url;
  final String title;

  const PptWebViewer({super.key, required this.url, required this.title});

  @override
  State<PptWebViewer> createState() => _PptWebViewerState();
}

class _PptWebViewerState extends State<PptWebViewer> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 🔹 Google Docs Viewer wraps your URL to render the PPT in HTML
    final String googleViewerUrl =
        "https://docs.google.com/viewer?url=${Uri.encodeComponent(widget.url)}&embedded=true";

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(googleViewerUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(height: 60, title: widget.title, isDashboard: false),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF0A6ED1))),
        ],
      ),
    );
  }
}