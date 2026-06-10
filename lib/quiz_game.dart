import 'package:flutter/material.dart';

class QuizGamePage extends StatefulWidget {
  const QuizGamePage({super.key});

  @override
  State<QuizGamePage> createState() => _QuizGamePageState();
}

class _QuizGamePageState extends State<QuizGamePage> {
  int currentQuestion = 0;
  int score = 0;
  bool answered = false;
  int selectedIndex = -1;

  final List<Map<String, dynamic>> questions = [
    {
      "question": "Which animal is called King of Jungle?",
      "options": ["Tiger", "Lion", "Elephant", "Monkey"],
      "answer": 1,
    },
    {
      "question": "2 + 5 = ?",
      "options": ["5", "6", "7", "8"],
      "answer": 2,
    },
    {
      "question": "Which planet is known as Red Planet?",
      "options": ["Earth", "Mars", "Venus", "Jupiter"],
      "answer": 1,
    },
    {
      "question": "Flutter is developed by?",
      "options": ["Apple", "Google", "Meta", "Microsoft"],
      "answer": 1,
    },
  ];

  void checkAnswer(int index) {
    if (answered) return;

    setState(() {
      answered = true;
      selectedIndex = index;

      if (index == questions[currentQuestion]['answer']) {
        score += 10;
      }
    });
  }

  void nextQuestion() {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        answered = false;
        selectedIndex = -1;
      });
    } else {
      showResult();
    }
  }

  void showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,

      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),

          title: const Text("🎉 Quiz Completed", textAlign: TextAlign.center),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Your Score",
                style: TextStyle(color: Colors.grey.shade700, fontSize: 18),
              ),

              const SizedBox(height: 12),

              Text(
                "$score",
                style: const TextStyle(
                  fontSize: 45,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),

          actions: [
            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                onPressed: () {
                  Navigator.pop(context);

                  setState(() {
                    currentQuestion = 0;
                    score = 0;
                    answered = false;
                    selectedIndex = -1;
                  });
                },

                child: const Text("Play Again", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestion];

    return Scaffold(
      appBar: AppBar(title: const Text("🧠 Quiz Game"), centerTitle: true),

      body: Container(
        width: double.infinity,

        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/game_bg.jpg"),
            fit: BoxFit.cover,
          ),
        ),

        child: Container(
          color: Colors.black.withOpacity(0.15),

          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                /// SCORE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Text(
                      "Question ${currentQuestion + 1}/${questions.length}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Text(
                        "⭐ $score",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                /// QUESTION CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white.withOpacity(0.95),
                  ),

                  child: Text(
                    question['question'],
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                /// OPTIONS
                ...List.generate(question['options'].length, (index) {
                  Color cardColor = Colors.white;

                  if (answered) {
                    if (index == question['answer']) {
                      cardColor = Colors.green;
                    } else if (index == selectedIndex) {
                      cardColor = Colors.red;
                    }
                  }

                  return GestureDetector(
                    onTap: () => checkAnswer(index),

                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),

                      margin: const EdgeInsets.only(bottom: 18),

                      padding: const EdgeInsets.all(18),

                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(22),
                      ),

                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(width: 18),

                          Expanded(
                            child: Text(
                              question['options'][index],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const Spacer(),

                /// NEXT BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 60,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    onPressed: answered ? nextQuestion : null,

                    child: Text(
                      currentQuestion == questions.length - 1
                          ? "Finish Quiz 🚀"
                          : "Next Question ➜",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
