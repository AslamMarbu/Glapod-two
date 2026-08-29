import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/prediction_provider.dart';
import '../utils/app_colors.dart';
import 'widgets.dart/appbar_page.dart';
import 'prediction_name_page.dart';
import 'prediction_tense_page.dart';
import 'prediction_opposit_word.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  late PageController _sliderController;

  int _currentSliderIndex = 0;

  int _sliderBasePage = 10000;

  bool _showOtherSections = false;

  @override
  void initState() {
    super.initState();

    _sliderController = PageController(
      viewportFraction: 1.0,
      initialPage: _sliderBasePage,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoriesAndPrecacheImages();
    });
  }

  Future<void> _loadCategoriesAndPrecacheImages() async {
    final provider = context.read<PredictionProvider>();

    await provider.fetchCategories();

    if (!mounted || provider.categories.isEmpty) {
      return;
    }

    final int categoryCount = provider.categories.length;

    // Create a large page number which starts exactly
    // at the first real category.
    _sliderBasePage = 10000 - (10000 % categoryCount);

    if (mounted) {
      setState(() {
        _currentSliderIndex = 0;
      });
    }

    // After the slider has been built, move it to the
    // calculated base page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (_sliderController.hasClients) {
        _sliderController.jumpToPage(_sliderBasePage);
      }
    });

    final List<String> imageUrls = provider.categories
        .map((category) => (category['image'] ?? '').toString())
        .where((url) => url.isNotEmpty && url != 'null')
        .toList();

    if (imageUrls.isEmpty) {
      return;
    }

    // First image gets priority so initial display
    // becomes available as quickly as possible.
    try {
      await precacheImage(CachedNetworkImageProvider(imageUrls.first), context);
    } catch (error) {
      debugPrint('First prediction image pre-cache failed: $error');
    }

    if (!mounted) {
      return;
    }

    // Cache all remaining slider images in parallel.
    // This makes subsequent swipes much smoother.
    final List<Future<void>> cacheTasks = [];

    for (final String imageUrl in imageUrls.skip(1)) {
      cacheTasks.add(
        precacheImage(CachedNetworkImageProvider(imageUrl), context).catchError(
          (error) {
            debugPrint(
              'Prediction image pre-cache failed: '
              '$imageUrl, $error',
            );
          },
        ),
      );
    }

    await Future.wait(cacheTasks);
  }

  @override
  void dispose() {
    _sliderController.dispose();
    super.dispose();
  }

  void _navToName(String catName, int catId, String level) {
    final apiLevel = context.read<PredictionProvider>().mapToApi(level);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PredictionNamePage(
          categoryName: catName,
          categoryId: catId,
          level: apiLevel,
        ),
      ),
    );
  }

  void _navToTense(String level) {
    final apiLevel = context.read<PredictionProvider>().mapToApi(level);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PredictionTensePage(level: apiLevel)),
    );
  }

  void _navToOpposite(String level) {
    final apiLevel = context.read<PredictionProvider>().mapToApi(level);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PredictionOppositePage(level: apiLevel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PredictionProvider>();

    return Scaffold(
      appBar: const CustomAppBar(height: 70, title: "Word Master"),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEEF2F6),
                    Color.fromARGB(255, 254, 235, 175),
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 20),
                                pp.isLoading
                                    ? const ShimmerPlaceholder(
                                        width: double.infinity,
                                        height: 96,
                                        borderRadius: 28,
                                      )
                                    : _buildGuessNameExpandableCard(pp),
                                const SizedBox(height: 16),
                                _buildFeatureRowCard(
                                  title: "Verb Forms",
                                  description:
                                      "Select a level to start learning!",
                                  backgroundColor: const Color(0xFFFFFDF0),
                                  arrowColor: const Color(0xFFFFC107),
                                  avatarWidget: const Icon(
                                    Icons.edit_road_rounded,
                                    size: 40,
                                    color: Color(0xFFFFB300),
                                  ),
                                  isLoading: pp.isLoading,
                                  onTap: () => _showLevelBottomSheet(
                                    "Verb Forms",
                                    pp,
                                    (lvl) => _navToTense(lvl),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureRowCard(
                                  title: "Antonyms",
                                  description:
                                      "Select a level to start learning!",
                                  backgroundColor: const Color(0xFFE8F8F5),
                                  arrowColor: const Color(0xFF2ECC71),
                                  avatarWidget: const Icon(
                                    Icons.saved_search_rounded,
                                    size: 40,
                                    color: Color(0xFF27AE60),
                                  ),
                                  isLoading: pp.isLoading,
                                  onTap: () => _showLevelBottomSheet(
                                    "Antonyms",
                                    pp,
                                    (lvl) => _navToOpposite(lvl),
                                  ),
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuessNameExpandableCard(PredictionProvider pp) {
    const Color cardAccentColor = Color(0xFF6366F1);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5FF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD7CCFF), width: 2),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      size: 28,
                      color: cardAccentColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Name Hunt",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          "Swipe to explore topics",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),

          Column(
            children: [
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,

                        // Infinite looping slider
                        child: pp.categories.isEmpty
                            ? Shimmer.fromColors(
                                baseColor: const Color(0xFFE8E5F5),
                                highlightColor: const Color(0xFFF8F7FF),
                                child: Container(color: Colors.white),
                              )
                            : PageView.builder(
                                controller: _sliderController,

                                // No itemCount:
                                // allows continuous
                                // forward scrolling.
                                itemBuilder: (context, pageIndex) {
                                  final int realIndex =
                                      pageIndex % pp.categories.length;

                                  final cat = pp.categories[realIndex];

                                  final int safeId =
                                      int.tryParse(cat['id'].toString()) ?? 0;

                                  return _buildHeroSliderItem(
                                    cat['subject'] ?? "Flags",
                                    safeId,
                                    cat['image'] ?? "",
                                    pp,
                                  );
                                },

                                onPageChanged: (pageIndex) {
                                  if (pp.categories.isEmpty) {
                                    return;
                                  }

                                  final int realIndex =
                                      pageIndex % pp.categories.length;

                                  setState(() {
                                    _currentSliderIndex = realIndex;
                                  });

                                  final int nextIndex =
                                      (realIndex + 1) % pp.categories.length;

                                  _precacheNextImage(pp, nextIndex);
                                },
                              ),
                      ),
                    ),
                  ),

                  if (pp.categories.isNotEmpty)
                    Positioned(
                      top: 7,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.topic_rounded,
                              size: 14,
                              color: cardAccentColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              pp.categories[_currentSliderIndex]['subject'] ??
                                  "Flags",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  Positioned(
                    left: 26,
                    top: 0,
                    bottom: 16,
                    child: Center(
                      child: _buildSliderNavButton(
                        icon: Icons.keyboard_arrow_left_rounded,
                        onTap: () {
                          if (!_sliderController.hasClients ||
                              pp.categories.isEmpty) {
                            return;
                          }

                          _sliderController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ),

                  Positioned(
                    right: 26,
                    top: 0,
                    bottom: 16,
                    child: Center(
                      child: _buildSliderNavButton(
                        icon: Icons.keyboard_arrow_right_rounded,
                        onTap: () {
                          if (!_sliderController.hasClients ||
                              pp.categories.isEmpty) {
                            return;
                          }

                          _sliderController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSliderItem(
    String label,
    int id,
    String imageUrl,
    PredictionProvider pp,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showOtherSections = true;
        });

        _showLevelBottomSheet(
          label,
          pp,
          (level) => _navToName(label, id, level),
        );
      },

      child: imageUrl.isNotEmpty && imageUrl != 'null'
          ? CachedNetworkImage(
              imageUrl: imageUrl,

              width: double.infinity,

              height: double.infinity,

              fit: BoxFit.cover,

              alignment: Alignment.center,

              // Decode close to actual
              // rendered size.
              memCacheWidth: 900,

              // Shorter transition reduces
              // visible loading delay.
              fadeInDuration: const Duration(milliseconds: 80),

              fadeOutDuration: const Duration(milliseconds: 50),

              placeholderFadeInDuration: Duration.zero,

              placeholder: (context, url) {
                return Shimmer.fromColors(
                  baseColor: const Color(0xFFE8E5F5),
                  highlightColor: const Color(0xFFF8F7FF),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.white,
                  ),
                );
              },

              errorWidget: (context, url, error) {
                debugPrint('Prediction image failed: $url');

                debugPrint('Prediction image error: $error');

                return Container(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.05),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_rounded,
                    size: 36,
                    color: Color(0xFF94A3B8),
                  ),
                );
              },
            )
          : Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_not_supported_rounded,
                size: 36,
                color: Colors.grey,
              ),
            ),
    );
  }

  Widget _buildSliderNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF1E293B)),
      ),
    );
  }

  Widget _buildFeatureRowCard({
    required String title,
    required String description,
    required Color backgroundColor,
    required Color arrowColor,
    required Widget avatarWidget,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    if (isLoading) {
      return const ShimmerPlaceholder(
        width: double.infinity,
        height: 96,
        borderRadius: 28,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: arrowColor.withOpacity(0.35), width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: avatarWidget,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF1E293B).withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildRoundActionCircle(
              color: Colors.white,
              iconColor: arrowColor,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundActionCircle({
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: iconColor,
        ),
      ),
    );
  }

  void _showLevelBottomSheet(
    String title,
    PredictionProvider pp,
    Function(String) onLevelSelected,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.quiz_rounded,
                              color: Color(0xFF6366F1),
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Boost your verb skills",
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      ...pp.displayLabels.map(
                        (level) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildModernLevelCard(level, () {
                            Navigator.pop(context);

                            onLevelSelected(level);
                          }),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),

                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
      ),
      child: Center(
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildModernLevelCard(String level, VoidCallback onTap) {
    IconData icon;
    Color iconBg;
    Color borderColor;
    Color arrowBg;
    String subtitle;

    switch (level.toLowerCase()) {
      case "beginner":
        icon = Icons.eco_rounded;
        iconBg = const Color.fromARGB(255, 220, 255, 239);
        borderColor = const Color(0xFF22C55E);
        arrowBg = const Color.fromARGB(255, 220, 255, 239);
        subtitle = "Perfect for getting started";
        break;

      case "intermediate":
        icon = Icons.flash_on_rounded;
        iconBg = const Color(0xFFFFF7D6);
        borderColor = const Color(0xFFFACC15);
        arrowBg = const Color(0xFFFFF7D6);
        subtitle = "Improve your skills";
        break;

      default:
        icon = Icons.workspace_premium_rounded;
        iconBg = const Color(0xFFFFF1F2);
        borderColor = const Color(0xFFEF4444);
        arrowBg = const Color(0xFFFFF1F2);
        subtitle = "Challenge yourself";
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: const Color(0xFF6366F1), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: arrowBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: borderColor,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _precacheNextImage(
    PredictionProvider provider,
    int index,
  ) async {
    if (!mounted || provider.categories.isEmpty) {
      return;
    }

    final int safeIndex = index % provider.categories.length;

    final String imageUrl = (provider.categories[safeIndex]['image'] ?? '')
        .toString();

    if (imageUrl.isEmpty || imageUrl == 'null') {
      return;
    }

    try {
      await precacheImage(CachedNetworkImageProvider(imageUrl), context);
    } catch (error) {
      debugPrint('Next prediction image pre-cache failed: $error');
    }
  }
}
