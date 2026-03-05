import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoUtils {
  static void playVideoPopup(BuildContext context, String videoId, String title) {
    // 1. Initialize the controller inside the helper
    final YoutubePlayerController controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        forceHD: false,
      ),
    );

    // 2. Show the Dialog
    showDialog(
      context: context,
      barrierDismissible: true, // User can tap outside to close
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          contentPadding: EdgeInsets.zero,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The Player
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: YoutubePlayer(
                  controller: controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.blueAccent,
                ),
              ),
              // The Title
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.pause(); // Stop video before closing
                Navigator.pop(context);
              },
              child: const Text("Close", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ).then((_) {
      // 3. CLEANUP: This runs when the dialog is dismissed (via button or tapping outside)
      controller.dispose();
    });
  }
}