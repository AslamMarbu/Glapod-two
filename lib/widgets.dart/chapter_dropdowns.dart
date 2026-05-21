import 'package:flutter/material.dart';

class ChapterList extends StatelessWidget {
  const ChapterList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set background color directly here
      backgroundColor: const Color(0xFFF1FAF2),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: 6,
        itemBuilder: (context, index) {
          String title = index == 5 ? 'Chapter n' : 'Chapter ${index + 1}';
          return _buildChapterCard(title);
        },
      ),
    );
  }

  Widget _buildChapterCard(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        // IMPORTANT: dividerColor: Colors.transparent removes the line on expansion
        data: ThemeData().copyWith(
          dividerColor: Colors.transparent,
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: ExpansionTile(
          // Removes default borders that appear when tile is open
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          children: [
            // This Padding replaces the old ListTiles to match your Video
            Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 15, right: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionIcon(Icons.assignment_outlined, "Notes"),
                  _buildActionIcon(Icons.play_circle_outline, "Video"),
                  _buildActionIcon(Icons.help_outline, "Q-Bank"),
                  _buildActionIcon(Icons.menu_book_outlined, "Solutions"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the circular blue icons from the video
  Widget _buildActionIcon(IconData icon, String label) {
    return InkWell(
      onTap: () {
        // Add your navigation logic here
        print("Tapped $label");
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4FACFE).withOpacity(0.1), // Light blue background
              border: Border.all(color: const Color(0xFF4FACFE), width: 1.5),
            ),
            child: Icon(icon, color: const Color(0xFF4FACFE), size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}