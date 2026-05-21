import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart'; // 🔹 Ensure shimmer is in pubspec.yaml
import '../providers/prediction_provider.dart';
import '../utils/app_colors.dart';
import 'widgets.dart/appbar_page.dart';
import 'prediction_name_page.dart';
import 'prediction_tense_page.dart';
import 'prediction_opposit_word.dart';

// --- REUSABLE SHIMMER COMPONENT ---
class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
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

  @override
  void initState() {
    super.initState();
    _sliderController = PageController(viewportFraction: 0.75, initialPage: 0);
    Future.microtask(() => context.read<PredictionProvider>().fetchCategories());
  }

  @override
  void dispose() {
    _sliderController.dispose();
    super.dispose();
  }

  void _navToName(String catName, int catId, String level) {
    final apiLevel = context.read<PredictionProvider>().mapToApi(level);
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PredictionNamePage(categoryName: catName, categoryId: catId, level: apiLevel),
    ));
  }

  void _navToTense(String level) {
    final apiLevel = context.read<PredictionProvider>().mapToApi(level);
    Navigator.push(context, MaterialPageRoute(builder: (_) => PredictionTensePage(level: apiLevel)));
  }

  void _navToOpposite(String level) {
    final apiLevel = context.read<PredictionProvider>().mapToApi(level);
    Navigator.push(context, MaterialPageRoute(builder: (_) => PredictionOppositePage(level: apiLevel)));
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PredictionProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF7),
      appBar: const CustomAppBar(height: 40, title: "Word Master", isDashboard: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 25),
        child: Column(
          children: [
            _buildAccordionSection(
              title: "Guess the name",
              initiallyExpanded: true,
              // 🔹 Shimmer for the horizontal slider
              content: pp.isLoading ? _buildSliderShimmer() : _buildCategoryRow(pp),
            ),
            const SizedBox(height: 20),
            _buildAccordionSection(
              title: "Verb Forms",
              // 🔹 Shimmer for the grid row
              content: pp.isLoading ? _buildGridShimmer() : _buildLevelGrid(pp, (lvl) => _navToTense(lvl)),
            ),
            const SizedBox(height: 20),
            _buildAccordionSection(
              title: "Antonyms",
              // 🔹 Shimmer for the grid row
              content: pp.isLoading ? _buildGridShimmer() : _buildLevelGrid(pp, (lvl) => _navToOpposite(lvl)),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 NEW: Shimmer for the Category Slider
  Widget _buildSliderShimmer() {
    double cardWidth = MediaQuery.of(context).size.width * 0.75;
    double cardHeight = cardWidth * (9 / 16);
    return SizedBox(
      height: cardHeight + 25,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 2,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 15),
          child: Column(
            children: [
              ShimmerPlaceholder(width: cardWidth, height: cardHeight, borderRadius: 20),
              const SizedBox(height: 10),
              const ShimmerPlaceholder(width: 80, height: 15),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 NEW: Shimmer for the 3-button Level Grid
  Widget _buildGridShimmer() {
    return Row(
      children: List.generate(3, (index) => const Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: ShimmerPlaceholder(width: double.infinity, height: 45, borderRadius: 12),
        ),
      )),
    );
  }

  Widget _buildCategoryRow(PredictionProvider pp) {
    if (pp.categories.isEmpty) return const Text("No categories found.");

    return SizedBox(
      height: (MediaQuery.of(context).size.width * 0.75) * (9 / 16) + 30,
      child: PageView.builder(
        controller: _sliderController,
        itemCount: pp.categories.length,
        clipBehavior: Clip.none,
        padEnds: true,
        itemBuilder: (context, index) {
          final cat = pp.categories[index];
          int safeId = int.tryParse(cat['id'].toString()) ?? 0;

          return AnimatedBuilder(
            animation: _sliderController,
            builder: (context, child) {
              double scale = 0.8;
              if (_sliderController.position.hasContentDimensions) {
                double page = _sliderController.page!;
                double diff = (page - index).abs();
                scale = (1.0 - (diff * 0.2)).clamp(0.8, 1.0);
              } else if (index == 0) {
                scale = 1.0;
              }

              return Transform.scale(
                scale: scale,
                child: _buildImageCategoryCard(
                  cat['subject'] ?? "Unknown",
                  safeId,
                  cat['image'] ?? "",
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildImageCategoryCard(String label, int id, String imageUrl) {
    return GestureDetector(
      onTap: () => _showLevelBottomSheet(label, id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
                image: imageUrl.isNotEmpty
                    ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: imageUrl.isEmpty
                  ? const Icon(Icons.image, color: Colors.grey, size: 40)
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF2D3142),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showLevelBottomSheet(String name, int id) {
    final pp = context.read<PredictionProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            _buildLevelGrid(pp, (lvl) => _navToName(name, id, lvl)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelGrid(PredictionProvider pp, Function(String) onTab) {
    return Row(
      children: pp.displayLabels.map((level) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(onTap: () => onTab(level), child: _buildBlueButton(level)),
        ),
      )).toList(),
    );
  }

  Widget _buildBlueButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
    );
  }

  Widget _buildAccordionSection({required String title, required Widget content, bool initiallyExpanded = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textHeadingBlack)),
          children: [Padding(padding: const EdgeInsets.only(left: 15, right: 15, bottom: 20), child: content)],
        ),
      ),
    );
  }
}