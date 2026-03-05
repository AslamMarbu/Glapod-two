import 'package:flutter/material.dart';
import 'package:glapod/profile.dart';
import 'package:glapod/storage/local_storage_service.dart';
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final Color backgroundColor;

  const CustomAppBar({
    super.key,
    required this.height,
    this.backgroundColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: height,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      centerTitle: true,
      backgroundColor: backgroundColor,
      title: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 45),
            const SizedBox(width: 8),
            const Text(
              'Glapod',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.only(right: 10.0), // Adjusted padding
      actions: [
        IconButton(
          icon:  Icon(Icons.notifications, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) =>  ProfilePage()),
            );
          },
        ),
         SizedBox(width: 5),
        // --- The Profile Button ---
        IconButton(
          icon:  Icon(Icons.person, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) =>  ProfilePage()),
            );
          },
        ),
         SizedBox(width: 10),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
