import 'package:flutter/material.dart';
import 'widgets.dart/gradient_button.dart';
import 'glapod_user_page.dart';
import 'widgets.dart/appbar_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? selectedOption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(height: 150),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade300,
              child: Icon(Icons.person, size: 40, color: Colors.grey.shade700),
            ),

            const SizedBox(height: 20),

            Text(
              'John Doe',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: DropdownButtonFormField<String>(
                value: selectedOption,
                hint: const Text(
                  'Class of Study',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: '1',
                    child: Text(
                      'Class 1',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DropdownMenuItem(
                    value: '2',
                    child: Text(
                      'Class 2',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DropdownMenuItem(
                    value: '3',
                    child: Text(
                      'Class 3',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DropdownMenuItem(
                    value: '4',
                    child: Text(
                      'Class 4',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DropdownMenuItem(
                    value: '5',
                    child: Text(
                      'Class 5',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DropdownMenuItem(
                    value: '6',
                    child: Text(
                      'Class 6',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DropdownMenuItem(
                    value: '7',
                    child: Text(
                      'Class 7',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DropdownMenuItem(
                    value: '8',
                    child: Text(
                      'Class 8',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DropdownMenuItem(
                    value: '9',
                    child: Text(
                      'Class 9',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DropdownMenuItem(
                    value: '10',
                    child: Text(
                      'Class 10',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedOption = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Phone Number',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '9876543210',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Email',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'user@mail.com',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GlapodUserPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
