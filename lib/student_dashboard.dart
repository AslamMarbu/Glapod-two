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
          userName = (studentData['name'] != null && studentData['name'].toString().isNotEmpty)
              ? studentData['name']
              : "User";
          isLoading = false;
        });

        if (studentData['class_id'] == null || studentData['class_id'].toString().isEmpty) {
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
      appBar: const CustomAppBar(
        height: 120,
        isDashboard: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/doodle.jpeg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.10),
              BlendMode.lighten,
            ),
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // GREETING SECTION
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: isLoading
                    ? _buildTextShimmer()
                    : Row(
                  children: [
                    Text(
                      'Hi $userName',
                      style: const TextStyle(
                        fontSize: 22,
                        color: Color(0xFF0056B3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('👋', style: TextStyle(fontSize: 24)),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // MENU BUTTONS
              _buildMenuButton(
                  context,
                  screenWidth,
                  'Study',
                  Icons.menu_book_rounded,
                  [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Study()))
              ),

              const SizedBox(height: 25),

              _buildMenuButton(
                  context,
                  screenWidth,
                  'Solved Papers',
                  Icons.description_rounded,
                  [const Color(0xFFFFB75E), const Color(0xFFED8F03)],
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SolvedPapersPage()))
              ),

              const SizedBox(height: 25),

              // 🔹 FIXED NAVIGATION FOR WORD MASTER
              _buildMenuButton(
                  context,
                  screenWidth,
                  'Word Master',
                  Icons.show_chart_rounded,
                  [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) =>  PredictionPage()))
              ),

              const SizedBox(height: 25),

              _buildMenuButton(
                  context,
                  screenWidth,
                  'Translator',
                  Icons.forum_rounded,
                  [const Color(0xFFC56CD6), const Color(0xFF3491FF)],
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TranslatorPage()))
              ),

              const SizedBox(height: 40),
            ],
          ),
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

  Widget _buildMenuButton(BuildContext context, double width, String text, IconData icon, List<Color> colors, VoidCallback onPressed) {
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