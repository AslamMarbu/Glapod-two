import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart'; // Ensure shimmer is in pubspec.yaml
import '../providers/video_provider.dart';
import 'widgets.dart/appbar_page.dart';

// --- SHIMMER PLACEHOLDER WIDGET ---
class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class VideoListingPage extends StatefulWidget {
  final String chapterTitle;
  final String subjectName;
  final dynamic chapterId;

  const VideoListingPage({
    super.key,
    required this.chapterTitle,
    required this.chapterId,
    required this.subjectName,
  });

  @override
  State<VideoListingPage> createState() => _VideoListingPageState();
}

class _VideoListingPageState extends State<VideoListingPage> {
  YoutubePlayerController? _controller;
  bool _isVideoSelected = false;
  String? _activeVideoTitle;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<VideoProvider>().initialFetch(widget.chapterId)
    );
  }

  void _onVideoSelected(String url, String? title, int index) {
    final id = YoutubePlayer.convertUrlToId(url);
    if (id != null) {
      setState(() {
        _activeVideoTitle = title ?? "Video ${index + 1}";
        _isVideoSelected = true;

        if (_controller == null) {
          _controller = YoutubePlayerController(
            initialVideoId: id,
            flags: const YoutubePlayerFlags(autoPlay: true),
          )..addListener(() { if (mounted) setState(() {}); });
        } else {
          _controller!.load(id);
        }
      });
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VideoProvider>();

    return YoutubePlayerBuilder(
      onEnterFullScreen: () => SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]),
      onExitFullScreen: () => SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
      player: YoutubePlayer(
        controller: _controller ?? YoutubePlayerController(initialVideoId: ""),
        showVideoProgressIndicator: true,
      ),
      builder: (context, player) {
        bool isFull = _controller?.value.isFullScreen ?? false;

        return Scaffold(
          backgroundColor: const Color(0xFFF1FAF2),
          appBar: isFull ? null : CustomAppBar(
            height: 60,
            title: widget.chapterTitle,
            isSubtitle: true,
            subtitleText: widget.subjectName,
            isDashboard: false,
          ),
          body: vp.isPageLoading
              ? _buildFullPageShimmer() // 🔹 Full page shimmer
              : Column(
            children: [
              if (_isVideoSelected && _controller != null)
                Column(
                  children: [
                    player,
                    if (!isFull)
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        color: Colors.white,
                        child: Text(_activeVideoTitle!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              if (!isFull)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLanguageHeader(vp),
                        _buildVideoListBody(vp),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // 🔹 Shimmer for the entire page (Header + Video List)
  Widget _buildFullPageShimmer() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerPlaceholder(width: 150, height: 20),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(3, (index) => const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: ShimmerPlaceholder(width: 80, height: 35, borderRadius: 20),
                  )),
                ),
                const SizedBox(height: 25),
                const ShimmerPlaceholder(width: 120, height: 20),
              ],
            ),
          ),
          _buildVideoListShimmer(),
        ],
      ),
    );
  }

  // 🔹 Shimmer specifically for the video list
  Widget _buildVideoListShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const ShimmerPlaceholder(width: 65, height: 65, borderRadius: 15),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerPlaceholder(width: 60, height: 12),
                    SizedBox(height: 8),
                    ShimmerPlaceholder(width: double.infinity, height: 16),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const ShimmerPlaceholder(width: 30, height: 30, borderRadius: 15),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageHeader(VideoProvider vp) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Video Language", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: vp.languages.map((lang) {
                bool isSelected = vp.selectedLanguageId == vp.toSafeInt(lang['id']);
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(lang['language'] ?? ""),
                    selected: isSelected,
                    selectedColor: const Color(0xFF1B75BB),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                    onSelected: (val) {
                      if (val) {
                        vp.selectLanguage(lang, widget.chapterId);
                        setState(() => _isVideoSelected = false);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Text("Videos (${vp.selectedLanguageName})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildVideoListBody(VideoProvider vp) {
    // 🔹 Shimmer specifically for when switching languages
    if (vp.isVideosLoading) return _buildVideoListShimmer();

    if (vp.videos.isEmpty) return const Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text("No videos found.")));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vp.videos.length,
      itemBuilder: (context, index) {
        final video = vp.videos[index];
        return GestureDetector(
          onTap: () => _onVideoSelected(video['video_url'], video['title'], index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                _buildPlayThumbnail(),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Part ${index + 1}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(video['title'] ?? "Video Title", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                const Icon(Icons.play_circle_fill, color: Color(0xFF1B75BB), size: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayThumbnail() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 65, width: 65,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(colors: [Color(0xFF53D4FF), Color(0xFF2478FF)]),
          ),
        ),
        const Icon(Icons.play_arrow, color: Colors.white, size: 35),
      ],
    );
  }
}