import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gk_master_model.dart';
import '../providers/gk_master_provider.dart';
import 'gk_quiz_page.dart';

class GKMasterPage extends StatefulWidget {
  const GKMasterPage({super.key});

  @override
  State<GKMasterPage> createState() => _GKMasterPageState();
}

class _GKMasterPageState extends State<GKMasterPage> {
  void _showComingSoonDialog(BuildContext context, String categoryName) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    size: 38,
                    color: Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  categoryName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF24243A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Questions for this category are coming soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF7A7A92),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5E4AE3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Okay'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GkProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),

      body: Consumer<GkProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingCategories &&
              provider.selectedCategory == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.zones.isEmpty) {
            return _errorView(provider);
          }

          return Column(
            children: [
              _buildHeader(context, provider),

              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _currentContent(provider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _currentContent(GkProvider provider) {
    // STEP 1: CATEGORY
    if (provider.selectedCategory == null) {
      return _categorySection(
        key: const ValueKey('categories'),
        provider: provider,
      );
    }

    // Loading zones after category selection
    if (provider.isLoadingZones) {
      return const Center(
        key: ValueKey('zone-loading'),
        child: CircularProgressIndicator(),
      );
    }

    // STEP 2: ZONE
    if (provider.selectedZone == null) {
      return _zoneSection(key: const ValueKey('zones'), provider: provider);
    }

    // STEP 3: LEVEL
    return _levelSection(key: const ValueKey('levels'), provider: provider);
  }

  Widget _buildHeader(BuildContext context, GkProvider provider) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B4BEB), Color(0xFF8B6EF3)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () {
                    if (provider.selectedZone != null) {
                      provider.goBackToZones();
                    } else if (provider.selectedCategory != null) {
                      provider.goBackToCategories();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    _appBarTitle(provider),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),

                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _appBarTitle(GkProvider provider) {
    if (provider.selectedCategory == null) {
      return 'Quiz Master';
    }

    if (provider.selectedZone == null) {
      return provider.selectedCategory!.name;
    }

    return provider.selectedZone!.name;
  }

  String _headerTitle(GkProvider provider) {
    if (provider.selectedCategory == null) {
      return 'Choose your category';
    }

    if (provider.selectedZone == null) {
      return provider.selectedCategory!.name;
    }

    return provider.selectedZone!.name;
  }

  String _headerSubtitle(GkProvider provider) {
    if (provider.selectedCategory == null) {
      return 'Select a category and begin your knowledge challenge.';
    }

    if (provider.selectedZone == null) {
      return 'Choose a zone for the selected category.';
    }

    return 'Choose your difficulty level and start the quiz.';
  }

  Widget _progressSteps(GkProvider provider) {
    final currentStep = provider.selectedCategory == null
        ? 1
        : provider.selectedZone == null
        ? 2
        : 3;

    return Row(
      children: [
        _stepItem(number: 1, label: 'Category', active: currentStep >= 1),

        _stepLine(active: currentStep >= 2),

        _stepItem(number: 2, label: 'Zone', active: currentStep >= 2),

        _stepLine(active: currentStep >= 3),

        _stepItem(number: 3, label: 'Level', active: currentStep >= 3),
      ],
    );
  }

  Widget _stepItem({
    required int number,
    required String label,
    required bool active,
  }) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: active
              ? Icon(
                  number == 1
                      ? Icons.category_rounded
                      : number == 2
                      ? Icons.public_rounded
                      : Icons.bar_chart_rounded,
                  size: 17,
                  color: const Color(0xFF5E4AE3),
                )
              : Text('$number', style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: active ? 1 : 0.65),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _stepLine({required bool active}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(left: 8, right: 8, bottom: 20),
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _zoneSection({required Key key, required GkProvider provider}) {
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 30),
      children: [
        const Text(
          'Available zones',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF24243A),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Explore questions from different knowledge areas.',
          style: TextStyle(color: Color(0xFF7A7A92), fontSize: 14),
        ),
        const SizedBox(height: 20),
        ...provider.zones.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _zoneCard(
              zone: entry.value,
              index: entry.key,
              onTap: () {
                provider.selectZone(entry.value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _zoneCard({
    required GkZone zone,
    required int index,
    required VoidCallback onTap,
  }) {
    final designs = [
      const _ZoneDesign(
        colors: [Color(0xFFFF7E5F), Color(0xFFFFB16A)],
        icon: Icons.flag_rounded,
      ),
      const _ZoneDesign(
        colors: [Color(0xFF00B4DB), Color(0xFF5BD1F2)],
        icon: Icons.language_rounded,
      ),
      const _ZoneDesign(
        colors: [Color(0xFF7F53AC), Color(0xFFB58AE8)],
        icon: Icons.public_rounded,
      ),
    ];

    final design = designs[index % designs.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: design.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: design.colors.first.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(design.icon, color: Colors.white, size: 29),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Tap to choose this zone',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categorySection({required Key key, required GkProvider provider}) {
    if (provider.isLoadingCategories) {
      return const Center(
        key: ValueKey('category-loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (provider.categories.isEmpty) {
      return const Center(
        key: ValueKey('empty-categories'),
        child: Text('No categories found for this zone.'),
      );
    }

    return ListView.builder(
      key: key,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 30),
      itemCount: provider.categories.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _categoryCard(
            category: provider.categories[index],
            index: index,
            onTap: () async {
              final category = provider.categories[index];

              if (category.totalQuestions <= 0) {
                _showComingSoonDialog(context, category.name);
                return;
              }

              await provider.selectCategory(category);
            },
          ),
        );
      },
    );
  }

  Widget _categoryCard({
    required GkCategory category,
    required int index,
    required VoidCallback onTap,
  }) {
    final colors = [
      const Color(0xFF5E5CE6),
      const Color(0xFF14B88A),
      const Color(0xFFE83E8C),
      const Color(0xFFFFA000),
      const Color(0xFF7C0AF5),
      const Color(0xFF00CFE8),
    ];

    final icons = [
      Icons.science_rounded,
      Icons.computer_rounded,
      Icons.history_edu_rounded,
      Icons.public_rounded,
      Icons.sports_soccer_rounded,
      Icons.auto_stories_rounded,
    ];

    final color = colors[index % colors.length];
    final icon = icons[index % icons.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: color.withValues(alpha: 0.28),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 31),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Text(
                  category.name,
                  softWrap: true,
                  maxLines: 4,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                    height: 1.25,
                  ),
                ),
              ),

              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _levelSection({required Key key, required GkProvider provider}) {
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 30),
      children: [
        _levelCard(
          title: 'Beginner',
          subtitle: 'Perfect for learning the basics',
          icon: Icons.sentiment_satisfied_alt_rounded,
          color: const Color(0xFF26A69A),
          difficulty: 1,
          onTap: () {
            _startQuiz(provider, 'beginner');
          },
        ),
        const SizedBox(height: 16),
        _levelCard(
          title: 'Intermediate',
          subtitle: 'Test your growing knowledge',
          icon: Icons.trending_up_rounded,
          color: const Color(0xFFFFA726),
          difficulty: 2,
          onTap: () {
            _startQuiz(provider, 'intermediate');
          },
        ),
        const SizedBox(height: 16),
        _levelCard(
          title: 'Advanced',
          subtitle: 'Challenge yourself with hard questions',
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFF05C75),
          difficulty: 3,
          onTap: () {
            _startQuiz(provider, 'advanced');
          },
        ),
      ],
    );
  }

  Widget _levelCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int difficulty,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withValues(alpha: 0.18)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color, size: 31),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF24243A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7A7A92),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(3, (index) {
                        return Container(
                          width: 22,
                          height: 5,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            color: index < difficulty
                                ? color
                                : color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow_rounded, color: color, size: 27),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startQuiz(GkProvider provider, String level) async {
    provider.selectLevel(level);

    final loaded = await provider.loadQuestions();

    if (!mounted) return;

    if (loaded) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GkQuizPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Unable to load GK questions.',
          ),
        ),
      );
    }
  }

  Widget _errorView(GkProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE8EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFFF05C75),
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load GK Master',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7A7A92)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (provider.selectedCategory != null) {
                  provider.loadZones();
                } else {
                  provider.loadCategories();
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E4AE3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneDesign {
  final List<Color> colors;
  final IconData icon;

  const _ZoneDesign({required this.colors, required this.icon});
}
