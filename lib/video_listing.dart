import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'widgets.dart/appbar_page.dart';
import 'services/student_service.dart';

class VideoListingPage extends StatefulWidget {
  final String chapterTitle;
  final chapterId; // Pass the ID from the previous screen

  const VideoListingPage({
    super.key,
    required this.chapterTitle,
    required this.chapterId
  });

  @override
  State<VideoListingPage> createState() => _VideoListingPageState();
}

class _VideoListingPageState extends State<VideoListingPage> {
  YoutubePlayerController? _controller;
  List<dynamic> _videos = [];
  bool _isLoading = true;
  String? _activeVideoTitle;

  @override
  void initState() {
    super.initState();
    _loadApiData();
  }

  // Calls your mentioned API function
  Future<void> _loadApiData() async {
    try {
      // Calling your function
      final List<dynamic> data = await StudentService.fetchStudyVideos(widget.chapterId.toString());

      if (data.isNotEmpty) {
        setState(() {
          _videos = data;

          // Handle the null title for the first video
          _activeVideoTitle = _videos[0]['title'] ?? "Video 1";

          // Initialize controller with the first URL from API
          final firstId = YoutubePlayer.convertUrlToId(_videos[0]['video_url'])!;
          _controller = YoutubePlayerController(
            initialVideoId: firstId,
            flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
          );
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _onVideoSelected(String url, String? title, int index) {
    final id = YoutubePlayer.convertUrlToId(url);
    if (id != null && _controller != null) {
      setState(() {
        // Fallback for null titles in the selection area
        _activeVideoTitle = title ?? "Video ${index + 1}";
      });
      _controller!.load(id);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(height: 100),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
          ? const Center(child: Text("No videos found"))
          : Column(
        children: [
          // PLAYER
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            color: Colors.white,
            child: Text(
              widget.chapterTitle,
              style: const TextStyle(fontWeight: FontWeight.bold,fontSize:30 ),
            ),
          ),
          if (_controller != null)
            YoutubePlayer(
              controller: _controller!,
              showVideoProgressIndicator: true,
            ),

          // TITLE BAR
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            color: Colors.white,
            child: Text(
              _activeVideoTitle!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // LIST
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _videos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                // FIX 1: Increase this from 0.8 to 1.2 or 1.3 to remove the vertical gap
                childAspectRatio: 1.3,
              ),
              itemBuilder: (context, index) {
                final video = _videos[index];
                final id = YoutubePlayer.convertUrlToId(video['video_url']) ?? "";
                final title = video['title'] ?? "Video ${index + 1}";

                return GestureDetector(
                  onTap: () => _onVideoSelected(video['video_url'], video['title'], index),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                    children: [
                      // FIX 2: Clip the thumbnail to look professional
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          "https://img.youtube.com/vi/$id/mqdefault.jpg",
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}