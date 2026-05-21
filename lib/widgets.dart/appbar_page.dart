import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../profile.dart';
import '../notification_page.dart';
import '../services/student_service.dart';
import 'package:glapod/utils/string_utilities.dart';


class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final double height;
  final String? title;
  final String? subtitleText;
  final bool isDashboard;
  final bool isSubtitle;
  final bool actionRequired;
  final PreferredSizeWidget? bottom;

  final int? postId;
  final String? bookmarkType;
  final bool initialBookmarked;
  final String? shareText;
  final Function(bool)? onBookmarkChanged;

  const CustomAppBar({
    super.key,
    required this.height,
    this.title,
    this.subtitleText,
    this.isDashboard = false,
    this.isSubtitle = false,
    this.bottom,
    this.actionRequired = false,
    this.postId,
    this.bookmarkType,
    this.initialBookmarked = false,
    this.onBookmarkChanged,
    this.shareText,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(
      bottom == null ? height : height + (bottom?.preferredSize.height ?? 0));
}

class _CustomAppBarState extends State<CustomAppBar> {
  late bool isFavorite;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.initialBookmarked;
  }

  Future<void> _handleBookmarkToggle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final bool success = await StudentService.toggleBookmark(
          widget.bookmarkType ?? "question_bank",
          widget.postId.toString()
      );

      if (success) {
        setState(() => isFavorite = !isFavorite);
        if (widget.onBookmarkChanged != null) {
          widget.onBookmarkChanged!(isFavorite);
        }
      }
    } catch (e) {
      debugPrint("Bookmark Toggle Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: widget.height,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: !widget.isDashboard,
      leading: !widget.isDashboard
          ? IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      )
          : null,
      iconTheme: const IconThemeData(color: Colors.white),
      bottom: widget.bottom,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B75BB), Color(0xFF6BCF2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          // REMOVED: borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      title: widget.isDashboard ? _buildDashboardTitle() : _buildStandardTitle(),
      actions: _buildActions(context),
    );
  }

  Widget _buildDashboardTitle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset("assets/images/logoo.png", height:50),
        Padding(
          padding: const EdgeInsets.only(top: 4),
           child: Text(
           'EdMaster',
            style: GoogleFonts.comfortaa(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
           letterSpacing: -1.2,
            ),
           ),
        ),
      ],
    );
  }

  Widget _buildStandardTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          StringUtils.toSentenceCase(widget.title.toString()) ?? "",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (widget.isSubtitle && widget.subtitleText != null)
          Text(
            widget.subtitleText!,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
      ],
    );
  }

  List<Widget>? _buildActions(BuildContext context) {
    if (widget.isDashboard) {
      return [
        IconButton(
          icon: const Icon(Icons.person, color: Colors.white),
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage())
          ).then((_) {
            if (widget.isDashboard) setState(() {});
          }),
        ),
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationPage())
          ),
        ),
        const SizedBox(width: 10),
      ];
    }

    if (widget.actionRequired) {
      return [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _isLoading ? Colors.white.withOpacity(0.2) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: _isLoading
                ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : Colors.white,
            ),
            onPressed: _isLoading ? null : _handleBookmarkToggle,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            String finalMessage = widget.shareText ??
                "Check out this ${widget.title ?? 'content'} on Glapod!";
            Share.share(finalMessage);
          },
        ),
        const SizedBox(width: 10),
      ];
    }
    return null;
  }
}