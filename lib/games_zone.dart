import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:glapod/quiz_game.dart';
import 'package:glapod/word_space_game.dart';
import 'widgets.dart/appbar_page.dart';

class GamesZonePage extends StatefulWidget {
  const GamesZonePage({super.key});

  @override
  State<GamesZonePage> createState() => _GamesZonePageState();
}

class _GamesZonePageState extends State<GamesZonePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMuted = false; // 1. Added mute state tracker

  // Updated layout mapping with rich gradients and crisp contrasting colors matching image_93451d.png
  final List<Map<String, dynamic>> games = [
    {
      "title": "Color Fill",
      "subtitle": "Fun coloring game for kids",
      "image": "assets/images/color_fill.png",
      "score": 120,
      "stars": 5,
      "gradient": const LinearGradient(
        colors: [Color(0xFFFFC64B), Color(0xFFE88905)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      "btnIconColor": const Color(0xFFE88905),
    },
    {
      "title": "Spelling Quiz",
      "subtitle": "Learn correct spelling",
      "image": "assets/images/spelling_quizz.png",
      "score": 340,
      "stars": 5,
      "gradient": const LinearGradient(
        colors: [Color(0xFFB189FF), Color(0xFF7B41F5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      "btnIconColor": const Color(0xFF7B41F5),
    },
    {
      "title": "Word Space",
      "subtitle": "Build words and improve vocabulary",
      "image": "assets/images/wordspace.png",
      "score": 280,
      "stars": 5,
      "gradient": const LinearGradient(
        colors: [Color(0xFF6EDAA3), Color(0xFF1F9E68)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      "btnIconColor": const Color(0xFF1F9E68),
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

  // 2. Added method to toggle mute state dynamically
  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    // Set volume to 0.0 if muted, or restore to original 0.4 if unmuted
    await _audioPlayer.setVolume(_isMuted ? 0.0 : 0.4);
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
      appBar: CustomAppBar(
        height: 70,
        title: "Games Zone",

        trailingWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _toggleMute,
              child: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars, color: Colors.white, size: 18),

                  SizedBox(width: 5),

                  Text(
                    "120",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF63AAED), // Sky Blue
                  Color.fromARGB(255, 240, 255, 101), // Light Blue
                  Color.fromARGB(255, 255, 184, 90), // White
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.25),
              ),
            ),
          ),

          Positioned(
            top: 120,
            left: 80,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromARGB(
                  255,
                  255,
                  255,
                  255,
                ).withOpacity(0.25),
              ),
            ),
          ),

          Positioned(
            bottom: -100,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.25),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // We use an Expanded + Center combo to keep the content mathematically in the middle of the remaining space
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: games.map((game) {
                                  return _buildGameCard(context, game);
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _fallbackControllerIcon(context, error, stackTrace) {
    return const Icon(
      Icons.sports_esports_rounded,
      size: 48,
      color: Color(0xFF1E438A),
    );
  }

  Widget _buildGameCard(BuildContext context, Map<String, dynamic> game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        gradient: game['gradient'],
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: () {
            if (game['title'] == "Spelling Quiz") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QuizGamePage()),
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Character Illustration Vector Space
                Container(
                  width: 95,
                  height: 95,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(game['image']),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Card details panel
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        game['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game['subtitle'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Score layout with mini stars alignment
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: Color(0xFFFFF066),
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${game['score']}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Row(
                            children: List.generate(
                              game['stars'],
                              (index) => const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFF066),
                                size: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Pure white circular action button matching the layout
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: game['btnIconColor'],
                    size: 32,
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
