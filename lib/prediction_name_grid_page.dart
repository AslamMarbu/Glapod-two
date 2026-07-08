import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart'; // 🔹 Import Shimmer
import '../providers/prediction_name_provider.dart';
import '../services/student_service.dart';
import 'widgets.dart/appbar_page.dart';

class PredictionNameGridPage extends StatefulWidget {
  final String categoryName;
  final int categoryId;
  final String level;

  const PredictionNameGridPage({
    super.key,
    required this.categoryName,
    required this.categoryId,
    required this.level,
  });

  @override
  State<PredictionNameGridPage> createState() => _PredictionNameGridPageState();
}

class _PredictionNameGridPageState extends State<PredictionNameGridPage> {
  bool _isLoading = true;
  List<dynamic> _questions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchGridData();
  }

  Future<void> _fetchGridData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await StudentService.getGuessNameQuestionGrid(
      categoryId: widget.categoryId,
      level: widget.level,
    );

    if (mounted) {
      if (response['status'] == true) {
        setState(() {
          _questions = response['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? "Failed to load grid";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),

      appBar: CustomAppBar(
        height: 70,
        title: "${widget.categoryName} - Grid",
        isDashboard: false,
      ),

      body: _isLoading
          ? _buildShimmerGrid()
          : _errorMessage != null
          ? _buildErrorView()
          : _buildGridView(),
    );
  }

  // 🔹 NEW: SHIMMER SKELETON GRID
  Widget _buildShimmerGrid() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        physics: const NeverScrollableScrollPhysics(), // Keep it static
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1,
        ),
        itemCount: 15, // Show a reasonable number of placeholder boxes
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridView() {
    if (_questions.isEmpty) {
      return const Center(child: Text("No questions found for this level."));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1,
      ),
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        final item = _questions[index];
        final bool isAttended = item['is_attended'] ?? false;
        final String? imageUrl =
            item['images'] != null && item['images'].isNotEmpty
            ? item['images'][0]
            : null;

        return GestureDetector(
          onTap: () {
            context.read<PredictionGameProvider>().setManualQuestion(item);
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAttended
                    ? const Color(0xFF6BCF2E)
                    : const Color(0xFF1B75BB).withOpacity(0.3),
                width: isAttended ? 3.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, color: Colors.grey),
                    )
                  else
                    const Icon(Icons.image, color: Colors.grey),

                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  if (isAttended)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6BCF2E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          Text(_errorMessage!, textAlign: TextAlign.center),
          TextButton(onPressed: _fetchGridData, child: const Text("Retry")),
        ],
      ),
    );
  }
}
