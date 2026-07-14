import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/student_service.dart';
import 'widgets.dart/gradient_button.dart';
import 'storage/local_storage_service.dart';
import 'utils/ui_utils.dart';
import 'student_dashboard.dart';
import 'login.dart';
import 'subscription_page.dart';
import 'terms_condition_page.dart';
import 'my_favourites_page.dart';

class ProfilePage extends StatefulWidget {
  final bool showSuccessMsg;
  const ProfilePage({super.key, this.showSuccessMsg = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Specific masking logic for Phone (2+2) and Email (ar****kh@gmail.com)
  String _maskSensitiveData(String data, {bool isEmail = false}) {
    if (data.isEmpty) return "";

    if (isEmail) {
      final parts = data.split('@');
      if (parts.length != 2) return data;
      String name = parts[0];
      String domain = parts[1];

      if (name.length <= 4) {
        return "${name[0]}**${name[name.length - 1]}@$domain";
      }
      return "${name.substring(0, 2)}****${name.substring(name.length - 2)}@$domain";
    } else {
      if (data.length < 5) return data;
      return "${data.substring(0, 2)}******${data.substring(data.length - 2)}";
    }
  }

  String? selectedClassId;
  List<dynamic> classList = [];
  bool _isLoading = false;
  bool _isDataLoaded = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  // Tracks persistent data states down from initialization layer
  String _rawEmail = "";
  String _rawMobile = "";

  bool _isClassSavedInStorage = false;
  File? _imageFile;
  String? _serverImageUrl;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _handleLoadClasses();
    final data = await LocalStorageService.getStudent();

    if (data != null && mounted) {
      setState(() {
        _rawEmail = data["email"] ?? "";
        _rawMobile = data["mobile"] ?? "";

        _nameController.text = data["name"] ?? "";
        _emailController.text = _maskSensitiveData(_rawEmail, isEmail: true);
        _mobileController.text = _maskSensitiveData(_rawMobile, isEmail: false);

        selectedClassId = data["class_id"]?.toString();
        _serverImageUrl = data["image"] ?? data["profile_photo_url"];
        _isClassSavedInStorage =
            data["class_id"] != null && data["class_id"].toString().isNotEmpty;
        _isDataLoaded = true;
      });
    }
  }

  Future<void> _handleLoadClasses() async {
    try {
      final classes = await StudentService.fetchClasses();
      if (mounted) setState(() => classList = classes);
    } catch (e) {
      debugPrint("Error loading classes: $e");
    }
  }

  Future<void> _pickImage() async {
    final status = await LocalStorageService.getLicenseStatus();

    if (status != LicenseStatus.activated) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Access Denied"),
          content: const Text(
            "Only activated students can change profile photo.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }
    final ImagePicker picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              title: Text(
                "Change Photo",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 50,
                );
                if (image != null) {
                  setState(() => _imageFile = File(image.path));
                }
                if (mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 50,
                );
                if (image != null) {
                  setState(() => _imageFile = File(image.path));
                }
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    await LocalStorageService.logOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MyHomePage()),
        (route) => false,
      );
    }
  }

  Future<void> _handleSaveProfile() async {
    if (selectedClassId == null || selectedClassId!.isEmpty) {
      Messenger.show(
        context,
        "Please select a Class of Study first.",
        type: MessageType.error,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String formEmailInput = _emailController.text.trim();
      String updatedEmail =
          (formEmailInput == _maskSensitiveData(_rawEmail, isEmail: true) ||
              formEmailInput.isEmpty)
          ? _rawEmail
          : formEmailInput;

      // Sending multi-part request data containing your raw _imageFile
      final data = await StudentService.updateProfile(
        name: _nameController.text.trim(),
        email: updatedEmail,
        classId: selectedClassId!,
        imageFile: _imageFile,
      );

      if (data['status'] == true) {
        // 1. Persist the absolute newest data returned by the server locally
        await LocalStorageService.updateStudentData(data['student']);

        if (mounted) {
          setState(() {
            _isClassSavedInStorage = true;

            // 2. Update server URL string (Double-check if this needs your API Base URL prefix!)
            _serverImageUrl =
                data['student']['image'] ??
                data['student']['profile_photo_url'];

            // 3. Clear local file path ONLY after setting the newly received server URL safely
            _imageFile = null;
          });

          Messenger.show(
            context,
            "Profile updated successfully!",
            type: MessageType.success,
          );

          // 4. Instead of replacing the screen and causing structural UI blink,
          // cleanly pop back to the dashboard. The dashboard should reload data on resume.
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          Messenger.show(
            context,
            data['message'] ?? "Failed to save profile changes",
            type: MessageType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Messenger.show(
          context,
          "An unexpected error occurred",
          type: MessageType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isDataLoaded == false
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 30),
                  _buildSectionLabel("Account Details"),
                  _buildGroupedCard(
                    children: [
                      _buildTextFieldRow("Full Name", _nameController),
                      _buildDivider(),
                      _buildClassDropdown(),
                      _buildDivider(),
                      _buildTextFieldRow(
                        "Phone",
                        _mobileController,
                        enabled: false,
                      ),
                      _buildDivider(),
                      _buildTextFieldRow("Email", _emailController),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: GradientButton(
                        text: _isLoading ? 'Saving...' : 'Save & Continue',
                        onPressed: _isLoading ? () {} : _handleSaveProfile,
                        gradient: const LinearGradient(
                           colors: [Color(0xfff16704), Color.fromARGB(255, 249, 116, 22)],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),
                  _buildSectionLabel("Preferences & Actions"),
                  _buildGroupedCard(
                    children: [
                      _buildMenuItem(
                        Icons.dashboard_rounded,
                        "Go To Dashboard",
                        const Color(0xFF1B75BB),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        Icons.favorite_rounded,
                        "My Favourites",
                        const Color(0xFFE91E63),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        Icons.stars_rounded,
                        "Subscription Info",
                        const Color(0xFFFF9800),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        Icons.article_rounded,
                        "Terms & Conditions",
                        const Color(0xFF607D8B),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        Icons.share_rounded,
                        "Share App",
                        const Color(0xFF4CAF50),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        Icons.logout_rounded,
                        "Logout",
                        Colors.redAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (_serverImageUrl != null && _serverImageUrl!.isNotEmpty
                                ? NetworkImage(
                                    "$_serverImageUrl?v=${DateTime.now().millisecondsSinceEpoch}",
                                  )
                                : null)
                            as ImageProvider?,
                  child:
                      (_imageFile == null &&
                          (_serverImageUrl == null || _serverImageUrl!.isEmpty))
                      ? Icon(
                          Icons.person_rounded,
                          size: 50,
                          color: Colors.grey[400],
                        )
                      : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B75BB),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        AnimatedBuilder(
          animation: _nameController,
          builder: (context, child) {
            return Text(
              _nameController.text.isEmpty
                  ? "Student Name"
                  : _nameController.text,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            );
          },
        ),
        const SizedBox(height: 5),
        Text(
          "Update your profile and settings",
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8, right: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.grey[600],
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: Colors.grey[200]),
    );
  }

  Widget _buildTextFieldRow(
    String label,
    TextEditingController controller, {
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                color: enabled ? Colors.black87 : Colors.grey[600],
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    // Exact theme color matched from your Save button
    const Color themeBlue = Color(0xFF00B0FF);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          const SizedBox(
            width: 100, // Matches your other form label widths perfectly
            child: Text(
              "Class of Study",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const Spacer(), // Pushes the capsule selector all the way to the right
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            height: 40, // Compact height for the capsule style
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                20,
              ), // Complete stadium/pill shape
              border: Border.all(
                color: themeBlue, // Vibrant blue border from your screenshot
                width: 1.8,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedClassId,
                iconEnabledColor: themeBlue, // Tint the arrow blue
                dropdownColor: Colors.white, // Background of the popup menu
                borderRadius: BorderRadius.circular(
                  20,
                ), // Rounds the overlay menu box!
                menuMaxHeight: 350, // Limits height so it scrolls cleanly
                hint: const Text(
                  "Select Class",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                icon: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.arrow_drop_down_rounded, size: 26),
                ),
                // Customizing how the selected text looks inside the button container
                selectedItemBuilder: (BuildContext context) {
                  return classList.map<Widget>((item) {
                    return Center(
                      child: Text(
                        item['class'] ?? "",
                        style: const TextStyle(
                          color: Color.fromARGB(
                            255,
                            0,
                            0,
                            0,
                          ), // Matching text selection color
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList();
                },
                items: classList
                    .map(
                      (item) => DropdownMenuItem(
                        value: item['id'].toString(),
                        child: Text(
                          item['class'] ?? "",
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => selectedClassId = val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color iconColor) {
    final bool isLocked = title == "Go To Dashboard" && !_isClassSavedInStorage;

    return InkWell(
      onTap: isLocked
          ? () => Messenger.show(
              context,
              "Save profile to unlock.",
              type: MessageType.error,
            )
          : () {
              switch (title) {
                case "Logout":
                  _handleLogout(context);
                  break;
                case "Go To Dashboard":
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentDashboardPage(),
                    ),
                  );
                  break;
                case "My Favourites":
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyFavouritesPage(),
                    ),
                  );
                  break;
                case "Subscription Info":
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionPage(),
                    ),
                  );
                  break;
                case "Terms & Conditions":
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsConditionsPage(),
                    ),
                  );
                  break;
                case "Share App":
                  // Add your share functional implementation or helper package invocation here
                  Messenger.show(
                    context,
                    "Sharing feature coming soon!",
                    type: MessageType.success,
                  );
                  break;
              }
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey[100] : iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isLocked ? Icons.lock_outline_rounded : icon,
                color: isLocked ? Colors.grey : iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isLocked
                      ? Colors.grey
                      : (title == "Logout" ? Colors.redAccent : Colors.black87),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
