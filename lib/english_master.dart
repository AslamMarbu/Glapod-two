import 'package:flutter/material.dart';
import 'widgets.dart/appbar_page.dart';
import 'package:glapod/translator_page.dart';
import 'english_master_grammer.dart';

class EnglishMasterPage extends StatelessWidget {
  const EnglishMasterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {"title": "Grammar", "icon": Icons.menu_book},
      {"title": "Translator", "icon": Icons.translate},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
      appBar: const CustomAppBar(height: 70, title: "English Master"),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final item = items[index];

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (item["title"] == "Grammar") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EnglishMasterGrammarPage(),
                  ),
                );
              } else if (item["title"] == "Translator") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TranslatorPage()),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item["icon"] as IconData, size: 55, color: Colors.green),
                  const SizedBox(height: 15),
                  Text(
                    item["title"] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
