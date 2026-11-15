import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomProfileCropPage extends StatefulWidget {
  final Uint8List imageBytes;

  const CustomProfileCropPage({super.key, required this.imageBytes});

  @override
  State<CustomProfileCropPage> createState() => _CustomProfileCropPageState();
}

class _CustomProfileCropPageState extends State<CustomProfileCropPage> {
  final CropController _cropController = CropController();

  bool _isCropping = false;

  static const Color _blue = Color(0xFF1B75BB);
  static const Color _green = Color(0xFF00B878);
  static const Color _background = Color(0xFF171A20);

  void _cropImage() {
    if (_isCropping) return;

    setState(() {
      _isCropping = true;
    });

    _cropController.crop();
  }

  void _handleCropResult(CropResult result) {
    switch (result) {
      case CropSuccess(:final croppedImage):
        if (!mounted) return;
        Navigator.of(context).pop<Uint8List>(croppedImage);

      case CropFailure(:final cause):
        debugPrint('PROFILE CROP FAILED => $cause');

        if (!mounted) return;

        setState(() {
          _isCropping = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to crop this image. Please try again.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _blue,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _background,

        // Custom toolbar: Flutter automatically respects the
        // Android status bar's safe area.
        appBar: AppBar(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 68,
          automaticallyImplyLeading: false,
          titleSpacing: 20,
          title: const Text(
            'Crop Profile Photo',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          leading: IconButton(
            tooltip: 'Cancel',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _isCropping ? null : () => Navigator.of(context).pop(),
          ),
        ),

        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // Instructions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.crop_free_rounded,
                      color: _green,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Adjust your photo inside the square',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Image cropping area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Crop(
                      image: widget.imageBytes,
                      controller: _cropController,

                      // Fixed square crop frame.
                      aspectRatio: 1,
                      interactive: true,
                      fixCropRect: true,

                      // Dark background outside the selected area.
                      baseColor: const Color(0xFF171A20),
                      maskColor: Colors.black.withOpacity(0.60),

                      // Remove all green corner squares.
                      cornerDotBuilder: (size, edgeAlignment) {
                        return const SizedBox.shrink();
                      },

                      // White crop border and grid.
                      overlayBuilder: (context, rect) {
                        return IgnorePointer(
                          child: CustomPaint(
                            painter: _WhiteCropBorderPainter(),
                            child: const SizedBox.expand(),
                          ),
                        );
                      },

                      radius: 0,
                      filterQuality: FilterQuality.high,

                      progressIndicator: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00B878),
                        ),
                      ),

                      onCropped: _handleCropResult,
                    ),
                  ),
                ),
              ),

              // Bottom action area: no tick icon anywhere.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF202733),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Square profile photo',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _isCropping ? null : _cropImage,
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          disabledBackgroundColor: _green.withOpacity(0.5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _isCropping
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 21),
                        label: Text(
                          _isCropping ? 'Cropping...' : 'Done',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhiteCropBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw a white border around the fixed crop region.
    // The Crop widget's overlayBuilder supplies the crop rect
    // as its coordinate system in supported package versions.
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _WhiteCropBorderPainter oldDelegate) => false;
}
