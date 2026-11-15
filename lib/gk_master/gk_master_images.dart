import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/gk_master_visual_provider.dart';
import 'gk_master_image_grid.dart';

class GKMasterImagesPage extends StatefulWidget {
  final dynamic categoryId;
  final String categoryName;
  final int initialIndex;
  final bool initialDataLoaded;

  const GKMasterImagesPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.initialIndex = 0,
    this.initialDataLoaded = false,
  });

  @override
  State<GKMasterImagesPage> createState() => _GKMasterImagesPageState();
}

class _GKMasterImagesPageState extends State<GKMasterImagesPage> {
  // ============================================================
  // PAGE CONTROLLER
  // ============================================================

  late final PageController _pageController;

  // ============================================================
  // TRANSFORMATION CONTROLLER
  // ============================================================

  final TransformationController _transformationController =
      TransformationController();

  // ============================================================
  // CURRENT INDEX
  // ============================================================

  int _currentIndex = 0;

  // ============================================================
  // IMAGE PRELOADING
  // ============================================================

  final Set<String> _preloadingImages = <String>{};

  final Set<String> _preloadedImages = <String>{};

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex + 1);

    // The home page can fetch the category data and preload its background
    // before navigation. Avoid issuing the same API request again.
    if (!widget.initialDataLoaded) {
      Future.microtask(() {
        if (!mounted) return;

        context.read<GKMasterProvider>().loadCategoryContents(
          widget.categoryId,
        );
      });
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _pageController.dispose();

    _transformationController.dispose();

    _preloadingImages.clear();
    _preloadedImages.clear();

    super.dispose();
  }

  // ============================================================
  // RESET ZOOM
  // ============================================================

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  // ============================================================
  // PRELOAD ONE IMAGE
  // ============================================================

  void _preloadImage(String imageUrl) {
    if (!mounted) {
      return;
    }

    final String url = imageUrl.trim();

    if (url.isEmpty) {
      return;
    }

    // Already cached.
    if (_preloadedImages.contains(url)) {
      return;
    }

    // Already downloading.
    if (_preloadingImages.contains(url)) {
      return;
    }

    _preloadingImages.add(url);

    // ==========================================================
    // IMPORTANT
    // ==========================================================
    //
    // No cacheWidth / cacheHeight here.
    //
    // The full original image is preloaded so the viewer does
    // not reduce image quality.
    // ==========================================================

    precacheImage(CachedNetworkImageProvider(url), context)
        .then((_) {
          if (!mounted) {
            return;
          }

          _preloadingImages.remove(url);
          _preloadedImages.add(url);

          debugPrint('GK MASTER IMAGE PRELOADED: $url');
        })
        .catchError((error) {
          _preloadingImages.remove(url);

          debugPrint('GK MASTER IMAGE PRELOAD ERROR: $error');
        });
  }

  // ============================================================
  // GET IMAGE URL
  // ============================================================

  String _getImageUrl(dynamic content) {
    if (content is! Map) {
      return '';
    }

    return content['file_url']?.toString().trim() ?? '';
  }

  // ============================================================
  // PRELOAD AROUND CURRENT IMAGE
  // ============================================================

  void _preloadNearbyImages(List<dynamic> contents, int currentIndex) {
    if (contents.isEmpty) {
      return;
    }

    // ==========================================================
    // CURRENT IMAGE
    // ==========================================================

    if (currentIndex >= 0 && currentIndex < contents.length) {
      final String currentUrl = _getImageUrl(contents[currentIndex]);

      _preloadImage(currentUrl);
    }

    // ==========================================================
    // NEXT 3 IMAGES
    // ==========================================================

    for (int offset = 1; offset <= 3; offset++) {
      final int nextIndex = currentIndex + offset;

      if (nextIndex >= contents.length) {
        break;
      }

      final String imageUrl = _getImageUrl(contents[nextIndex]);

      _preloadImage(imageUrl);
    }

    // ==========================================================
    // PREVIOUS 3 IMAGES
    // ==========================================================

    for (int offset = 1; offset <= 3; offset++) {
      final int previousIndex = currentIndex - offset;

      if (previousIndex < 0) {
        break;
      }

      final String imageUrl = _getImageUrl(contents[previousIndex]);

      _preloadImage(imageUrl);
    }
  }

  // ============================================================
  // INITIAL PRELOAD
  // ============================================================

  void _preloadInitialImages(List<dynamic> contents) {
    if (contents.isEmpty) {
      return;
    }

    // Current + next 3.
    final int count = contents.length < 4 ? contents.length : 4;

    for (int i = 0; i < count; i++) {
      final String imageUrl = _getImageUrl(contents[i]);

      _preloadImage(imageUrl);
    }
  }

  // ============================================================
  // NEXT IMAGE
  // ============================================================

  void _nextImage(int totalImages) {
    if (totalImages <= 0) {
      return;
    }

    final int nextIndex =
        (_pageController.page?.round() ?? (_currentIndex + 1)) + 1;

    _resetZoom();

    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  // ============================================================
  // PREVIOUS IMAGE
  // ============================================================

  void _previousImage() {
    final int totalImages =
        (context.read<GKMasterProvider>().selectedCategory?['contents']
                as List?)
            ?.length ??
        0;
    if (totalImages <= 0) return;

    final int page = _pageController.page?.round() ?? (_currentIndex + 1);
    final int previousIndex = page - 1;

    _resetZoom();

    _pageController.animateToPage(
      previousIndex,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  // ============================================================
  // OPEN GRID
  // ============================================================

  void _openGrid(List<dynamic> contents, String categoryImage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GKMasterImageGridPage(
          contents: contents,
          categoryName: widget.categoryName,
          categoryImage: categoryImage,
          currentIndex: _currentIndex,
          categoryId: widget.categoryId,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Consumer<GKMasterProvider>(
          builder: (context, provider, child) {
            // ==================================================
            // LOADING
            // ==================================================

            if (provider.isLoadingContents &&
                provider.selectedCategory == null) {
              return _buildLoading();
            }

            // ==================================================
            // ERROR
            // ==================================================

            if (provider.contentError != null &&
                provider.selectedCategory == null) {
              return _buildError(provider);
            }

            // ==================================================
            // DATA
            // ==================================================

            final Map<String, dynamic>? data = provider.selectedCategory;

            if (data == null) {
              return _buildLoading();
            }

            final dynamic rawContents = data['contents'];

            final List<dynamic> contents = rawContents is List
                ? rawContents
                : <dynamic>[];

            // ==================================================
            // EMPTY
            // ==================================================

            if (contents.isEmpty) {
              return _buildEmpty();
            }

            // ==================================================
            // CATEGORY IMAGE
            // ==================================================

            final dynamic rawCategory = data['category'];

            String categoryImage = '';
            String backgroundImage = '';

            if (rawCategory is Map) {
              categoryImage = rawCategory['image']?.toString().trim() ?? '';
              backgroundImage =
                  rawCategory['background_image']?.toString().trim() ?? '';
            }

            // Use the same full-screen layout previously used by
            // World of Reptiles whenever the API provides a background.
            final bool hasBackgroundImage = backgroundImage.isNotEmpty;

            // ==================================================
            // INITIAL PRELOAD
            // ==================================================

            if (_preloadedImages.isEmpty && _preloadingImages.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                _preloadInitialImages(contents);
              });
            }

            // ==================================================
            // INDEX SAFETY
            // ==================================================

            if (_currentIndex >= contents.length) {
              _currentIndex = contents.length - 1;
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                if (hasBackgroundImage)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = constraints.maxWidth;
                      final alignmentX = screenWidth < 400
                          ? -1.0
                          : screenWidth < 600
                          ? -0.6
                          : screenWidth < 900
                          ? -0.2
                          : 0.0;

                      return CachedNetworkImage(
                        imageUrl: backgroundImage,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        fit: BoxFit.cover,
                        alignment: Alignment(alignmentX, 0),
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholder: (context, url) => const SizedBox.expand(),
                        errorWidget: (context, url, error) {
                          debugPrint(
                            'GK MASTER BACKGROUND IMAGE ERROR: $error',
                          );
                          return const SizedBox.expand();
                        },
                      );
                    },
                  ),
                SafeArea(
                  top: false,
                  bottom: false,
                  child: Column(
                    children: [
                      // ==================================================
                      // APP BAR
                      // ==================================================
                      _buildAppBar(
                        categoryImage: categoryImage,
                        contents: contents,
                        hasBackgroundImage: hasBackgroundImage,
                      ),

                      // ==================================================
                      // IMAGE AREA
                      // ==================================================
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Padding(
                              padding: EdgeInsets.only(
                                top: hasBackgroundImage ? 0 : 18,
                              ),
                              child: SizedBox(
                                width: constraints.maxWidth,
                                height: constraints.maxHeight,
                                child: PageView.builder(
                                  controller: _pageController,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: contents.length + 2,

                                  onPageChanged: (pageIndex) {
                                    final int realIndex =
                                        (pageIndex - 1 + contents.length) %
                                        contents.length;

                                    _resetZoom();

                                    setState(() {
                                      _currentIndex = realIndex;
                                    });

                                    if (pageIndex == 0) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            if (mounted &&
                                                _pageController.hasClients) {
                                              _pageController.jumpToPage(
                                                contents.length,
                                              );
                                            }
                                          });
                                    } else if (pageIndex ==
                                        contents.length + 1) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            if (mounted &&
                                                _pageController.hasClients) {
                                              _pageController.jumpToPage(1);
                                            }
                                          });
                                    }

                                    _preloadNearbyImages(contents, realIndex);
                                  },

                                  itemBuilder: (context, pageIndex) {
                                    final int index =
                                        (pageIndex - 1 + contents.length) %
                                        contents.length;

                                    final dynamic rawContent = contents[index];

                                    if (rawContent is! Map) {
                                      return const SizedBox();
                                    }

                                    final Map<String, dynamic> content =
                                        Map<String, dynamic>.from(rawContent);

                                    final String imageUrl =
                                        content['file_url']
                                            ?.toString()
                                            .trim() ??
                                        '';

                                    if (imageUrl.isEmpty) {
                                      return _buildImageError();
                                    }

                                    // The transparent header takes space above the
                                    // content image. Lift the poster slightly so its
                                    // visual centre sits closer to the screen centre.
                                    return Transform.translate(
                                      offset: Offset(
                                        0,
                                        hasBackgroundImage ? -40 : 0,
                                      ),
                                      child: _buildFixedZoomImage(imageUrl),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // ==================================================
                      // BOTTOM CONTROLS
                      // ==================================================
                      SafeArea(
                        top: false,
                        bottom: true,
                        child: _buildBottomControls(
                          currentIndex: _currentIndex,
                          totalImages: contents.length,
                          hasBackgroundImage: hasBackgroundImage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildAppBar({
    required String categoryImage,
    required List<dynamic> contents,
    required bool hasBackgroundImage,
  }) {
    if (hasBackgroundImage) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          MediaQuery.of(context).padding.top + 12,
          18,
          12,
        ),
        child: Row(
          children: [
            // BACK BUTTON
            _buildTransparentAppBarIcon(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),

            const SizedBox(width: 12),

            // GLASS CAPSULE TITLE
            Expanded(
              child: Container(
                height: 64,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.65),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.28),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // CATEGORY IMAGE
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 2,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: categoryImage.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: categoryImage,
                                    fit: BoxFit.cover,
                                    fadeInDuration: Duration.zero,
                                    fadeOutDuration: Duration.zero,
                                    useOldImageOnUrlChange: true,
                                    placeholder: (context, url) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      );
                                    },
                                    errorWidget: (context, url, error) {
                                      return const Icon(
                                        Icons.image_outlined,
                                        color: Color(0xFF777777),
                                        size: 24,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.image_outlined,
                                    color: Color(0xFF777777),
                                    size: 24,
                                  ),
                          ),

                          const SizedBox(width: 7),

                          // CATEGORY NAME
                          Expanded(
                            child: Text(
                              widget.categoryName,
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.05,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // GRID BUTTON
            _buildTransparentAppBarIcon(
              icon: Icons.grid_view_rounded,
              onTap: () => _openGrid(contents, categoryImage),
            ),
          ],
        ),
      );
    }

    return _buildDefaultAppBar(
      categoryImage: categoryImage,
      contents: contents,
    );
  }

  Widget _buildTransparentAppBarIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 30),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      splashRadius: 24,
    );
  }

  // Existing header design for all other categories.
  Widget _buildDefaultAppBar({
    required String categoryImage,
    required List<dynamic> contents,
  }) {
    return Container(
      width: double.infinity,

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [
            Color(0xFF7B2FF7),
            Color(0xFFF72585),
            Color(0xFFFF4D4D),
            Color(0xFFFF9F1C),
          ],
        ),
      ),

      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          MediaQuery.of(context).padding.top + 12,
          18,
          18,
        ),

        child: Row(
          children: [
            // ==================================================
            // BACK BUTTON
            // ==================================================
            _buildAppBarCircleButton(
              icon: Icons.arrow_back_ios_new_rounded,

              onTap: () {
                Navigator.pop(context);
              },
            ),

            const SizedBox(width: 8),

            // ==================================================
            // CATEGORY TITLE
            // ==================================================
            Expanded(
              child: Container(
                height: 64,
                padding: const EdgeInsets.all(2),

                // Outer curved border
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.65),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),

                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.28),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1,
                        ),
                      ),

                      child: Row(
                        children: [
                          // =========================================
                          // CATEGORY IMAGE
                          // =========================================
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 2,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,

                            child: categoryImage.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: categoryImage,
                                    fit: BoxFit.cover,
                                    fadeInDuration: Duration.zero,
                                    fadeOutDuration: Duration.zero,
                                    useOldImageOnUrlChange: true,

                                    placeholder: (context, url) {
                                      return Center(
                                        child: Lottie.asset(
                                          'assets/animations/loading_text.json',
                                          width: 225,
                                          height: 225,
                                          fit: BoxFit.contain,
                                        ),
                                      );
                                    },

                                    errorWidget: (context, url, error) {
                                      return const Icon(
                                        Icons.image_outlined,
                                        color: Color(0xFF777777),
                                        size: 24,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.image_outlined,
                                    color: Color(0xFF777777),
                                    size: 24,
                                  ),
                          ),

                          const SizedBox(width: 7),

                          // =========================================
                          // CATEGORY NAME
                          // =========================================
                          Expanded(
                            child: Text(
                              widget.categoryName,
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.visible,

                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.05,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // ==================================================
            // GRID BUTTON
            // ==================================================
            _buildAppBarCircleButton(
              icon: Icons.grid_view_rounded,

              onTap: () {
                _openGrid(contents, categoryImage);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR CIRCLE BUTTON
  // ============================================================

  Widget _buildAppBarCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: 52,
        height: 52,

        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.13),

          shape: BoxShape.circle,

          border: Border.all(color: Colors.white.withOpacity(0.18)),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),

              blurRadius: 12,

              offset: const Offset(0, 5),
            ),
          ],
        ),

        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }

  // ============================================================
  // FIXED IMAGE + ZOOM
  // ============================================================

  Widget _buildFixedZoomImage(String imageUrl) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;

        return Center(
          child: InteractiveViewer(
            panEnabled: false,
            scaleEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            scaleFactor: 200.0,
            transformationController: _transformationController,
            boundaryMargin: EdgeInsets.zero,
            constrained: true,
            clipBehavior: Clip.none,

            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: availableWidth,
                maxHeight: availableHeight,
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                useOldImageOnUrlChange: true,

                placeholder: (context, url) {
                  return Center(
                    child: Lottie.asset(
                      'assets/animations/loading_text.json',
                      width: 225,
                      height: 225,
                      fit: BoxFit.contain,
                    ),
                  );
                },

                imageBuilder: (context, imageProvider) {
                  return Image(
                    image: imageProvider,
                    width: availableWidth,
                    height: availableHeight,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                  );
                },

                errorWidget: (context, url, error) {
                  debugPrint('GK MASTER IMAGE ERROR: $error');
                  return _buildImageError();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BOTTOM CONTROLS
  // ============================================================

  Widget _buildBottomControls({
    required int currentIndex,
    required int totalImages,
    required bool hasBackgroundImage,
  }) {
    if (hasBackgroundImage) {
      return const SizedBox.shrink();
    }

    final bool canGoPrevious = totalImages > 0;

    final bool canGoNext = totalImages > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),

      child: Row(
        children: [
          // ==================================================
          // PREVIOUS
          // ==================================================
          Expanded(
            child: _buildNavigationButton(
              icon: Icons.arrow_back_rounded,

              label: 'Previous',

              enabled: canGoPrevious,

              onTap: canGoPrevious ? _previousImage : null,
            ),
          ),

          const SizedBox(width: 14),

          // ==================================================
          // NEXT
          // ==================================================
          Expanded(
            child: _buildNavigationButton(
              icon: Icons.arrow_forward_rounded,

              label: 'Next',

              enabled: canGoNext,

              onTap: canGoNext
                  ? () {
                      _nextImage(totalImages);
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAVIGATION BUTTON
  // ============================================================

  Widget _buildNavigationButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    final bool isPrevious = label.toLowerCase() == 'previous';

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: isPrevious
                      ? const [Color(0xFFEB2525), Color(0xFFED3A3A)]
                      : const [Color(0xFF16A34A), Color(0xFF22C55E)],
                )
              : null,

          color: enabled ? null : const Color(0xFFF0F1F4),

          borderRadius: BorderRadius.circular(18),

          border: Border.all(
            color: enabled ? Colors.transparent : const Color(0xFFE2E3E8),
          ),

          boxShadow: enabled
              ? [
                  BoxShadow(
                    color:
                        (isPrevious
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF16A34A))
                            .withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled ? Colors.white : const Color(0xFFB4B6BE),
            ),

            const SizedBox(width: 8),

            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: enabled ? Colors.white : const Color(0xFFB4B6BE),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Center(
      child: Lottie.asset(
        'assets/animations/loading_text.json',
        width: 225,
        height: 225,
        fit: BoxFit.contain,
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(GKMasterProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(
              Icons.error_outline_rounded,

              size: 55,

              color: Color(0xFFF72585),
            ),

            const SizedBox(height: 14),

            Text(
              provider.contentError ?? 'Failed to load images.',

              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 16,

                fontWeight: FontWeight.w600,

                color: Color(0xFF30323A),
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: () {
                provider.loadCategoryContents(widget.categoryId);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF72585),

                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),

              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(
              Icons.image_not_supported_outlined,

              size: 60,

              color: Color(0xFFB5B7BF),
            ),

            const SizedBox(height: 15),

            const Text(
              'No images available in this category.',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 17,

                fontWeight: FontWeight.w600,

                color: Color(0xFF30323A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE ERROR
  // ============================================================

  Widget _buildImageError() {
    return Container(
      width: double.infinity,

      height: double.infinity,

      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),

        borderRadius: BorderRadius.circular(16),
      ),

      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,

          size: 60,

          color: Color(0xFFB4B6BE),
        ),
      ),
    );
  }
}
