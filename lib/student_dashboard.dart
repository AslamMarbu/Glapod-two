import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:glapod/study_subject_listing.dart';
import 'package:glapod/solved_papers_page.dart';
import 'package:glapod/prediction_page.dart';
import 'package:glapod/translator_page.dart';
import 'package:glapod/profile.dart';
import 'package:glapod/storage/local_storage_service.dart';
import 'package:glapod/utils/app_colors.dart';
import 'widgets.dart/gradient_button.dart';
import 'widgets.dart/appbar_page.dart';
import 'games_zone.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  String userName = "User";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final studentData = await LocalStorageService.getStudent();

      if (studentData != null && mounted) {
        setState(() {
          userName =
              (studentData['name'] != null &&
                  studentData['name'].toString().isNotEmpty)
              ? studentData['name']
              : "User";
          isLoading = false;
        });

        if (studentData['class_id'] == null ||
            studentData['class_id'].toString().isEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          ).then((_) => _loadUserName());
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading student data: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildTextShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 140,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildButtonShimmer(double width) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: 85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    double width,
    String text,
    IconData icon,
    List<Color> colors,
    VoidCallback onPressed,
  ) {
    return Center(
      child: SizedBox(
        width: width * 0.85,
        height: 85,
        child: isLoading
            ? _buildButtonShimmer(width * 0.85)
            : GradientButton(
                text: text,
                icon: icon,
                iconSize: 36,
                fontSize: 22,
                contentAlignment: MainAxisAlignment.start,
                circularIcon: false,
                borderRadius: 20,
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onPressed: onPressed,
              ),
      ),
    );
  }

  Widget _miniCard({
    required String title,
    required String imagePath,
    required Color color,
    required VoidCallback onTap,
    required double cardWidth,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(.1),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: Image.asset(imagePath, fit: BoxFit.contain)),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double screenWidth = mediaQuery.size.width;
    final double topPadding = mediaQuery.padding.top > 0
        ? mediaQuery.padding.top + 10
        : 40.0;

    // Responsive calculations to eliminate layout breaking
    double gridAspectRatio = screenWidth > 600 ? 0.95 : 0.82;
    double quickAccessCardWidth = screenWidth * 0.36;
    if (quickAccessCardWidth > 160) quickAccessCardWidth = 160;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFFF5F7FB)),
        child: SafeArea(
          top: false, // Custom clean padding handled below
          bottom: true,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: topPadding),

                // 🔹 RESPONSIVE HEADER BAR WITH ELEMENT BORDERS
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Modified Logo Container to replicate the reference design
                      Container(
                        width: screenWidth > 600 ? 56 : 48,
                        height: screenWidth > 600 ? 56 : 48,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12, width: 1.2),
                        ),
                        child: ClipOval(
                          child: Transform.scale(
                            scale: 1.20, // try values between 1.25 and 1.4
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          // ... rest of your code for stars and profile items stays identical
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4D6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Color(0xFFF5C542),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  "1250",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfilePage(),
                                ),
                              ).then((_) => _loadUserName());
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black12,
                                  width: 1.2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: screenWidth > 600 ? 22 : 18,
                                backgroundColor: Colors.pink.shade100,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.black87,
                                  size: screenWidth > 600 ? 22 : 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 🔹 RESPONSIVE PARENT DASHBOARD CONTAINER
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isLoading
                          ? _buildTextShimmer()
                          : RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Hello, ",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: userName,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      const SizedBox(height: 2),
                      const Text(
                        "Let's continue learning",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),

                      const SizedBox(height: 16),

                      // Responsive Dynamic Main Grid Content
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: gridAspectRatio,
                        children: [
                          _dashboardCard(
                            title: "Study Master",
                            subtitle: "Class Lessons",
                            imagePath: "assets/images/dashboard/study.png",
                            color: const Color(0xFF2F80ED),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const Study(),
                                ),
                              );
                            },
                          ),
                          _dashboardCard(
                            title: "Word Master",
                            subtitle: "Vocabulary",
                            imagePath: "assets/images/dashboard/wordmaster.png",
                            color: const Color(0xFF27AE60),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PredictionPage(),
                                ),
                              );
                            },
                          ),
                          _dashboardCard(
                            title: "English Master",
                            subtitle: "Learn English",
                            imagePath:
                                "assets/images/dashboard/english_master.png",
                            color: const Color(0xFFF2994A),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TranslatorPage(),
                                ),
                              );
                            },
                          ),
                          _dashboardCard(
                            title: "Game Master",
                            subtitle: "Fun & Learning",
                            imagePath: "assets/images/dashboard/games.png",
                            color: const Color(0xFF9B51E0),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GamesZonePage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      const Text(
                        "Quick Access",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Horizontal Slider Container
                      SizedBox(
                        height: 105,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _miniCard(
                              title: "Solved Papers",
                              imagePath:
                                  "assets/images/dashboard/solvedpapers.png",
                              color: Colors.orange,
                              cardWidth: quickAccessCardWidth,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SolvedPapersPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            _miniCard(
                              title: "Daily Quiz",
                              imagePath:
                                  "assets/images/dashboard/daily_quiz.png",
                              color: Colors.blue,
                              cardWidth: quickAccessCardWidth,
                              onTap: () {},
                            ),
                            const SizedBox(width: 10),
                            _miniCard(
                              title: "Translator",
                              imagePath:
                                  "assets/images/dashboard/translator.png",
                              color: const Color.fromARGB(255, 255, 3, 121),
                              cardWidth: quickAccessCardWidth,
                              onTap: () {},
                            ),
                            const SizedBox(width: 10),
                            _miniCard(
                              title: "GK",
                              imagePath:
                                  "assets/images/dashboard/daily_quiz.png",
                              color: Colors.green,
                              cardWidth: quickAccessCardWidth,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 🔹 OPTIMIZED GLOBAL CARD OBJECT BUILDERS
Widget _dashboardCard({
  required String title,
  required String subtitle,
  required String imagePath,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(24),
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.25),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _quickCard({
  required String title,
  required String imagePath,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(imagePath, height: 38, width: 38),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    ),
  );
}
