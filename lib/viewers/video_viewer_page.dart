import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class VideoViewerPage extends StatefulWidget {
  final String path, title;

  const VideoViewerPage({
    super.key,
    required this.path,
    required this.title,
  });

  @override
  State<VideoViewerPage> createState() => _VideoViewerPageState();
}

class _VideoViewerPageState extends State<VideoViewerPage> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController =
          VideoPlayerController.file(File(widget.path));

      await _videoController.initialize();

      if (!mounted) return;

      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          aspectRatio:
          _videoController.value.aspectRatio == 0
              ? 16 / 9
              : _videoController.value.aspectRatio,
        );
      });
    } catch (e) {
      setState(() {
        _isError = true;
      });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis, // 🔹 prevents overflow
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _isError
            ? const Text(
          "Failed to load video",
          style: TextStyle(color: Colors.white),
        )
            : _chewieController != null
            ? AspectRatio(
          aspectRatio: _chewieController!
              .aspectRatio!,
          child: Chewie(
            controller: _chewieController!,
          ),
        )
            : SizedBox(
          width: width * 0.1,
          height: width * 0.1,
          child: const CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}