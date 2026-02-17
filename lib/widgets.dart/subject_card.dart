import 'package:flutter/material.dart';
import 'package:glapod/syllabus_page.dart';

class SubjectCard extends StatelessWidget {
  final String title;

  const SubjectCard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconColumn(context, Icons.book, "Textbook"),
              _buildIconColumn(
                context,
                Icons.description,
                "Syllabus",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SyllabusPage()),
                  );
                },
              ),
              _buildIconColumn(context, Icons.help, "Questions"),
              _buildIconColumn(context, Icons.lightbulb, "Solutions"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconColumn(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Icon(icon, size: 20, color: Colors.blue),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
