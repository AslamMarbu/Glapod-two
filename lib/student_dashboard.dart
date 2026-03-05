import 'package:flutter/material.dart';
import 'package:glapod/study_subject_listing.dart';
import 'widgets.dart/gradient_button.dart';
import 'widgets.dart/appbar_page.dart';
import 'storage/local_storage_service.dart'; // Ensure this is imported

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  String userName = "User"; // Default fallback

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  // Fetch the name from Local Storage
  Future<void> _loadUserName() async {
    final studentData = await LocalStorageService.getStudent();
    if (studentData != null && studentData['name'] != null) {
      setState(() {
        userName = studentData['name'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(height: 150),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/doodle.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Hi $userName', // Use the dynamic variable here
                    style: const TextStyle(
                      fontSize: 24,
                      color: Color.fromARGB(255, 45, 97, 187),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('👋', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),

            const SizedBox(height: 50),



            Center(
              child: SizedBox(
                width: 300,
                height: 50,
                child: GradientButton(
                  text: 'Study',
                  icon: Icons.menu_book,
                  contentAlignment: MainAxisAlignment.start,
                  circularIcon: false,
                  borderRadius: 10,
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 33, 138, 225),
                      Colors.lightBlueAccent,
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Study()),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 300,
                height: 50,
                child: GradientButton(
                  text: 'Solved Papers',
                  icon: Icons.auto_stories,
                  contentAlignment: MainAxisAlignment.start,
                  circularIcon: false,
                  borderRadius: 10,
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 236, 175, 77),
                      Color.fromARGB(255, 229, 147, 24),
                    ],
                  ),
                  onPressed: () {},
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 300,
                height: 50,
                child: GradientButton(
                  text: 'Prediction',
                  icon: Icons.library_books,
                  contentAlignment: MainAxisAlignment.start,
                  circularIcon: false,
                  borderRadius: 10,
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 68, 211, 96),
                      Color.fromARGB(255, 63, 229, 154),
                    ],
                  ),
                  onPressed: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}