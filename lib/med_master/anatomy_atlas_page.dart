import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class AnatomyAtlasPage extends StatefulWidget {
  final Map<String, dynamic> category;
  final int initialIndex;

  const AnatomyAtlasPage({
    super.key,
    required this.category,
    this.initialIndex = 0,
  });

  @override
  State<AnatomyAtlasPage> createState() => _AnatomyAtlasPageState();
}

class _AnatomyAtlasPageState extends State<AnatomyAtlasPage> {
  static const Color _primary = Color(0xFF00695C);
  static const Color _secondary = Color(0xFF00A896);
  static const Color _background = Color(0xFFF2FAF8);

  late final PageController _pageController;
  final TransformationController _transformationController =
      TransformationController();

  late List<Map<String, dynamic>> _images;
  int _currentIndex = 0;

  final Set<String> _preloading = <String>{};
  final Set<String> _preloaded = <String>{};

  String get _categoryName =>
      (widget.category['name'] ?? 'Anatomy Atlas').toString();

  String get _categoryImage {
    final value = widget.category['image']?.toString().trim() ?? '';
    return value == 'null' ? '' : value;
  }

  @override
  void initState() {
    super.initState();

    final dynamic rawFiles = widget.category['files'];

    _images = rawFiles is List
        ? rawFiles
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    if (_images.isEmpty && widget.category['single_file'] is Map) {
      _images = [
        Map<String, dynamic>.from(widget.category['single_file'] as Map),
      ];
    }

    if (_images.isNotEmpty) {
      _currentIndex = widget.initialIndex.clamp(0, _images.length - 1).toInt();
    }

    // Sentinel pages allow seamless wrapping between first and last images.
    _pageController = PageController(
      initialPage: _images.isEmpty ? 0 : _currentIndex + 1,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _preloadNearby(_currentIndex);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    _preloading.clear();
    _preloaded.clear();
    super.dispose();
  }

  String _imageUrl(Map<String, dynamic> item) {
    for (final key in const ['image', 'file_url', 'image_url', 'url']) {
      final value = item[key]?.toString().trim() ?? '';

      if (value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }

    return '';
  }

  String _imageTitle(Map<String, dynamic> item) {
    final value = item['title'] ?? item['name'] ?? item['caption'];
    final title = value?.toString().trim() ?? '';

    return title.isEmpty || title.toLowerCase() == 'null' ? '' : title;
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _preload(String url) {
    if (!mounted ||
        url.isEmpty ||
        _preloaded.contains(url) ||
        _preloading.contains(url)) {
      return;
    }

    _preloading.add(url);

    precacheImage(CachedNetworkImageProvider(url), context)
        .then((_) {
          _preloading.remove(url);

          if (mounted) {
            _preloaded.add(url);
          }
        })
        .catchError((Object error) {
          _preloading.remove(url);
          debugPrint('ANATOMY ATLAS PRELOAD ERROR: $error');
        });
  }

  void _preloadNearby(int index) {
    if (_images.isEmpty) return;

    for (int offset = -2; offset <= 3; offset++) {
      final int candidate = (index + offset) % _images.length;
      final int normalized = candidate < 0
          ? candidate + _images.length
          : candidate;

      _preload(_imageUrl(_images[normalized]));
    }
  }

  void _goTo(int index) {
    if (_images.isEmpty || !_pageController.hasClients) return;

    _resetZoom();

    _pageController.animateToPage(
      index + 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _openGrid() {
    Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => AnatomyAtlasGridPage(
          categoryName: _categoryName,
          categoryImage: _categoryImage,
          images: _images,
          currentIndex: _currentIndex,
        ),
      ),
    ).then((result) {
      if (!mounted ||
          result == null ||
          result < 0 ||
          result >= _images.length) {
        return;
      }

      _goTo(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          top: false,
          bottom: false,
          child: _images.isEmpty
              ? _buildEmpty()
              : Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: PageView.builder(
                          controller: _pageController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _images.length + 2,
                          onPageChanged: (page) {
                            if (_images.isEmpty) return;

                            final int realIndex =
                                (page - 1 + _images.length) % _images.length;

                            _resetZoom();

                            setState(() {
                              _currentIndex = realIndex;
                            });

                            _preloadNearby(realIndex);

                            // Jump from sentinel pages to the matching image.
                            if (page == 0 || page == _images.length + 1) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted || !_pageController.hasClients) {
                                  return;
                                }

                                _pageController.jumpToPage(
                                  page == 0 ? _images.length : 1,
                                );
                              });
                            }
                          },
                          itemBuilder: (context, page) {
                            final int index =
                                (page - 1 + _images.length) % _images.length;

                            final String url = _imageUrl(_images[index]);

                            if (url.isEmpty) {
                              return _buildImageError();
                            }

                            return _buildZoomImage(url);
                          },
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      bottom: true,
                      child: _buildBottomControls(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, Color(0xFF00897B), _secondary],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        18,
      ),
      child: Row(
        children: [
          // Back button: no border or outline.
          _headerButton(
            Icons.arrow_back_ios_new_rounded,
            () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),

          // Heading: no surrounding border.
          Expanded(
            child: Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: Row(
                children: [
                  ClipOval(
                    child: Container(
                      width: 44,
                      height: 44,
                      color: Colors.white,
                      child: _categoryImage.isEmpty
                          ? const Icon(Icons.biotech_rounded, color: _primary)
                          : CachedNetworkImage(
                              imageUrl: _categoryImage,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Icon(
                                Icons.biotech_rounded,
                                color: _primary,
                              ),
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.biotech_rounded,
                                color: _primary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _categoryName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Grid button: no border or outline.
          _headerButton(Icons.grid_view_rounded, _openGrid),
        ],
      ),
    );
  }

  Widget _headerButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: Colors.white.withOpacity(0.15),
        highlightColor: Colors.white.withOpacity(0.08),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Center(child: Icon(icon, color: Colors.white, size: 21)),
        ),
      ),
    );
  }

  Widget _buildZoomImage(String url) {
    return Center(
      child: InteractiveViewer(
        transformationController: _transformationController,
        panEnabled: false,
        scaleEnabled: true,
        minScale: 1,
        maxScale: 4,
        scaleFactor: 200,
        boundaryMargin: EdgeInsets.zero,
        constrained: true,
        clipBehavior: Clip.none,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          useOldImageOnUrlChange: true,
          placeholder: (_, __) => Center(
            child: Lottie.asset(
              'assets/animations/loading_text.json',
              width: 225,
              height: 225,
              fit: BoxFit.contain,
            ),
          ),
          imageBuilder: (_, imageProvider) => Image(
            image: imageProvider,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
          errorWidget: (_, __, error) {
            debugPrint('ANATOMY ATLAS IMAGE ERROR: $error');
            return _buildImageError();
          },
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
      child: Row(
        children: [
          Expanded(
            child: _navigationButton(
              icon: Icons.arrow_back_rounded,
              label: 'Previous',
              color: const Color(0xFF00796B),
              onTap: () =>
                  _goTo((_currentIndex - 1 + _images.length) % _images.length),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _navigationButton(
              icon: Icons.arrow_forward_rounded,
              label: 'Next',
              color: const Color(0xFF00A896),
              onTap: () => _goTo((_currentIndex + 1) % _images.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navigationButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F1EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 54, color: _primary),
          SizedBox(height: 8),
          Text('Unable to load this image'),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      color: _background,
      width: double.infinity,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: _primary),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.image_not_supported_outlined,
              size: 64,
              color: _primary,
            ),
            const SizedBox(height: 14),
            const Text(
              'No Anatomy Atlas images available.',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

/// Tapping a grid item returns its index to the viewer.
class AnatomyAtlasGridPage extends StatelessWidget {
  final String categoryName;
  final String categoryImage;
  final List<Map<String, dynamic>> images;
  final int currentIndex;

  const AnatomyAtlasGridPage({
    super.key,
    required this.categoryName,
    required this.categoryImage,
    required this.images,
    required this.currentIndex,
  });

  static const Color _primary = Color(0xFF00695C);
  static const Color _background = Color(0xFFF2FAF8);

  String _url(Map<String, dynamic> item) {
    for (final key in const ['image', 'file_url', 'image_url', 'url']) {
      final value = item[key]?.toString().trim() ?? '';

      if (value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }

    return '';
  }

  String _title(Map<String, dynamic> item) {
    final value = item['title'] ?? item['name'] ?? item['caption'];
    final title = value?.toString().trim() ?? '';

    return title.isEmpty || title.toLowerCase() == 'null' ? '' : title;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(categoryName, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: images.isEmpty
          ? const Center(child: Text('No images available.'))
          : GridView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                final item = images[index];
                final url = _url(item);
                final title = _title(item);

                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.pop(context, index),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            color: const Color(0xFFE4F1EE),
                            alignment: Alignment.center,
                            child: url.isEmpty
                                ? const Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 40,
                                    color: _primary,
                                  )
                                : CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.contain,
                                    placeholder: (_, __) => const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _primary,
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => const Icon(
                                      Icons.broken_image_outlined,
                                      size: 40,
                                      color: _primary,
                                    ),
                                  ),
                          ),
                        ),
                        if (title.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF23433E),
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
  }
}
