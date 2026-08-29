import 'dart:math';
import 'package:flutter/material.dart';

class WordSpaceGamePage extends StatefulWidget {
  const WordSpaceGamePage({super.key});

  @override
  State<WordSpaceGamePage> createState() => _WordSpaceGamePageState();
}

class _WordSpaceGamePageState extends State<WordSpaceGamePage> {
  /// LEVELS
  final List<Map<String, dynamic>> levels = [
    {
      "letters": ["D", "S", "T", "A", "V", "E", "R"],
      // Layout definitions matching crossword intersections dynamically
      // Structure: [Word, StartRow, StartCol, IsVertical]
      "layout": [
        {"word": "STARTED", "row": 2, "col": 0, "isVertical": false},
        {"word": "SAVED", "row": 0, "col": 3, "isVertical": true},
        {"word": "SAD", "row": 0, "col": 3, "isVertical": false},
        {"word": "RATE", "row": 4, "col": 2, "isVertical": false},
        {"word": "STARE", "row": 6, "col": 1, "isVertical": false},
      ],
    },
  ];

  int currentLevel = 0;
  List<String> foundWords = [];
  List<String> selectedLetters = [];
  String currentWord = "";

  void selectLetter(String letter) {
    setState(() {
      selectedLetters.add(letter);
      currentWord = selectedLetters.join("");

      final List<dynamic> layout = levels[currentLevel]['layout'];
      final targetWords = layout.map((e) => e['word'] as String).toList();

      if (targetWords.contains(currentWord) && !foundWords.contains(currentWord)) {
        foundWords.add(currentWord);
        selectedLetters.clear();
        currentWord = "";
        checkLevelCompleted();
      }
    });
  }

  void clearSelection() {
    setState(() {
      selectedLetters.clear();
      currentWord = "";
    });
  }

  void shuffleLetters() {
    setState(() {
      levels[currentLevel]['letters'].shuffle();
    });
  }

  void checkLevelCompleted() {
    final List<dynamic> layout = levels[currentLevel]['layout'];
    if (foundWords.length == layout.length) {
      Future.delayed(const Duration(milliseconds: 500), () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("🎉 Level Completed", textAlign: TextAlign.center),
            content: const Text("Great Job!", textAlign: TextAlign.center),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Next"),
              )
            ],
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> layouts = levels[currentLevel]['layout'];
    
    // Find grid bounding size dynamically
    int maxRows = 8;
    int maxCols = 8;

    // Create a matrix representation of the crossword puzzle
    List<List<String?>> grid = List.generate(maxRows, (_) => List.filled(maxCols, null));
    for (var item in layouts) {
      String word = item['word'];
      int r = item['row'];
      int c = item['col'];
      bool isVert = item['isVertical'];
      bool isWordFound = foundWords.contains(word);

      for (int i = 0; i < word.length; i++) {
        int targetRow = isVert ? r + i : r;
        int targetCol = isVert ? c : c + i;
        if (isWordFound) {
          grid[targetRow][targetCol] = word[i];
        } else {
          // Placeholder space to render an empty box frame 
          grid[targetRow][targetCol] = grid[targetRow][targetCol] ?? "";
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F4),
      body: Column(
        children: [
          /// TOP HERO HEADER
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFAC1C), Color(0xFFFA7E0A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(36),
              ),
            ),
            padding: const EdgeInsets.only(top: 50, bottom: 24, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "LEVEL ${currentLevel + 1}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "WORD SPACE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BorderRadius.circular(20).toBoxDecoration(Colors.white),
                  child: Row(
                    children: const [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      SizedBox(width: 4),
                      Text("0", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                )
              ],
            ),
          ),

          /// STATUS TRACKER ROW
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Solve the words",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF5A4A42)),
                ),
                Text(
                  "${foundWords.length} / ${layouts.length}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A4A42)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BorderRadius.circular(12).toBoxDecoration(const Color(0xFFFCEEE5)),
                  child: Row(
                    children: const [
                      Icon(Icons.emoji_events, color: Colors.orange, size: 16),
                      SizedBox(width: 4),
                      Text("0", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                )
              ],
            ),
          ),

          /// CROSSWORD BOARD CONTAINER
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF3EAE3), width: 2),
              ),
              child: Center(
                child: InteractiveViewer(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: maxCols,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: maxRows * maxCols,
                    itemBuilder: (context, index) {
                      int r = index ~/ maxCols;
                      int c = index % maxCols;
                      String? char = grid[r][c];

                      if (char == null) return const SizedBox.shrink();

                      bool hasLetter = char.isNotEmpty;
                      return Container(
                        decoration: BoxDecoration(
                          color: hasLetter ? const Color(0xFFFF9100) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasLetter ? const Color(0xFFFF9100) : const Color(0xFF8C75C5),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          char,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: hasLetter ? Colors.white : Colors.transparent,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          /// SELECTED PREVIEW BAR
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              currentWord,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFA7E0A)),
            ),
          ),

          /// INSTRUCTIONS HINT CONTAINER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BorderRadius.circular(20).toBoxDecoration(const Color(0xFFFCEEE5)),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFF5E35B1),
                    child: Icon(Icons.lightbulb_outline, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Connect letters", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("to find the words", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BorderRadius.circular(20).toBoxDecoration(Colors.white),
                    child: Row(
                      children: const [
                        Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                        SizedBox(width: 4),
                        Text("53", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          /// LETTERS WHEEL CIRCLE
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Center(child: buildLetterWheel()),
          ),

          /// FOOTER CONTROL ACTIONS
          Padding(
            padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: shuffleLetters,
                  icon: const Icon(Icons.shuffle, color: Color(0xFF5A4A42)),
                  label: const Text("Shuffle", style: TextStyle(color: Color(0xFF5A4A42))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFEFE5DD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: clearSelection,
                  icon: const Icon(Icons.delete_outline, color: Color(0xFF5A4A42)),
                  label: const Text("Clear", style: TextStyle(color: Color(0xFF5A4A42))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFEFE5DD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLetterWheel() {
    final List<String> letters = List<String>.from(levels[currentLevel]['letters']);
    return Stack(
      alignment: Alignment.center,
      children: [
        // Elliptical dashed trace background matching the asset style
        Container(
          width: 260,
          height: 160,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFD7CDCE),
              width: 2,
              style: BorderStyle.solid, // Use a custom painter if explicit dashes are requested
            ),
            borderRadius: const BorderRadius.all(Radius.elliptical(260, 160)),
          ),
        ),
        ...List.generate(letters.length, (index) {
          // Mathematics mapped horizontally across elliptical parameters
          double angle = (2 * pi / letters.length) * index - (pi / 2);
          double radiusX = 120; 
          double radiusY = 75;

          double x = radiusX * cos(angle);
          double y = radiusY * sin(angle);

          return Transform.translate(
            offset: Offset(x, y),
            child: GestureDetector(
              onTap: () => selectLetter(letters[index]),
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFFA7E0A),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 3))
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  letters[index],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

extension BorderRadiusToBox on BorderRadius {
  BoxDecoration toBoxDecoration(Color color) => BoxDecoration(color: color, borderRadius: this);
}

extension ColorHelpers on Color {
  static const Color whiteEfficacy = Color(0xCCFFFFFF);
}