import 'package:flutter/material.dart';
import 'services/student_service.dart';
import 'widgets.dart/gradient_button.dart';
import 'widgets.dart/appbar_page.dart';
import 'widgets.dart/profile_text_field.dart';
import 'widgets.dart/profile_dropdown_field.dart';
import 'storage/local_storage_service.dart';
import 'utils/ui_utils.dart';
import 'student_dashboard.dart';
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? selectedClassId;
  List<dynamic> classList = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();


  dynamic studentData = LocalStorageService.getStudent();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _handleLoadClasses();
  }

  bool _isLoading = false; // Add this to your State class variables

  Future<void> _handleSaveProfile() async {
    // ... (validation and loading state logic) ...

    try {
      final data = await StudentService.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        classId: selectedClassId ?? "",
      );

      if (data['status'] == true) {
        // 1. Save data locally
        await LocalStorageService.setStudent(data['student']);

        // 2. Show success message
        Messenger.show(context, "Profile updated successfully!", type: MessageType.success);

        // 3. Wait for 2 seconds
        await Future.delayed(const Duration(seconds: 2));

        // 4. Redirect to Dashboard
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const StudentDashboardPage()),
                (route) => false,
          );
        }
      } else {
        Messenger.show(context, data['message'] ?? "Update failed", type: MessageType.error);
      }
    } catch (e) {
      Messenger.show(context, "An error occurred", type: MessageType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _loadInitialData() async {
    // 1. Load Classes from API FIRST
    // This ensures the "classList" is populated before we set the selected ID
    await _handleLoadClasses();

    // 2. Load Student from Local Storage
    final data = await LocalStorageService.getStudent();

    if (data != null && mounted) {
      setState(() {
        studentData = data;

        // Bind to Controllers (The way you already do)
        _nameController.text = data["name"] ?? "";
        _emailController.text = data["email"] ?? "";
        _mobileController.text = data["mobile"] ?? "";

        // Bind to Dropdown (Selected same way as controllers)
        // .toString() ensures a match with the items in the dropdown
        selectedClassId = data["class_id"]?.toString();
      });
    }
  }

  Future<void> _handleLoadClasses() async {
    try {
      final classes = await StudentService.fetchClasses();
      setState(() {
        classList = classes;
      });
    } catch (e) {
      debugPrint("Error loading classes: $e");
    }
  }

  // UI starts here

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(height: 150),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade300,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                _nameController.text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 30),

              buildTextField(
                label: "Name",
                controller: _nameController,
                hintText: "Enter name",
                onChanged: (value) {
                  setState(() {});
                },
              ),

              const SizedBox(height: 30),

              buildDropdownField(
                label: "Class",
                value: selectedClassId,
                items: classList,
                onChanged: (value) {
                  setState(() {
                    selectedClassId = value;
                  });
                },
              ),

              const SizedBox(height: 30),

              buildTextField(
                label: "Phone Number",
                controller: _mobileController,
                hintText: "Phone Number",
                keyboardType: TextInputType.text,
              ),

              const SizedBox(height: 30),

              buildTextField(
                label: "Email",
                controller: _emailController,
                hintText: "Enter email",
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: 300,
                height: 50,
                child: GradientButton(
                  text: 'Continue & Save',
                  icon: Icons.check,
                  borderRadius: 10,
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 33, 138, 225),
                      Colors.lightBlueAccent,
                    ],
                  ),
                  onPressed: _handleSaveProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


