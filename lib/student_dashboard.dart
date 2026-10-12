import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:Edmaster/study_subject_listing.dart';
import 'package:Edmaster/solved_papers_page.dart';
import 'package:Edmaster/prediction_page.dart';
import 'package:Edmaster/translator_page.dart';
import 'package:Edmaster/english_master/english_master.dart';
import 'package:Edmaster/profile.dart';
import 'package:Edmaster/storage/local_storage_service.dart';
import 'package:Edmaster/services/student_service.dart';
import 'package:Edmaster/utils/app_colors.dart';
import 'widgets.dart/gradient_button.dart';
import 'widgets.dart/appbar_page.dart';
import 'package:Edmaster/daily_quiz.dart';
import 'package:Edmaster/quizz_master/gk_master.dart';
import 'package:Edmaster/gk_master/gk_master_page.dart';
import 'games_zone.dart';
import 'package:Edmaster/med_master/med_master.dart';
import 'package:Edmaster/services/profile_image_cache_service.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  String userName = "User";
  String? profileImageUrl;
  String? localProfileImagePath;
  File? localProfileImage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Refresh profile data from the server after login so the saved
      // image URL is available even when the local cache was cleared on logout.
      await StudentService.syncStudentProfile();

      final studentData = await LocalStorageService.getStudent();

      if (studentData == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }

        return;
      }

      final String? imageUrl =
          studentData['image'] != null &&
              studentData['image'].toString().isNotEmpty
          ? studentData['image'].toString()
          : (studentData['profile_photo_url'] != null &&
                    studentData['profile_photo_url'].toString().isNotEmpty
                ? studentData['profile_photo_url'].toString()
                : null);

      // ---------------------------------------------------------
      // SHOW DASHBOARD IMMEDIATELY
      // ---------------------------------------------------------
      if (mounted) {
        setState(() {
          userName = studentData['name']?.toString() ?? 'User';

          profileImageUrl = imageUrl;

          isLoading = false;
        });
      }

      // ---------------------------------------------------------
      // LOAD LOCAL IMAGE WITHOUT BLOCKING DASHBOARD
      // ---------------------------------------------------------
      _loadCachedProfileImage();

      // ---------------------------------------------------------
      // DOWNLOAD ONLY IF LOCAL CACHE DOESN'T EXIST
      // ---------------------------------------------------------
      if (imageUrl != null && imageUrl.isNotEmpty) {
        _updateProfileImageInBackground(imageUrl);
      }

      // ---------------------------------------------------------
      // PROFILE COMPLETION CHECK
      // ---------------------------------------------------------
      if (studentData['class_id'] == null ||
          studentData['class_id'].toString().isEmpty) {
        if (!mounted) return;

        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );

        // If ProfilePage changed something,
        // reload dashboard immediately.
        if (result == true && mounted) {
          await _refreshProfileImageImmediately();
        }
      }
    } catch (e) {
      debugPrint("LOAD USER ERROR => $e");

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCachedProfileImage() async {
    try {
      final File? localImage = await ProfileImageCacheService.getLocalImage();

      if (!mounted || localImage == null) {
        return;
      }

      setState(() {
        localProfileImage = localImage;
        localProfileImagePath = localImage.path;
      });
    } catch (e) {
      debugPrint("LOAD CACHED PROFILE IMAGE ERROR => $e");
    }
  }

  Future<void> _refreshProfileImageImmediately() async {
    try {
      final File? localImage = await ProfileImageCacheService.getLocalImage();

      if (!mounted) return;

      if (localImage != null) {
        setState(() {
          localProfileImage = localImage;
          localProfileImagePath = localImage.path;
        });
      }

      // Also refresh student information.
      final studentData = await LocalStorageService.getStudent();

      if (!mounted || studentData == null) {
        return;
      }

      final String? imageUrl =
          studentData['image'] != null &&
              studentData['image'].toString().isNotEmpty
          ? studentData['image'].toString()
          : (studentData['profile_photo_url'] != null &&
                    studentData['profile_photo_url'].toString().isNotEmpty
                ? studentData['profile_photo_url'].toString()
                : null);

      setState(() {
        userName = studentData['name']?.toString() ?? userName;

        profileImageUrl = imageUrl;
      });
    } catch (e) {
      debugPrint("REFRESH PROFILE IMAGE ERROR => $e");
    }
  }

  Future<void> _updateProfileImageInBackground(String imageUrl) async {
    try {
      // Refresh the cache from the server URL. The cached file may be stale
      // (for example, after changing the profile photo or switching accounts).
      final file = await ProfileImageCacheService.downloadAndCache(imageUrl);

      if (!mounted || file == null) {
        return;
      }

      setState(() {
        localProfileImage = file;
        localProfileImagePath = file.path;
      });
    } catch (e) {
      debugPrint('PROFILE IMAGE BACKGROUND ERROR: $e');
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
                      // Dashboard Logo
                      Container(
                        width: screenWidth > 600 ? 56 : 48,
                        height: screenWidth > 600 ? 56 : 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12, width: 1.2),
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfilePage(),
                                ),
                              );

                              if (!mounted) return;

                              if (result != null && result is String) {
                                final newImageFile = File(result);

                                if (await newImageFile.exists()) {
                                  setState(() {
                                    localProfileImage = newImageFile;
                                    localProfileImagePath = newImageFile.path;
                                  });
                                }
                              }
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
                                backgroundColor: Colors.grey.shade200,

                                backgroundImage: localProfileImage != null
                                    ? ResizeImage(
                                        FileImage(localProfileImage!),
                                        width: 120,
                                        height: 120,
                                      )
                                    : (profileImageUrl != null &&
                                              profileImageUrl!.isNotEmpty
                                          ? ResizeImage(
                                              NetworkImage(profileImageUrl!),
                                              width: 120,
                                              height: 120,
                                            )
                                          : null),

                                child:
                                    (localProfileImage == null &&
                                        (profileImageUrl == null ||
                                            profileImageUrl!.isEmpty))
                                    ? Icon(
                                        Icons.person,
                                        size: screenWidth > 600 ? 24 : 20,
                                        color: Colors.grey,
                                      )
                                    : null,
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
                                  builder: (_) => const EnglishMasterPage(),
                                ),
                              );
                            },
                          ),
                          _dashboardCard(
                            title: "Fun Master",
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
                          _dashboardCard(
                            title: "Med Master",
                            subtitle: "Medical Learning",
                            imagePath: "assets/images/dashboard/med_master.png",
                            color: const Color(0xFF00ACC1), // Cyan
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MedMasterPage(),
                                ),
                              );
                            },
                          ),

                          _dashboardCard(
                            title:
                                "Quiz Master", //Gk master changed to Quiz master
                            subtitle: "General Knowledge",
                            imagePath: "assets/images/dashboard/gk_master.png",
                            color: const Color(0xFFE91E63), // Pink
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const QuizzMasterPage(),
                                ),
                              );
                            },
                          ),

                          // GK MASTER
                          _dashboardCard(
                            title: "GK Master",
                            subtitle: "General Knowledge",
                            imagePath: "assets/images/dashboard/gkmaster.png",
                            color: const Color(0xFF3F51B5),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GKMasterHomePage(),
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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const DailyQuizGamePage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            _miniCard(
                              title: "Translator",
                              imagePath:
                                  "assets/images/dashboard/translator.png",
                              color: const Color.fromARGB(255, 255, 3, 121),
                              cardWidth: quickAccessCardWidth,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TranslatorPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
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
