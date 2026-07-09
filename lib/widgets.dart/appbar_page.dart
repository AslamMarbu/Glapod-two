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
  final Widget? trailingWidget;
  final PreferredSizeWidget? bottom;
  final List<Widget>? customActions;

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
    this.trailingWidget,
    this.customActions,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(
    bottom == null ? height : height + (bottom?.preferredSize.height ?? 0),
  );
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
        widget.postId.toString(),
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
      automaticallyImplyLeading: false,
      elevation: 4,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      bottom: widget.bottom,

      title: null,
      leading: null,
      actions: null,

      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff6200EE), Color(0xff7B1FFF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: [
                  if (!widget.isDashboard)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),

                  Expanded(
                    child: widget.isDashboard
                        ? _buildDashboardTitle()
                        : _buildStandardTitle(),
                  ),

                  if (_buildActions(context) != null)
                    ..._buildActions(context)!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget actionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.15),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(.25)),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildDashboardTitle() {
    return Row(
      children: [
        Hero(
          tag: "logo",
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset("assets/images/logoo.png", height: 36),
          ),
        ),

        const SizedBox(width: 14),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "EdMaster",
              style: GoogleFonts.poppins(
                fontSize: 21,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: .3,
              ),
            ),

            Text(
              "Learn Smarter Everyday",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
            ),
          ],
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
          StringUtils.toSentenceCase(widget.title ?? ""),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),

        if (widget.isSubtitle)
          Text(
            widget.subtitleText ?? "",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
          ),
      ],
    );
  }

  List<Widget>? _buildActions(BuildContext context) {
    if (widget.customActions != null) {
      return widget.customActions;
    }
    if (widget.trailingWidget != null) {
      return [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: widget.trailingWidget!,
        ),
      ];
    }
    if (widget.isDashboard) {
      return [
        actionButton(
          icon: Icons.person_outline_rounded,
          onTap: () =>
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              ).then((_) {
                if (widget.isDashboard) setState(() {});
              }),
        ),

        actionButton(
          icon: Icons.notifications_none_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationPage()),
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
            color: _isLoading
                ? Colors.white.withOpacity(0.2)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: actionButton(
            icon: isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
            iconColor: isFavorite ? Colors.redAccent : Colors.white,
            onTap: _isLoading ? () {} : _handleBookmarkToggle,
          ),
        ),
        actionButton(
          icon: Icons.ios_share_rounded,
          onTap: () {
            String finalMessage =
                widget.shareText ??
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
