import 'package:flutter/material.dart';
import 'widgets.dart/appbar_page.dart';
import 'services/student_service.dart';
import 'widgets.dart/empty_state_widget.dart'; // Using the widget created earlier
import 'chapter_solution_details.dart';
import 'question_bank_single_view_page.dart';

class MyFavouritesPage extends StatefulWidget {
  const MyFavouritesPage({super.key});

  @override
  State<MyFavouritesPage> createState() => _MyFavouritesPageState();
}

class _MyFavouritesPageState extends State<MyFavouritesPage> {
  List<dynamic> _questions = [];
  List<dynamic> _solutions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final response = await StudentService.fetchBookmarks();
    if (response != null && response['status'] == true) {
      setState(() {
        _questions = response['favourite_list']['question_bank'] ?? [];
        _solutions = response['favourite_list']['textbook_solutions'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1FAF2),
        appBar: CustomAppBar(
          height: 120,
          title: "My Favourites",
          isDashboard: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: Container(
              padding: const EdgeInsets.only(bottom: 20, left: 30, right: 30),
              child: const TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 4,
                dividerColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                tabs: [
                  Tab(text: "Questions"),
                  Tab(text: "Solutions"),
                ],
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            _buildListSection(_questions, "Question"),
            _buildListSection(_solutions, "Solution"),
          ],
        ),
      ),
    );
  }

  Widget _buildListSection(List<dynamic> list, String type) {
    if (list.isEmpty) {
      return EmptyStateWidget(msg: "No favourite ${type.toLowerCase()}s saved yet.");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return GestureDetector(
          // Inside _buildListSection in MyFavouritesPage.dart
          onTap: () {
            // 1. Common Mapping: Convert API keys to the ones used in your View Pages
            List<dynamic> mappedList = list.map((item) {
              return {
                'id': item['question_id'], // Map question_id to 'id'
                'title': item['question'] != null && item['question'].length > 20
                    ? "${item['question'].substring(0, 20)}..."
                    : (item['question'] ?? "Detail"),
                'question': item['question'] ?? "",
                'answer': item['answer'] ?? "",
                'bookmark': true, // Since it's from the bookmark list, it's true
              };
            }).toList();

            if (type == "Question") {
              // Navigate to Question Bank View
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuestionViewPage(
                    title: "Favourite Questions",
                    qaList: mappedList,
                    initialIndex: index,
                  ),
                ),
              ).then((_) => _loadBookmarks()); // Refresh list when returning
            } else {
              // Navigate to Solution View
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChapterSolutionDetailsPage(
                    exerciseTitle: "Favourite Solutions",
                    qaList: mappedList,
                    initialIndex: index,
                  ),
                ),
              ).then((_) => _loadBookmarks()); // Refresh list when returning
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  type == "Question" ? Icons.help_outline : Icons.check_circle_outline,
                  color: const Color(0xFF1B75BB),
                  size: 28,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['question'] ?? "No Title",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Mark: ${item['mark'] ?? 'N/A'}",
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}