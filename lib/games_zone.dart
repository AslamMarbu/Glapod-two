import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:glapod/quiz_game.dart';
import 'package:glapod/word_space_game.dart';

class GamesZonePage extends StatefulWidget {
  const GamesZonePage({super.key});

  @override
  State<GamesZonePage> createState() => _GamesZonePageState();
}

class _GamesZonePageState extends State<GamesZonePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<Map<String, dynamic>> games = [
    {
      "title": "Color Fill",
      "subtitle": "Fun coloring game for kids",
      "image": "assets/images/colorfill.jpeg",
      "score": 120,
      "stars": 4,
      "colors": [const Color(0xFFFF9966), const Color(0xFFFF5E62)],
    },
    {
      "title": "Spelling Quiz",
      "subtitle": "Learn correct spelling",
      "image": "assets/images/spelling.jpeg",
      "score": 340,
      "stars": 5,
      "colors": [const Color(0xFF7F00FF), const Color(0xFFE100FF)],
    },
    {
      "title": "Word Space",
      "subtitle": "Build words and improve vocabulary",
      "image": "assets/images/wordspace.jpeg",
      "score": 280,
      "stars": 4,
      "colors": [const Color(0xFF11998E), const Color(0xFF38EF7D)],
    },
  ];

  @override
  void initState() {
    super.initState();
    playBackgroundMusic();
  }

  Future<void> playBackgroundMusic() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);

    await _audioPlayer.play(AssetSource("music/audio.mp3"), volume: 0.4);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,

        title: const Text(
          "🎮 Games Zone",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/game_bg.png"),
            fit: BoxFit.cover,
          ),
        ),

        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.15),
                Colors.black.withOpacity(0.08),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),

          child: Stack(
            children: [
              /// FLOATING BUBBLES
              Positioned(
                top: 120,
                left: 20,
                child: _buildBubble(35, Colors.orange),
              ),

              Positioned(
                top: 220,
                right: 30,
                child: _buildBubble(25, Colors.blue),
              ),

              Positioned(
                bottom: 180,
                left: 40,
                child: _buildBubble(28, Colors.green),
              ),

              Positioned(
                bottom: 120,
                right: 50,
                child: _buildBubble(40, Colors.purple),
              ),

              /// GAME LIST
              ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: 100,
                  left: 18,
                  right: 18,
                  bottom: 30,
                ),
                itemCount: games.length,

                itemBuilder: (context, index) {
                  final game = games[index];

                  return Container(
                    height: 150,
                    margin: const EdgeInsets.only(bottom: 22),

                    child: Material(
                      elevation: 10,
                      shadowColor: Colors.black26,
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.transparent,

                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),

                        onTap: () {
                          if (game['title'] == "Spelling Quiz") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QuizGamePage(),
                              ),
                            );
                          } else if (game['title'] == "Word Space") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WordSpaceGamePage(),
                              ),
                            );
                          }
                        },

                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),

                            gradient: LinearGradient(
                              colors: game['colors'],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),

                          child: Stack(
                            children: [
                              Positioned(
                                top: -30,
                                right: -20,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              Positioned(
                                bottom: -35,
                                left: -20,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.06),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(18),

                                child: Row(
                                  children: [
                                    /// IMAGE
                                    Container(
                                      width: 110,
                                      height: 110,

                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),

                                        image: DecorationImage(
                                          image: AssetImage(game['image']),
                                          fit: BoxFit.cover,
                                        ),

                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.18,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 18),

                                    /// DETAILS
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,

                                        mainAxisAlignment:
                                            MainAxisAlignment.center,

                                        children: [
                                          Text(
                                            game['title'],

                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 23,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(height: 8),

                                          Text(
                                            game['subtitle'],

                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.92,
                                              ),
                                              fontSize: 13,
                                              height: 1.3,
                                            ),
                                          ),

                                          const SizedBox(height: 14),

                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 7,
                                                    ),

                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.18),

                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                ),

                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .emoji_events_rounded,
                                                      color: Colors.yellow,
                                                      size: 18,
                                                    ),

                                                    const SizedBox(width: 6),

                                                    Text(
                                                      "${game['score']}",
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(width: 12),

                                              Expanded(
                                                child: Row(
                                                  children: List.generate(
                                                    game['stars'],
                                                    (index) => const Padding(
                                                      padding: EdgeInsets.only(
                                                        right: 2,
                                                      ),
                                                      child: Icon(
                                                        Icons.star_rounded,
                                                        color: Colors.yellow,
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    /// PLAY BUTTON
                                    Container(
                                      width: 52,
                                      height: 52,

                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                      ),

                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.black,
                                        size: 34,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(double size, Color color) {
    return Container(
      width: size,
      height: size,

      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        shape: BoxShape.circle,
      ),
    );
  }
}
