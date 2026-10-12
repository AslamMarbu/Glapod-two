import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gk_master_visual_provider.dart';
import 'gk_master_images.dart';

class GKMasterHomePage extends StatefulWidget {
  const GKMasterHomePage({super.key});

  @override
  State<GKMasterHomePage> createState() => _GKMasterHomePageState();
}

class _GKMasterHomePageState extends State<GKMasterHomePage> {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final PageController _aroundUsController = PageController(
    viewportFraction: 0.88,
  );

  // ============================================================
  // TIMER
  // ============================================================

  Timer? _aroundUsTimer;

  // ============================================================
  // INDEX
  // ============================================================

  int _aroundUsIndex = 0;
  int _lastCategoryCount = 0;

  // ============================================================
  // INFINITE SCROLL
  // ============================================================

  static const int _infiniteStartPage = 10000;

  // ============================================================
  // IMAGE PRELOAD STATE
  // ============================================================

  final Set<String> _preloadingImages = <String>{};
  final Set<String> _preloadedImages = <String>{};

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;

      context.read<GKMasterProvider>().loadCategories();
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _aroundUsTimer?.cancel();
    _aroundUsController.dispose();

    _preloadingImages.clear();
    _preloadedImages.clear();

    super.dispose();
  }

  // ============================================================
  // OPEN CATEGORY
  // ============================================================

  void _openCategory(Map<String, dynamic> category) {
    final dynamic categoryId = category['id'];

    if (categoryId == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GKMasterImagesPage(
          categoryId: categoryId,
          categoryName: category['category']?.toString() ?? '',
        ),
      ),
    );
  }

  // ============================================================
  // START AUTO SLIDER
  // ============================================================

  void _startAutoSlider(int categoryCount) {
    if (categoryCount <= 0) {
      return;
    }

    if (_lastCategoryCount == categoryCount && _aroundUsTimer != null) {
      return;
    }

    _lastCategoryCount = categoryCount;

    _aroundUsTimer?.cancel();
    _aroundUsTimer = null;

    if (categoryCount <= 1) {
      _precacheInitialCategories(categoryCount);
      return;
    }

    _aroundUsTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_aroundUsController.hasClients) {
        return;
      }

      final double? page = _aroundUsController.page;

      if (page == null) {
        return;
      }

      final int nextPage = page.round() + 1;

      _aroundUsController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });

    _initializeInfiniteCarousel(categoryCount);

    _precacheInitialCategories(categoryCount);
  }

  // ============================================================
  // INITIALIZE INFINITE CAROUSEL
  // ============================================================

  void _initializeInfiniteCarousel(int categoryCount) {
    if (categoryCount <= 0) {
      return;
    }

    final int startPage =
        _infiniteStartPage - (_infiniteStartPage % categoryCount);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (_aroundUsController.hasClients) {
        _aroundUsController.jumpToPage(startPage);
      }
    });
  }

  // ============================================================
  // INITIAL PRELOAD
  // ============================================================

  void _precacheInitialCategories(int categoryCount) {
    final provider = context.read<GKMasterProvider>();

    final List<dynamic> categories = provider.categories;

    if (categories.isEmpty) {
      return;
    }

    final int count = categoryCount < 4 ? categoryCount : 4;

    for (int i = 0; i < count; i++) {
      _precacheCategoryImage(categories[i]);
    }
  }

  // ============================================================
  // PRELOAD CATEGORY IMAGE
  // ============================================================

  void _precacheCategoryImage(dynamic category) {
    if (!mounted) {
      return;
    }

    if (category is! Map) {
      return;
    }

    final String image = category['image']?.toString().trim() ?? '';

    if (image.isEmpty) {
      return;
    }

    if (_preloadedImages.contains(image)) {
      return;
    }

    if (_preloadingImages.contains(image)) {
      return;
    }

    _preloadingImages.add(image);

    final int cacheWidth = _categoryCacheWidth(context);

    precacheImage(
          CachedNetworkImageProvider(image, maxWidth: cacheWidth),
          context,
        )
        .then((_) {
          if (!mounted) {
            return;
          }

          _preloadedImages.add(image);
          _preloadingImages.remove(image);
        })
        .catchError((error) {
          debugPrint('GK CATEGORY PRELOAD ERROR: $error');

          _preloadingImages.remove(image);
        });
  }

  // ============================================================
  // PRELOAD NEARBY
  // ============================================================

  void _precacheNearby(List<dynamic> categories, int currentIndex) {
    if (categories.isEmpty) {
      return;
    }

    // Previous image
    final int previous = currentIndex - 1;

    if (previous >= 0) {
      _precacheCategoryImage(categories[previous]);
    }

    // Next 3 images
    for (int i = 1; i <= 3; i++) {
      final int next = currentIndex + i;

      if (next < categories.length) {
        _precacheCategoryImage(categories[next]);
      }
    }

    // Infinite carousel wrap
    if (currentIndex >= categories.length - 2) {
      for (int i = 0; i < 2; i++) {
        if (i < categories.length) {
          _precacheCategoryImage(categories[i]);
        }
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Consumer<GKMasterProvider>(
          builder: (context, provider, child) {
            // ----------------------------------------------------
            // LOADING
            // ----------------------------------------------------

            if (provider.isLoadingCategories && provider.categories.isEmpty) {
              return _buildLoading();
            }

            // ----------------------------------------------------
            // EMPTY
            // ----------------------------------------------------

            if (provider.categories.isEmpty) {
              return _buildEmptyState(provider);
            }

            final List<dynamic> categories = provider.categories;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              _startAutoSlider(categories.length);
            });

            return RefreshIndicator(
              color: const Color(0xFF3F51B5),

              onRefresh: () async {
                await provider.refreshCategories();

                if (!mounted) {
                  return;
                }

                _lastCategoryCount = 0;

                _aroundUsTimer?.cancel();
                _aroundUsTimer = null;

                _aroundUsIndex = 0;

                _preloadingImages.clear();
                _preloadedImages.clear();

                if (_aroundUsController.hasClients) {
                  _aroundUsController.jumpToPage(0);
                }
              },

              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),

                slivers: [
                  // ------------------------------------------------
                  // TOP BAR
                  // ------------------------------------------------
                  SliverToBoxAdapter(child: _buildTopBar()),

                  // ------------------------------------------------
                  // SECTION
                  // ------------------------------------------------
                  SliverToBoxAdapter(
                    child: _buildSectionHeading(title: 'World Around Us'),
                  ),

                  // ------------------------------------------------
                  // FEATURED SLIDER
                  // ------------------------------------------------
                  SliverToBoxAdapter(
                    child: _buildFeaturedSlider(
                      categories: categories,
                      controller: _aroundUsController,
                      currentIndex: _aroundUsIndex,
                      onPageChanged: (index) {
                        setState(() {
                          _aroundUsIndex = index;
                        });

                        _precacheNearby(categories, index);
                      },
                    ),
                  ),

                  // ------------------------------------------------
                  // INDICATOR
                  // ------------------------------------------------
                  SliverToBoxAdapter(
                    child: _buildCategoryIndicator(
                      categories.length,
                      _aroundUsIndex,
                    ),
                  ),

                  // ------------------------------------------------
                  // ALL CATEGORIES
                  // ------------------------------------------------
                  SliverToBoxAdapter(child: _buildAllCategories(categories)),

                  const SliverToBoxAdapter(child: SizedBox(height: 35)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF202124),
              ),
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Text(
              'GK Master',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202124),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADING
  // ============================================================

  Widget _buildSectionHeading({required String title}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          height: 1.1,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  // ============================================================
  // FEATURED SLIDER
  // ============================================================

  Widget _buildFeaturedSlider({
    required List<dynamic> categories,
    required PageController controller,
    required int currentIndex,
    required ValueChanged<int> onPageChanged,
  }) {
    if (categories.isEmpty) {
      return const SizedBox();
    }

    return SizedBox(
      height: 205,
      child: PageView.builder(
        controller: controller,
        itemCount: 100000,
        physics: const BouncingScrollPhysics(),

        onPageChanged: (pageIndex) {
          final int realIndex = pageIndex % categories.length;

          onPageChanged(realIndex);
        },

        itemBuilder: (context, pageIndex) {
          final int categoryIndex = pageIndex % categories.length;

          final dynamic rawCategory = categories[categoryIndex];

          if (rawCategory is! Map) {
            return const SizedBox();
          }

          final Map<String, dynamic> category = Map<String, dynamic>.from(
            rawCategory,
          );

          final String title = category['category']?.toString() ?? '';

          final String image = category['image']?.toString().trim() ?? '';

          return GestureDetector(
            onTap: () {
              _openCategory(category);
            },

            child: Container(
              margin: const EdgeInsets.only(right: 12),

              decoration: BoxDecoration(
                color: const Color(0xFFE9ECF5),
                borderRadius: BorderRadius.circular(28),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),

              clipBehavior: Clip.antiAlias,

              child: Stack(
                fit: StackFit.expand,

                children: [
                  // ==================================================
                  // IMAGE
                  // ==================================================
                  image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: image,

                          fit: BoxFit.cover,

                          memCacheWidth: _categoryCacheWidth(context),

                          filterQuality: FilterQuality.medium,

                          fadeInDuration: Duration.zero,

                          fadeOutDuration: Duration.zero,

                          useOldImageOnUrlChange: true,

                          // IMPORTANT:
                          // Do not show a spinner while disk cache
                          // is being checked.
                          placeholder: (context, url) {
                            return Container(
                              color: const Color(0xFFE9ECF5),
                              child: _buildImageLoading(),
                            );
                          },

                          errorWidget: (context, url, error) {
                            debugPrint('GK CATEGORY IMAGE ERROR: $error');

                            return const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 50,
                                color: Color(0xFF9EA3B0),
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 50,
                            color: Color(0xFF9EA3B0),
                          ),
                        ),

                  // ==================================================
                  // GRADIENT
                  // ==================================================
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.72),
                            ],
                            stops: const [0.45, 0.62, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ==================================================
                  // TITLE
                  // ==================================================
                  Positioned(
                    left: 20,
                    right: 16,
                    bottom: 17,

                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,

                      children: [
                        Expanded(
                          child: Text(
                            title,

                            maxLines: 2,

                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Container(
                          width: 40,
                          height: 40,

                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),

                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
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

  // ============================================================
  // CATEGORY CACHE WIDTH
  // ============================================================

  int _categoryCacheWidth(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    final double width = screenWidth * 0.90 * pixelRatio;

    return width.round();
  }

  // ============================================================
  // CATEGORY INDICATOR
  // ============================================================

  Widget _buildCategoryIndicator(int categoryCount, int currentIndex) {
    final int visibleCount = categoryCount > 7 ? 7 : categoryCount;

    return Padding(
      padding: const EdgeInsets.only(top: 13, bottom: 5),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,

        children: List.generate(visibleCount, (index) {
          int actualIndex = index;

          if (categoryCount > 7) {
            final int start = (currentIndex - 3).clamp(0, categoryCount - 7);

            actualIndex = start + index;
          }

          final bool selected = actualIndex == currentIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),

            margin: const EdgeInsets.symmetric(horizontal: 3),

            width: selected ? 24 : 7,
            height: 7,

            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF3F51B5)
                  : const Color(0xFFD0D3DA),

              borderRadius: BorderRadius.circular(10),
            ),
          );
        }),
      ),
    );
  }

  // ============================================================
  // ALL CATEGORIES
  // ============================================================

  Widget _buildAllCategories(List<dynamic> categories) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'All Categories',

            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,

            physics: const NeverScrollableScrollPhysics(),

            itemCount: categories.length,

            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),

            itemBuilder: (context, index) {
              final dynamic rawCategory = categories[index];

              if (rawCategory is! Map) {
                return const SizedBox();
              }

              final Map<String, dynamic> category = Map<String, dynamic>.from(
                rawCategory,
              );

              final String title = category['category']?.toString() ?? '';

              final String image = category['image']?.toString().trim() ?? '';

              return GestureDetector(
                onTap: () {
                  _openCategory(category);
                },

                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(20),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.055),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),

                  clipBehavior: Clip.antiAlias,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // ============================================
                      // IMAGE
                      // ============================================
                      Expanded(
                        child: Container(
                          width: double.infinity,

                          color: const Color(0xFFF0F1F5),

                          child: image.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: image,

                                  fit: BoxFit.cover,

                                  memCacheWidth: _gridCacheWidth(context),

                                  filterQuality: FilterQuality.medium,

                                  fadeInDuration: Duration.zero,

                                  fadeOutDuration: Duration.zero,

                                  useOldImageOnUrlChange: true,

                                  placeholder: (context, url) {
                                    return Container(
                                      color: const Color(0xFFE9ECF5),
                                      child: _buildImageLoading(),
                                    );
                                  },

                                  errorWidget: (context, url, error) {
                                    return const Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Color(0xFF9EA3B0),
                                        size: 35,
                                      ),
                                    );
                                  },
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: Color(0xFF9EA3B0),
                                    size: 35,
                                  ),
                                ),
                        ),
                      ),

                      // ============================================
                      // TITLE
                      // ============================================
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),

                        child: Text(
                          title,

                          maxLines: 2,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF202124),
                            height: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GRID CACHE WIDTH
  // ============================================================

  int _gridCacheWidth(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    final double width = screenWidth * 0.46 * pixelRatio;

    return width.round();
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Center(
      child: Lottie.asset(
        'assets/animations/loading_text.json',
        width: 150,
        height: 150,
        fit: BoxFit.contain,
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState(GKMasterProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 60,
              color: Color(0xFF3F51B5),
            ),

            const SizedBox(height: 15),

            const Text(
              'No GK Master categories available.',
              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: provider.loadCategories,

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F51B5),
                foregroundColor: Colors.white,
              ),

              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageLoading() {
    return Center(
      child: Lottie.asset(
        'assets/animations/loading_text.json',
        width: 70,
        height: 70,
        fit: BoxFit.contain,
      ),
    );
  }
}
