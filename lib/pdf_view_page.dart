import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import 'widgets.dart/appbar_page.dart';
import 'utils/file_utils.dart';

/// PDF reader that renders pages as high-resolution PNG images.
///
/// Add the dependency with: flutter pub add pdfx
class PdfViewerPage extends StatefulWidget {
  final String url;
  final String title;
  final bool isLocal;
  final String? downloadUrl;
  final bool allowDownload;

  const PdfViewerPage({
    super.key,
    required this.url,
    required this.title,
    this.isLocal = false,
    this.downloadUrl,
    this.allowDownload = false,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage>
    with TickerProviderStateMixin {
  // Render a lightweight preview first so zoom becomes available quickly.
  static const double _previewRenderScale = 1.5;
  static const double _renderScale = 3.0;
  final Dio _dio = Dio();
  final PageController _pageController = PageController();
  final TransformationController _transformationController =
      TransformationController();

  PdfDocument? _document;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isDownloading = false;
  bool _isLandscape = false;
  bool _isFullscreen = false;

  String _status = 'Initializing...';
  String? _pdfPath;
  int _totalPages = 0;
  int _currentPage = 1;

  final Map<int, Uint8List> _pageImages = {};
  final Map<int, Uint8List> _pagePreviews = {};
  final Map<int, String> _pageErrors = {};
  final Set<int> _renderingPages = {};
  final Set<int> _renderingHighResolutionPages = {};
  bool _isZoomed = false;
  Offset _doubleTapPosition = Offset.zero;
  late final AnimationController _zoomAnimationController;
  Animation<Matrix4>? _zoomAnimation;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformChanged);
    _zoomAnimationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 260),
        )..addListener(() {
          final animation = _zoomAnimation;
          if (animation != null) {
            _transformationController.value = animation.value;
          }
        });
    unawaited(_initializePdf());
  }

  Future<void> _initializePdf() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _status = widget.isLocal ? 'Opening PDF...' : 'Downloading PDF...';
      _pdfPath = null;
      _totalPages = 0;
      _currentPage = 1;
      _pageImages.clear();
      _pagePreviews.clear();
      _pageErrors.clear();
      _renderingPages.clear();
      _renderingHighResolutionPages.clear();
      _isZoomed = false;
      _zoomAnimationController.stop();
      _zoomAnimation = null;
    });

    final oldDocument = _document;
    _document = null;
    if (oldDocument != null) {
      try {
        await oldDocument.close();
      } catch (_) {}
    }

    PdfDocument? openedDocument;
    try {
      final String path;

      if (kIsWeb) {
        // Browsers cannot use dart:io File paths. Fetch PDF bytes and open
        // them directly. The source server must allow CORS for this request.
        final bytes = await _downloadTemporaryPdfBytes();
        if (!mounted) return;
        setState(() => _status = 'Reading PDF pages...');
        openedDocument = await PdfDocument.openData(bytes);
        path = widget.downloadUrl ?? widget.url;
      } else {
        if (widget.isLocal) {
          path = widget.url;
          final file = File(path);
          if (!await file.exists()) {
            throw Exception('Local PDF file not found.');
          }
          await _validatePdfFile(file);
        } else {
          path = await _downloadTemporaryPdf();
        }

        if (!mounted) return;
        setState(() => _status = 'Reading PDF pages...');
        openedDocument = await PdfDocument.openFile(path);
      }

      final pageCount = openedDocument.pagesCount;
      if (pageCount < 1) throw Exception('The PDF contains no pages.');

      if (!mounted) {
        await openedDocument.close();
        return;
      }

      _document = openedDocument;
      openedDocument = null;
      setState(() {
        _pdfPath = path;
        _totalPages = pageCount;
        _currentPage = 1;
        _status = 'Preparing first page...';
      });

      await _renderPage(1);
      if (!mounted) return;

      if (!_pagePreviews.containsKey(1) && !_pageImages.containsKey(1)) {
        throw Exception(_pageErrors[1] ?? 'Could not render the first page.');
      }

      setState(() {
        _isLoading = false;
        _hasError = false;
        _status = 'PDF ready';
      });

      if (_totalPages >= 2) unawaited(_renderPage(2));
    } catch (error, stackTrace) {
      debugPrint('PDF OPEN/RENDER ERROR: $error\n$stackTrace');
      if (openedDocument != null) {
        try {
          await openedDocument.close();
        } catch (_) {}
      }
      final currentDocument = _document;
      _document = null;
      if (currentDocument != null) {
        try {
          await currentDocument.close();
        } catch (_) {}
      }
      _showError(
        'Unable to open this PDF. It may be incomplete, damaged, '
        'or password-protected.\n\nDetails: $error',
      );
    }
  }

  Future<String> _downloadTemporaryPdf() async {
    final sourceUrl = widget.downloadUrl ?? widget.url;

    // Remote PDFs use the same centralized 24-hour cache as other study files.
    // The permanent "Download PDF" action below still saves a separate copy
    // under Documents/EdMaster_PDFs and is not subject to cache cleanup.
    final cachedFile = await FileUtils.downloadFile(sourceUrl);
    if (cachedFile == null) {
      throw Exception('Unable to download this PDF. Please try again.');
    }

    try {
      await _validatePdfFile(cachedFile);
      return cachedFile.path;
    } catch (_) {
      // Do not let an HTML/error response be reused as a PDF on the next open.
      await FileUtils.deleteCachedFile(sourceUrl);
      rethrow;
    }
  }

  /// Web-only download path. Browser CORS rules apply to the PDF host.
  Future<Uint8List> _downloadTemporaryPdfBytes() async {
    final sourceUrl = widget.downloadUrl ?? widget.url;

    try {
      final response = await _dio.get<List<int>>(
        sourceUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 90),
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
        ),
      );

      final data = response.data;
      if (data == null || data.length < 5) {
        throw Exception('The server returned an empty or incomplete PDF.');
      }

      final bytes = Uint8List.fromList(data);
      if (!_hasPdfSignature(bytes)) {
        throw Exception(
          'The server did not return a PDF. It may have returned an HTML '
          'error page instead.',
        );
      }

      return bytes;
    } on DioException catch (error) {
      debugPrint('WEB PDF DOWNLOAD ERROR: $error');
      throw Exception(
        'Unable to load this PDF in the browser. Check the PDF URL and '
        'whether its server allows cross-origin (CORS) requests.',
      );
    }
  }

  bool _hasPdfSignature(Uint8List bytes) {
    const signature = <int>[0x25, 0x50, 0x44, 0x46, 0x2D]; // %PDF-
    final limit = bytes.length < 1024 ? bytes.length : 1024;

    for (var i = 0; i <= limit - signature.length; i++) {
      var matches = true;
      for (var j = 0; j < signature.length; j++) {
        if (bytes[i + j] != signature[j]) {
          matches = false;
          break;
        }
      }
      if (matches) return true;
    }
    return false;
  }

  Future<void> _validatePdfFile(File file) async {
    if (!await file.exists()) throw Exception('PDF file does not exist.');
    final length = await file.length();
    if (length < 5) throw Exception('PDF file is empty or incomplete.');

    final header = await file
        .openRead(0, length < 1024 ? length : 1024)
        .fold<List<int>>(<int>[], (previous, chunk) => previous..addAll(chunk));

    const signature = <int>[0x25, 0x50, 0x44, 0x46, 0x2D]; // %PDF-
    var found = false;
    for (var i = 0; i <= header.length - signature.length; i++) {
      var matches = true;
      for (var j = 0; j < signature.length; j++) {
        if (header[i + j] != signature[j]) {
          matches = false;
          break;
        }
      }
      if (matches) {
        found = true;
        break;
      }
    }
    if (!found) {
      throw Exception(
        'The server did not return a PDF. It may have returned an HTML '
        'error or login page instead.',
      );
    }
  }

  String _safeTitle(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
    return cleaned.isEmpty ? 'document' : cleaned;
  }

  Future<void> _renderPage(int pageNumber) async {
    final document = _document;
    if (!mounted ||
        document == null ||
        pageNumber < 1 ||
        pageNumber > _totalPages ||
        _pagePreviews.containsKey(pageNumber) ||
        _pageImages.containsKey(pageNumber) ||
        !_renderingPages.add(pageNumber)) {
      return;
    }

    PdfPage? page;
    try {
      page = await document.getPage(pageNumber);
      final preview = await page.render(
        width: page.width * _previewRenderScale,
        height: page.height * _previewRenderScale,
        format: PdfPageImageFormat.png,
        quality: 100,
        backgroundColor: '#FFFFFF',
      );
      if (preview == null)
        throw Exception('Renderer returned an empty preview.');
      if (!mounted || !identical(document, _document)) return;

      // Show the page as soon as this lightweight preview is ready.
      setState(() {
        _pagePreviews[pageNumber] = preview.bytes;
        _pageErrors.remove(pageNumber);
        _pruneImageCache();
      });

      // Upgrade to a sharper image in the background. This does not block
      // opening the PDF or using pinch-to-zoom on the preview.
      unawaited(_renderHighResolutionPage(pageNumber, document));
    } catch (error, stackTrace) {
      debugPrint('PDF PAGE $pageNumber PREVIEW ERROR: $error\n$stackTrace');
      if (mounted && identical(document, _document)) {
        setState(() => _pageErrors[pageNumber] = error.toString());
      }
    } finally {
      if (page != null) {
        try {
          await page.close();
        } catch (_) {}
      }
      _renderingPages.remove(pageNumber);
    }
  }

  Future<void> _renderHighResolutionPage(
    int pageNumber,
    PdfDocument document,
  ) async {
    if (!mounted ||
        !identical(document, _document) ||
        _pageImages.containsKey(pageNumber) ||
        !_renderingHighResolutionPages.add(pageNumber)) {
      return;
    }

    PdfPage? page;
    try {
      page = await document.getPage(pageNumber);
      final rendered = await page.render(
        width: page.width * _renderScale,
        height: page.height * _renderScale,
        format: PdfPageImageFormat.png,
        quality: 100,
        backgroundColor: '#FFFFFF',
      );
      if (rendered == null) return;
      if (!mounted || !identical(document, _document)) return;

      setState(() {
        _pageImages[pageNumber] = rendered.bytes;
        _pruneImageCache();
      });
    } catch (error, stackTrace) {
      // Keep the preview usable even if high-resolution rendering fails.
      debugPrint('PDF PAGE $pageNumber HI-RES ERROR: $error\n$stackTrace');
    } finally {
      if (page != null) {
        try {
          await page.close();
        } catch (_) {}
      }
      _renderingHighResolutionPages.remove(pageNumber);
    }
  }

  void _animateToTransformation(Matrix4 target) {
    _zoomAnimationController.stop();

    _zoomAnimation =
        Matrix4Tween(
          begin: Matrix4.copy(_transformationController.value),
          end: target,
        ).animate(
          CurvedAnimation(
            parent: _zoomAnimationController,
            curve: Curves.easeInOutCubic,
          ),
        );

    _zoomAnimationController.forward(from: 0);
  }

  void _onTransformChanged() {
    if (!mounted) return;
    final zoomed = _transformationController.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _isZoomed) setState(() => _isZoomed = zoomed);
  }

  void _pruneImageCache() {
    final keep = <int>{_currentPage - 1, _currentPage, _currentPage + 1};
    _pageImages.removeWhere((page, _) => !keep.contains(page));
    _pagePreviews.removeWhere((page, _) => !keep.contains(page));
    _pageErrors.removeWhere((page, _) => !keep.contains(page));
  }

  void _onPageChanged(int index) {
    final pageNumber = index + 1;
    if (!mounted || pageNumber == _currentPage) return;

    _zoomAnimationController.stop();
    _zoomAnimation = null;
    _transformationController.value = Matrix4.identity();
    setState(() {
      _currentPage = pageNumber;
      _pruneImageCache();
    });

    unawaited(_renderPage(pageNumber));
    if (pageNumber > 1) unawaited(_renderPage(pageNumber - 1));
    if (pageNumber < _totalPages) unawaited(_renderPage(pageNumber + 1));
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _hasError = true;
      _status = message;
    });
  }

  Widget _buildPdfPages() {
    if (_totalPages == 0) return const SizedBox.shrink();

    return PageView.builder(
      key: ValueKey(_pdfPath),
      controller: _pageController,
      scrollDirection: Axis.horizontal,
      physics: const PageScrollPhysics(),
      itemCount: _totalPages,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        final pageNumber = index + 1;
        final bytes = _pageImages[pageNumber] ?? _pagePreviews[pageNumber];

        if (bytes == null) {
          if (!_pageErrors.containsKey(pageNumber)) {
            unawaited(_renderPage(pageNumber));
          }
          if (_pageErrors.containsKey(pageNumber)) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 34,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Could not render page $pageNumber.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _pageErrors.remove(pageNumber));
                        unawaited(_renderPage(pageNumber));
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry page'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Keep the page clean while its high-resolution PNG is rendering.
          return const Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: Color(0xFFFFB300),
                strokeWidth: 3,
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final viewportWidth = constraints.maxWidth;
            final viewportHeight = constraints.maxHeight;
            final boundary = constraints.biggest.longestSide;

            return SizedBox(
              width: viewportWidth,
              height: viewportHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTapDown: (details) {
                  // This position is local to the same full-size viewport
                  // that InteractiveViewer uses.
                  _doubleTapPosition = details.localPosition;
                },
                onDoubleTap: () {
                  if (_isZoomed) {
                    _animateToTransformation(Matrix4.identity());
                    return;
                  }

                  const zoomScale = 2.0;
                  final tap = _doubleTapPosition;

                  // With Alignment.topLeft, the transformation coordinates
                  // match the viewport coordinates directly.
                  final scenePoint = _transformationController.toScene(tap);

                  // Keep the point that was tapped at the same screen
                  // position while scaling around it.
                  final target = Matrix4.identity()
                    ..translate(tap.dx, tap.dy)
                    ..scale(zoomScale)
                    ..translate(-scenePoint.dx, -scenePoint.dy);

                  _animateToTransformation(target);
                },
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1.0,
                  maxScale: 6.0,

                  // The page cannot be dragged at normal size.
                  // Panning is enabled automatically after zooming.
                  panEnabled: _isZoomed,
                  scaleEnabled: true,

                  // Top-left alignment keeps tap-to-scene coordinates
                  // predictable for double-tap zoom.
                  alignment: Alignment.topLeft,
                  constrained: true,
                  boundaryMargin: EdgeInsets.all(boundary),
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: viewportWidth,
                    height: viewportHeight,
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text(
                            'Could not display this page image.',
                            style: TextStyle(color: Colors.black87),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleOrientation() async {
    if (_isLandscape) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      if (!mounted) return;
      setState(() {
        _isLandscape = false;
        _isFullscreen = false;
      });
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      if (!mounted) return;
      setState(() {
        _isLandscape = true;
        _isFullscreen = true;
      });
    }
  }

  Future<void> _toggleFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(
      _isFullscreen ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    );
    if (!mounted) return;
    setState(() => _isFullscreen = !_isFullscreen);
  }

  void _showGoToPageDialog() {
    final textController = TextEditingController(text: '$_currentPage');
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Jump to Page'),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter page 1 - $_totalPages',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A6ED1),
            ),
            onPressed: () {
              final target = int.tryParse(textController.text.trim());
              if (target == null || target < 1 || target > _totalPages) return;
              _transformationController.value = Matrix4.identity();
              _pageController.jumpToPage(target - 1);
              Navigator.pop(dialogContext);
            },
            child: const Text('Go', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).then((_) => textController.dispose());
  }

  Future<void> _downloadPdf() async {
    if (!widget.allowDownload || _isDownloading) return;

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Use the browser PDF download option to save this textbook.',
          ),
        ),
      );
      return;
    }
    String? stagingPath;

    try {
      if (!mounted) return;
      setState(() => _isDownloading = true);

      final directory = await getApplicationDocumentsDirectory();
      final downloadDirectory = Directory('${directory.path}/EdMaster_PDFs');
      if (!await downloadDirectory.exists()) {
        await downloadDirectory.create(recursive: true);
      }

      final savePath =
          '${downloadDirectory.path}/${_safeTitle(widget.title)}.pdf';
      stagingPath = '$savePath.download.part';
      final stagingFile = File(stagingPath);
      if (await stagingFile.exists()) await stagingFile.delete();

      if (widget.isLocal) {
        final source = File(widget.url);
        if (!await source.exists()) throw Exception('Source PDF not found.');
        await source.copy(stagingPath);
      } else {
        await _dio.download(
          widget.downloadUrl ?? widget.url,
          stagingPath,
          options: Options(
            followRedirects: true,
            receiveTimeout: const Duration(seconds: 90),
            validateStatus: (status) =>
                status != null && status >= 200 && status < 300,
          ),
        );
      }

      await _validatePdfFile(stagingFile);
      final destination = File(savePath);
      if (await destination.exists()) await destination.delete();
      await stagingFile.rename(savePath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved successfully\n$savePath'),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (error) {
      if (stagingPath != null) {
        final staging = File(stagingPath);
        if (await staging.exists()) {
          try {
            await staging.delete();
          } catch (_) {}
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $error')));
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  PreferredSizeWidget? _buildAppBar() {
    if (_isLandscape || _isFullscreen) return null;
    return CustomAppBar(
      height: 60,
      title: widget.title,
      isDashboard: false,
      customActions: [
        IconButton(
          tooltip: 'Jump to page',
          icon: const Icon(Icons.find_in_page, color: Colors.white),
          onPressed: _totalPages > 0 && !_isLoading
              ? _showGoToPageDialog
              : null,
        ),
        if (_totalPages > 0)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Text(
                '$_currentPage/$_totalPages',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        IconButton(
          tooltip: 'Landscape',
          icon: const Icon(Icons.stay_current_landscape, color: Colors.white),
          onPressed: _toggleOrientation,
        ),
        if (widget.allowDownload)
          IconButton(
            tooltip: 'Download PDF',
            onPressed: _isDownloading ? null : _downloadPdf,
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download, color: Colors.white),
          ),
      ],
    );
  }

  Widget _buildLandscapePortraitButton() {
    if (!_isLandscape) return const SizedBox.shrink();
    return Positioned(
      top: 8,
      right: 8,
      child: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleOrientation,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.stay_current_portrait,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 42,
              height: 42,
              child: CircularProgressIndicator(
                color: Color(0xFFFFB300),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 55),
            const SizedBox(height: 15),
            Text(
              _status,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _initializePdf,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    final document = _document;
    _document = null;
    if (document != null) {
      unawaited(document.close().catchError((_) {}));
    }
    _pageController.dispose();
    _zoomAnimationController.dispose();
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F2),
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isLoading)
              _buildLoadingView()
            else if (_hasError)
              _buildErrorView()
            else
              ColoredBox(
                color: const Color(0xFFF5F5F2),
                child: _buildPdfPages(),
              ),
            _buildLandscapePortraitButton(),
          ],
        ),
      ),
    );
  }
}
