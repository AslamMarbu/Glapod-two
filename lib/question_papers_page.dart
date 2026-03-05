import 'package:flutter/material.dart';

class QuestionPapersPage extends StatefulWidget {
  final String subjectName;

  const QuestionPapersPage({
    super.key,
    required this.subjectName,
  });

  @override
  State<QuestionPapersPage> createState() => _QuestionPapersPageState();
}

class _QuestionPapersPageState extends State<QuestionPapersPage> {

  final List<Map<String, dynamic>> years = [
    {"year": "2025", "sets": 18},
    {"year": "2024", "sets": 15},
    {"year": "2023", "sets": 15},
    {"year": "2022", "sets": 13},
    {"year": "2020", "sets": 15},
    {"year": "2019", "sets": 15},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background
      appBar: AppBar(
        title: Text(widget.subjectName),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B75BB), Color(0xFF6BCF2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: years.length,
        itemBuilder: (context, index) {
          final item = years[index];

          return _buildYearCard(
            year: item["year"],
            sets: item["sets"],
          );
        },
      ),
    );
  }

  Widget _buildYearCard({
    required String year,
    required int sets,
  }) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to sets page if needed
        print("Clicked Year $year");
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Year $year",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "$sets Sets",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}