import 'package:flutter/material.dart';

class VideoCardWidget extends StatelessWidget {
  final Map<String, String> video;
  final VoidCallback? onTap;

  const VideoCardWidget({super.key, required this.video, this.onTap});

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFF6200EE);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: accent.withOpacity(.25), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              /// Left Icon
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_circle_fill_rounded,
                  color: accent,
                  size: 34,
                ),
              ),

              const SizedBox(width: 18),

              /// Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video["title"] ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff1E293B),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      video["duration"] ?? "Watch Video",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              /// Right Arrow
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
