import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:glapod/study_subject_listing.dart';
import 'package:glapod/solved_papers_page.dart';
import 'package:glapod/prediction_page.dart'; // 🔹 Ensure this path is correct
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: double.infinity),
        decoration: const BoxDecoration(color: Color(0xFFF5F7FB)),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // GREETING SECTION
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfilePage(),
                              ),
                            ).then((_) => _loadUserName());
                          },
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.pink.shade100,
                            child: const Icon(
                              Icons.person,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4D6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 18),
                              SizedBox(width: 6),
                              Text(
                                "1250 pts",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.settings_outlined,
                              size: 24,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),
                    Text(
                      "Hello",
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Let's continue learning",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),

                    const SizedBox(height: 30),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.78,
                      children: [
                        _dashboardCard(
                          title: "Study",
                          subtitle: "Class Lessons",
                          imagePath: "assets/images/dashboard/study.png",
                          color: const Color(0xFF2F80ED),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const Study()),
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
                          title: "Translator",
                          subtitle: "Language",
                          imagePath: "assets/images/dashboard/translator.png",
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
                          title: "Games Zone",
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

                    const SizedBox(height: 30),

                    const Text(
                      "Quick Access",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      height: 130,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _miniCard(
                            title: "Solved Papers",
                            imagePath:
                                "assets/images/dashboard/solvedpapers.png",
                            color: Colors.orange,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SolvedPapersPage(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(width: 12),

                          _miniCard(
                            title: "Daily Quiz",
                            imagePath: "assets/images/dashboard/daily_quiz.png",
                            color: Colors.blue,
                            onTap: () {},
                          ),

                          const SizedBox(width: 12),

                          _miniCard(
                            title: "GK",
                            imagePath: "assets/images/dashboard/daily_quiz.png",
                            color: Colors.green,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniCard({
    required String title,
    required String imagePath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(.1),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          children: [
            Expanded(child: Image.asset(imagePath, fit: BoxFit.contain)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
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
}

Widget _dashboardCard({
  required String title,
  required String subtitle,
  required String imagePath,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(30),
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),

            const SizedBox(height: 8),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),

            const SizedBox(height: 6),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Image.asset(imagePath, height: 48, width: 48),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}
