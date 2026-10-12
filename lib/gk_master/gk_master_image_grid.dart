import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class GKMasterImageGridPage extends StatefulWidget {
  final List<dynamic> contents;
  final String categoryName;
  final String categoryImage;
  final int currentIndex;

  const GKMasterImageGridPage({
    super.key,
    required this.contents,
    required this.categoryName,
    required this.categoryImage,
    required this.currentIndex,
  });

  @override
  State<GKMasterImageGridPage> createState() => _GKMasterImageGridPageState();
}

class _GKMasterImageGridPageState extends State<GKMasterImageGridPage> {
  // ============================================================
  // SEARCH CONTROLLER
  // ============================================================

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // FILTERED CONTENTS
  // ============================================================

  List<dynamic> get _filteredContents {
    final String query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.contents;
    }

    return widget.contents.where((item) {
      if (item is! Map) {
        return false;
      }

      final String fileName = item['file_name']?.toString() ?? '';

      return fileName.toLowerCase().contains(query);
    }).toList();
  }

  // ============================================================
  // REMOVE FILE EXTENSION
  // ============================================================

  String _displayFileName(String fileName) {
    final String name = fileName.trim();

    return name.replaceFirst(
      RegExp(r'\.(jpg|jpeg|png|webp|gif|bmp)$', caseSensitive: false),
      '',
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final List<dynamic> filtered = _filteredContents;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      body: Column(
        children: [
          // ======================================================
          // APP BAR
          // ======================================================
          _buildAppBar(),

          // ======================================================
          // SEARCH + GRID
          // ======================================================
          Expanded(
            child: Column(
              children: [
                // ==================================================
                // SEARCH BOX
                // ==================================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: Container(
                    height: 50,

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(16),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.045),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: TextField(
                      controller: _searchController,

                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },

                      decoration: InputDecoration(
                        hintText: 'Search images',

                        hintStyle: const TextStyle(
                          color: Color(0xFF9EA3B0),
                          fontSize: 14,
                        ),

                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF3F51B5),
                        ),

                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                color: const Color(0xFF7A7F8C),
                                onPressed: () {
                                  _searchController.clear();

                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF3F51B5),
                            width: 1.2,
                          ),
                        ),

                        filled: true,

                        fillColor: Colors.white,

                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 4,
                        ),
                      ),
                    ),
                  ),
                ),

                // ==================================================
                // RESULT COUNT
                // ==================================================
                if (_searchQuery.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),

                    child: Align(
                      alignment: Alignment.centerLeft,

                      child: Text(
                        '${filtered.length} image${filtered.length == 1 ? '' : 's'} found',

                        style: const TextStyle(
                          color: Color(0xFF7A7F8C),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                // ==================================================
                // GRID
                // ==================================================
                Expanded(
                  child: filtered.isEmpty
                      ? _buildNoResults()
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),

                          physics: const BouncingScrollPhysics(),

                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,

                                crossAxisSpacing: 12,

                                mainAxisSpacing: 14,

                                childAspectRatio: 0.78,
                              ),

                          itemCount: filtered.length,

                          itemBuilder: (context, index) {
                            final dynamic item = filtered[index];

                            if (item is! Map) {
                              return const SizedBox();
                            }

                            final String imageUrl =
                                item['file_url']?.toString() ?? '';

                            final String fileName =
                                item['file_name']?.toString() ?? '';

                            // Find original position.
                            final int originalIndex = widget.contents.indexOf(
                              item,
                            );

                            return _buildGridCard(
                              imageUrl: imageUrl,

                              fileName: fileName,

                              isCurrent: originalIndex == widget.currentIndex,

                              onTap: () {
                                Navigator.pop(context, originalIndex);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildAppBar() {
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
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),

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

            const SizedBox(width: 14),

            // ==================================================
            // CATEGORY TITLE
            // ==================================================
            Expanded(
              child: Container(
                height: 64,

                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),

                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.10),

                  borderRadius: BorderRadius.circular(34),

                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),

                child: Row(
                  children: [
                    // ==================================================
                    // CATEGORY IMAGE
                    // ==================================================
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

                      child: widget.categoryImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.categoryImage,

                              fit: BoxFit.cover,

                              fadeInDuration: Duration.zero,

                              fadeOutDuration: Duration.zero,

                              useOldImageOnUrlChange: true,

                              placeholder: (context, url) {
                                return Center(
                                  child: Lottie.asset(
                                    'assets/animations/loading_text.json',
                                    width: 34,
                                    height: 34,
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

                    const SizedBox(width: 12),

                    // ==================================================
                    // CATEGORY NAME
                    // ==================================================
                    Expanded(
                      child: Text(
                        widget.categoryName,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 14),

            // ==================================================
            // GRID BUTTON
            // ==================================================
            _buildAppBarCircleButton(
              icon: Icons.grid_view_rounded,

              onTap: () {},
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
        width: 48,
        height: 48,

        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),

          shape: BoxShape.circle,

          border: Border.all(color: Colors.white.withOpacity(0.20)),
        ),

        child: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }

  // ============================================================
  // GRID CARD
  // ============================================================

  Widget _buildGridCard({
    required String imageUrl,
    required String fileName,
    required bool isCurrent,
    required VoidCallback onTap,
  }) {
    final String displayName = _displayFileName(fileName);

    return GestureDetector(
      onTap: onTap,

      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(18),

          border: isCurrent
              ? Border.all(color: const Color(0xFF3F51B5), width: 2)
              : null,

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.055),

              blurRadius: 14,

              offset: const Offset(0, 5),
            ),
          ],
        ),

        clipBehavior: Clip.antiAlias,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ==================================================
            // IMAGE
            // ==================================================
            Expanded(
              child: Stack(
                fit: StackFit.expand,

                children: [
                  imageUrl.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 44,
                            color: Color(0xFF9EA3B0),
                          ),
                        )
                      : Image.network(
                          imageUrl,

                          fit: BoxFit.cover,

                          filterQuality: FilterQuality.high,

                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }

                            return Center(
                              child: Lottie.asset(
                                'assets/animations/loading_text.json',
                                width: 55,
                                height: 55,
                                fit: BoxFit.contain,
                              ),
                            );
                          },

                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 44,
                                color: Color(0xFF9EA3B0),
                              ),
                            );
                          },
                        ),

                  // ==================================================
                  // CURRENT IMAGE INDICATOR
                  // ==================================================
                  if (isCurrent)
                    Positioned(
                      top: 9,
                      right: 9,

                      child: Container(
                        width: 27,
                        height: 27,

                        decoration: const BoxDecoration(
                          color: Color(0xFF3F51B5),
                          shape: BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ),

                  // ==================================================
                  // OPEN ICON
                  // ==================================================
                  Positioned(
                    right: 9,
                    bottom: 9,

                    child: Container(
                      width: 32,
                      height: 32,

                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.48),

                        shape: BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.open_in_full_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // IMAGE NAME
            // ==================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),

              child: Text(
                displayName.isEmpty ? 'Image' : displayName,

                maxLines: 2,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  fontSize: 13.5,

                  fontWeight: FontWeight.w600,

                  color: Color(0xFF202124),

                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NO RESULTS
  // ============================================================

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 72,
              height: 72,

              decoration: BoxDecoration(
                color: const Color(0xFF3F51B5).withOpacity(0.08),

                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.search_off_rounded,
                size: 34,
                color: Color(0xFF3F51B5),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No images found',

              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202124),
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'Try searching with another image name.',

              textAlign: TextAlign.center,

              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
