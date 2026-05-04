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
import 'package:glapod/utils/app_colors.dart';

class ProfilePage extends StatefulWidget {
  final bool showSuccessMsg;
  const ProfilePage({super.key, this.showSuccessMsg = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Helper to mask sensitive data visually
  String _maskSensitiveData(String data, {bool isEmail = false}) {
    if (data.isEmpty) return "";

    if (isEmail) {
      final parts = data.split('@');
      if (parts.length != 2) return data;
      String name = parts[0];
      if (name.length <= 2) return data;
      return "${name.substring(0, 2)}****@${parts[1]}";
    } else {
      if (data.length < 6) return data;
      return "${data.substring(0, 3)}*****${data.substring(data.length - 2)}";
    }
  }

  String? selectedClassId;
  List<dynamic> classList = [];
  bool _isLoading = false;
  bool _isDataLoaded = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  bool _isClassSavedInStorage = false;
  File? _imageFile;
  String? _serverImageUrl;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _handleLoadClasses();
    final data = await LocalStorageService.getStudent();

    if (data != null && mounted) {
      setState(() {
        _nameController.text = data["name"] ?? "";
        _emailController.text = data["email"] ?? "";
        _mobileController.text = data["mobile"] ?? "";
        selectedClassId = data["class_id"]?.toString();
        _serverImageUrl = data["image"] ?? data["profile_photo_url"];
        _isClassSavedInStorage = data["class_id"] != null && data["class_id"].toString().isNotEmpty;
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
    final ImagePicker picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(title: Text("Change Photo", style: TextStyle(fontWeight: FontWeight.bold))),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                if (image != null) setState(() => _imageFile = File(image.path));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                if (image != null) setState(() => _imageFile = File(image.path));
                Navigator.pop(context);
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
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MyHomePage()), (route) => false);
    }
  }

  // --- UPDATED SAVE FUNCTION TO NAVIGATE TO DASHBOARD ---
  Future<void> _handleSaveProfile() async {
    if (selectedClassId == null || selectedClassId!.isEmpty) {
      Messenger.show(context, "Please select a Class of Study first.", type: MessageType.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = await StudentService.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        classId: selectedClassId!,
        imageFile: _imageFile,
      );

      if (data['status'] == true) {
        await LocalStorageService.updateStudentData(data['student']);

        if (mounted) {
          setState(() {
            _isClassSavedInStorage = true;
            _serverImageUrl = data['student']['image'] ?? data['student']['profile_photo_url'];
            _imageFile = null;
          });

          Messenger.show(context, "Profile updated!", type: MessageType.success);

          // Redirect to Dashboard after successful save
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StudentDashboardPage()),
          );
        }
      } else {
        if (mounted) Messenger.show(context, data['message'] ?? "Failed", type: MessageType.error);
      }
    } catch (e) {
      if (mounted) Messenger.show(context, "Error occurred", type: MessageType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  _buildDataCard(child: _buildTextFieldRow("Full Name", _nameController)),
                  _buildDataCard(child: _buildClassDropdown()),
                  _buildDataCard(child: _buildTextFieldRow("Phone", _mobileController, enabled: false, mask: true)),
                  _buildDataCard(child: _buildTextFieldRow("Email", _emailController, mask: true, isEmail: true)),

                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity, height: 55,
                      child: GradientButton(
                        text: _isLoading ? 'Saving...' : 'Save & Continue',
                        onPressed: _isLoading ? () {} : _handleSaveProfile,
                        gradient: const LinearGradient(colors: [Color(0xFF40C4FF), Color(0xFF00B0FF)]),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                  _buildMenuCard(Icons.dashboard, "Go To Dashboard", const Color(0xFF1B75BB)),
                  _buildMenuCard(Icons.favorite, "My Favourites", const Color(0xFF1B75BB)),
                  _buildMenuCard(Icons.stars, "Subscription Info", const Color(0xFF1B75BB)),
                  _buildMenuCard(Icons.article, "Terms & Conditions", const Color(0xFF1B75BB)),
                  _buildMenuCard(Icons.share, "Share App", const Color(0xFF1B75BB)),
                  _buildMenuCard(Icons.logout, "Logout", Colors.redAccent),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1B75BB), Color(0xFF6BCF2E)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
            const Expanded(child: Center(child: Text("Profile", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)))),
            const SizedBox(width: 48),
          ]),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImage,
            child: Stack(alignment: Alignment.bottomRight, children: [
              CircleAvatar(
                radius: 52, backgroundColor: Colors.white24,
                child: CircleAvatar(
                  radius: 48, backgroundColor: const Color(0xFF424242),
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (_serverImageUrl != null && _serverImageUrl!.isNotEmpty
                      ? NetworkImage("$_serverImageUrl?v=${DateTime.now().millisecondsSinceEpoch}")
                      : null) as ImageProvider?,
                  child: (_imageFile == null && (_serverImageUrl == null || _serverImageUrl!.isEmpty))
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
              ),
              const CircleAvatar(radius: 16, backgroundColor: Colors.white, child: Icon(Icons.camera_alt, size: 18, color: Color(0xFF1B75BB))),
            ]),
          ),
          const SizedBox(height: 12),
          Text(_nameController.text.isEmpty ? "Student" : _nameController.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
            "Class of Study",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
        ),
        const SizedBox(width: 20),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedClassId,
              isExpanded: true,
              hint: const Align(
                alignment: Alignment.centerRight,
                child: Text("Select Class", style: TextStyle(color: Colors.grey, fontSize: 14)),
              ),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              selectedItemBuilder: (BuildContext context) {
                return classList.map<Widget>((item) {
                  return Container(
                    alignment: Alignment.centerRight,
                    child: Text(
                      item['class'] ?? "",
                      style: const TextStyle(color: Colors.black87),
                    ),
                  );
                }).toList();
              },
              items: classList.map((item) => DropdownMenuItem(
                value: item['id'].toString(),
                child: Text(
                  item['class'] ?? "",
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              )).toList(),
              onChanged: (val) => setState(() => selectedClassId = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFieldRow(String label, TextEditingController controller, {bool enabled = true, bool mask = false, bool isEmail = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      Expanded(
          child: TextField(
              controller: mask ? TextEditingController(text: _maskSensitiveData(controller.text, isEmail: isEmail)) : controller,
              enabled: enabled,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(border: InputBorder.none, isDense: true)
          )
      ),
    ]);
  }

  Widget _buildDataCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: child,
    );
  }

  Widget _buildMenuCard(IconData icon, String title, Color color) {
    final bool isLocked = title == "Go To Dashboard" && !_isClassSavedInStorage;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(isLocked ? Icons.lock_outline : icon, color: isLocked ? Colors.grey : color),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: isLocked ? Colors.grey : Colors.black)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: isLocked ? () => Messenger.show(context, "Save profile to unlock.", type: MessageType.error) : () {
          if (title == "Logout") _handleLogout(context);
          else if (title == "Go To Dashboard") Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentDashboardPage()));
          else if (title == "My Favourites") Navigator.push(context, MaterialPageRoute(builder: (context) => const MyFavouritesPage()));
          else if (title == "Subscription Info") Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionPage()));
          else if (title == "Terms & Conditions") Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsConditionsPage()));
        },
      ),
    );
  }
}