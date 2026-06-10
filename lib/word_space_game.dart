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
      "letters": ["S", "A", "V", "E", "D"],
      "verticalWord": "SAVE",
      "horizontalWord": "SAD",
    },

    {
      "letters": ["C", "A", "T"],
      "verticalWord": "CAT",
      "horizontalWord": "AT",
    },

    {
      "letters": ["F", "I", "S", "H"],
      "verticalWord": "FISH",
      "horizontalWord": "HI",
    },

    {
      "letters": ["B", "O", "O", "K"],
      "verticalWord": "BOOK",
      "horizontalWord": "BOO",
    },

    {
      "letters": ["G", "A", "M", "E"],
      "verticalWord": "GAME",
      "horizontalWord": "ME",
    },
  ];

  int currentLevel = 0;

  List<String> foundWords = [];
  List<String> selectedLetters = [];

  String currentWord = "";

  /// SELECT LETTER
  void selectLetter(String letter) {
    setState(() {
      selectedLetters.add(letter);

      currentWord = selectedLetters.join("");

      final verticalWord = levels[currentLevel]['verticalWord'];

      final horizontalWord = levels[currentLevel]['horizontalWord'];

      final answers = [verticalWord, horizontalWord];

      if (answers.contains(currentWord) && !foundWords.contains(currentWord)) {
        foundWords.add(currentWord);

        selectedLetters.clear();

        currentWord = "";

        checkLevelCompleted();
      }
    });
  }

  /// CLEAR
  void clearSelection() {
    setState(() {
      selectedLetters.clear();

      currentWord = "";
    });
  }

  /// CHECK LEVEL
  void checkLevelCompleted() {
    final verticalWord = levels[currentLevel]['verticalWord'];

    final horizontalWord = levels[currentLevel]['horizontalWord'];

    final answers = [verticalWord, horizontalWord];

    if (foundWords.length == answers.length) {
      Future.delayed(const Duration(milliseconds: 500), () {
        showDialog(
          context: context,
          barrierDismissible: false,

          builder: (_) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              title: const Text(
                "🎉 Level Completed",
                textAlign: TextAlign.center,
              ),

              content: const Text("Great Job!", textAlign: TextAlign.center),

              actions: [
                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);

                      if (currentLevel < levels.length - 1) {
                        setState(() {
                          currentLevel++;

                          foundWords.clear();

                          selectedLetters.clear();

                          currentWord = "";
                        });
                      }
                    },

                    child: const Text("Next Level"),
                  ),
                ),
              ],
            );
          },
        );
      });
    }
  }

  /// LETTER CIRCLE
  Widget buildLetterCircle() {
    final letters = List<String>.from(levels[currentLevel]['letters']);

    return Container(
      width: 300,
      height: 300,

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        shape: BoxShape.circle,
      ),

      child: Stack(
        children: List.generate(letters.length, (index) {
          double angle = (2 * pi / letters.length) * index;

          double radius = 100;

          double x = 120 + radius * cos(angle);

          double y = 120 + radius * sin(angle);

          return Positioned(
            left: x,
            top: y,

            child: GestureDetector(
              onTap: () {
                selectLetter(letters[index]);
              },

              child: Container(
                width: 60,
                height: 60,

                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),

                      blurRadius: 8,
                    ),
                  ],
                ),

                alignment: Alignment.center,

                child: Text(
                  letters[index],

                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,

                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final verticalWord = levels[currentLevel]['verticalWord'];

    final horizontalWord = levels[currentLevel]['horizontalWord'];

    return Scaffold(
      body: Container(
        width: double.infinity,

        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/game_bg.png"),

            fit: BoxFit.cover,
          ),
        ),

        child: Container(
          color: Colors.black.withOpacity(0.25),

          child: SafeArea(
            child: Column(
              children: [
                /// TOP BAR
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },

                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 30,
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
                              color: Colors.white70,

                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// CROSSWORD
                Container(
                  height: 280,
                  width: double.infinity,

                  child: Stack(
                    children: [
                      /// VERTICAL WORD
                      Positioned(
                        left: 40,
                        top: 20,

                        child: Column(
                          children: List.generate(verticalWord.length, (i) {
                            bool found = foundWords.contains(verticalWord);

                            return Container(
                              width: 55,
                              height: 55,

                              margin: const EdgeInsets.all(4),

                              decoration: BoxDecoration(
                                color: found
                                    ? Colors.green
                                    : Colors.white.withOpacity(0.25),

                                borderRadius: BorderRadius.circular(10),
                              ),

                              alignment: Alignment.center,

                              child: Text(
                                found ? verticalWord[i] : "",

                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,

                                  color: Colors.white,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      /// HORIZONTAL WORD
                      Positioned(
                        left: 120,
                        top: 120,

                        child: Row(
                          children: List.generate(horizontalWord.length, (i) {
                            bool found = foundWords.contains(horizontalWord);

                            return Container(
                              width: 55,
                              height: 55,

                              margin: const EdgeInsets.all(4),

                              decoration: BoxDecoration(
                                color: found
                                    ? Colors.green
                                    : Colors.white.withOpacity(0.25),

                                borderRadius: BorderRadius.circular(10),
                              ),

                              alignment: Alignment.center,

                              child: Text(
                                found ? horizontalWord[i] : "",

                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,

                                  color: Colors.white,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),

                /// CURRENT WORD
                Text(
                  currentWord,

                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,

                    color: Colors.yellow,
                  ),
                ),

                const Spacer(),

                /// LETTER CIRCLE
                buildLetterCircle(),

                const SizedBox(height: 20),

                /// CLEAR BUTTON
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 14,
                    ),
                  ),
                  onPressed: clearSelection,
                  child: const Text(
                    "CLEAR",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
