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
      body: Container(
        // Mimicking the playful outdoor background sky and path scenery
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              "assets/images/games_zone_bg.png",
            ), // Add your background scenery asset here
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildHeader(context),
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
                            padding: const EdgeInsets.symmetric(horizontal: 20),
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Circular Soft-Yellow Back Button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBE6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFFE88905),
              ),
            ),
          ),

          // Center Controller Icon & App Title
          Column(
            children: [
              const Image(
                image: AssetImage(
                  "assets/images/gamepad_icon.png",
                ), // Use a cute game controller image asset if available
                height: 44,
                width: 44,
                errorBuilder: _fallbackControllerIcon,
              ),
              const SizedBox(height: 4),
              const Text(
                "Games Zone",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2B6D),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Play, Learn & Have Fun!",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A2B6D).withOpacity(0.6),
                ),
              ),
            ],
          ),

          // 3. Updated Action Section: Wrapped Mute Button and Points badge together
          Row(
            children: [
              // Mute/Unmute Audio Button
              InkWell(
                onTap: _toggleMute,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isMuted
                        ? const Color(0xFFFFEAEA)
                        : const Color(0xFFE6F7FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    size: 20,
                    color: _isMuted
                        ? Colors.redAccent
                        : const Color(0xFF1F9E68),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Dashboard Points Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Colors.orangeAccent,
                      size: 22,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "1250",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
      margin: const EdgeInsets.only(bottom: 20),
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
