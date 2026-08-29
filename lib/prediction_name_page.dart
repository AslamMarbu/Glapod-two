import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/prediction_name_provider.dart';
import '../utils/app_colors.dart';
import 'prediction_name_grid_page.dart';
import 'widgets.dart/appbar_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

// --- REUSABLE SHIMMER COMPONENT ---
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

class PredictionNamePage extends StatefulWidget {
  final String categoryName;
  final int categoryId;
  final String level;

  const PredictionNamePage({
    super.key,
    required this.categoryName,
    required this.categoryId,
    required this.level,
  });

  @override
  State<PredictionNamePage> createState() => _PredictionNamePageState();
}

class _PredictionNamePageState extends State<PredictionNamePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late PageController _pageController;
  late ScrollController _scrollController;

  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];

  Timer? _imageSliderTimer;
  bool _isUserTouchingSlider = false;
  List<String> _currentSliderImages = [];

  int _currentImageIndex = 0;
  String _correctAnswer = "";
  dynamic _currentQuestionId;
  bool _isInitialized = false;

  bool _isRestartingQuestions = false;

  // 👁️ Reveal feature state
  bool _showAnswerReveal = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pageController = PageController();
    _scrollController = ScrollController();
    Future.microtask(() => _fetchNewQuestion(status: "new"));
  }

  void _fetchNewQuestion({String? status}) {
    _resetLocalState();
    context.read<PredictionGameProvider>().loadQuestion(
      widget.categoryId,
      widget.level,
      status: status,
    );
  }

  void _resetLocalState() {
    _stopImageAutoSlide();

    setState(() {
      _isInitialized = false;
      _showAnswerReveal = false;
      _currentImageIndex = 0;

      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }

      for (var c in _controllers) {
        c.dispose();
      }

      for (var f in _focusNodes) {
        f.dispose();
      }

      _controllers.clear();
      _focusNodes.clear();
    });
  }

  void _startImageAutoSlide(List<String> images) {
    _imageSliderTimer?.cancel();

    _currentSliderImages = images;

    if (images.length <= 1) return;

    _imageSliderTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted) return;
      if (_isUserTouchingSlider) return;
      if (!_pageController.hasClients) return;
      if (_currentSliderImages.length <= 1) return;

      int nextIndex = _currentImageIndex + 1;

      if (nextIndex >= _currentSliderImages.length) {
        nextIndex = 0;
      }

      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopImageAutoSlide() {
    _imageSliderTimer?.cancel();
    _imageSliderTimer = null;
  }

  Future<void> _preloadQuestionImages(List<String> images) async {
    if (!mounted || images.isEmpty) return;

    final List<String> validImages = images
        .where((url) => url.isNotEmpty && url != 'null')
        .toList();

    if (validImages.isEmpty) return;

    try {
      await precacheImage(
        CachedNetworkImageProvider(validImages.first),
        context,
      );
    } catch (e) {
      debugPrint('First image preload failed: ${validImages.first} - $e');
    }

    if (!mounted) return;

    for (int i = 1; i < validImages.length; i++) {
      if (!mounted) return;

      final String imageUrl = validImages[i];

      try {
        await precacheImage(CachedNetworkImageProvider(imageUrl), context);
      } catch (e) {
        debugPrint('Background image preload failed: $imageUrl - $e');
      }
    }
  }

  void _setupGame(Map<String, dynamic> questionData) {
    _isRestartingQuestions = false;

    _currentQuestionId = questionData['id'];

    final List<String> questionImages = List<String>.from(
      questionData['images'] ?? [],
    );

    if (!_isInitialized && questionImages.isNotEmpty) {
      _startImageAutoSlide(questionImages);
    }

    // Only trigger once per loaded question.
    if (!_isInitialized && questionImages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _preloadQuestionImages(questionImages);
        }
      });
    }

    String rawValue = (questionData['answer'] ?? questionData['name'] ?? "")
        .toString();
    _correctAnswer = rawValue.toUpperCase();

    if (_isInitialized) return;

    if (_correctAnswer.isNotEmpty) {
      for (int i = 0; i < _correctAnswer.length; i++) {
        TextEditingController controller = TextEditingController();
        FocusNode node = FocusNode();

        node.addListener(() {
          if (node.hasFocus) {
            controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller.text.length,
            );
            setState(() {});
          }
        });

        _controllers.add(controller);
        _focusNodes.add(node);
      }

      if (widget.level.toLowerCase() == "intermediate") {
        List<int> letterIndices = [];
        for (int i = 0; i < _correctAnswer.length; i++) {
          if (_correctAnswer[i] != " ") letterIndices.add(i);
        }

        letterIndices.shuffle();
        int hintCount = (letterIndices.length / 3).ceil();
        for (int i = 0; i < hintCount; i++) {
          int targetIdx = letterIndices[i];
          _controllers[targetIdx].text = _correctAnswer[targetIdx];
        }
      }

      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _focusFirstEmpty();
        });
      });
    }
  }

  void _focusFirstEmpty() {
    for (int i = 0; i < _controllers.length; i++) {
      if (_controllers[i].text.isEmpty) {
        _focusNodes[i].requestFocus();
        SystemChannels.textInput.invokeMethod('TextInput.show');
        break;
      }
    }
  }

  Future<void> _handleNext() async {
    String enteredWord = _enteredWord();

    if (enteredWord != _cleanCorrectAnswer()) {
      _triggerShake();
      return;
    }

    _fetchNewQuestion();
  }

  void _triggerShake() {
    if (!_shakeController.isAnimating) {
      _shakeController.forward(from: 0.0);
      HapticFeedback.vibrate();
    }
  }

  void _clearInputs() {
    for (var controller in _controllers) controller.clear();
    setState(() {});
    _focusFirstEmpty();
  }

  @override
  void dispose() {
    _imageSliderTimer?.cancel();

    _shakeController.dispose();
    _pageController.dispose();

    for (var c in _controllers) {
      c.dispose();
    }

    for (var f in _focusNodes) {
      f.dispose();
    }

    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<PredictionGameProvider>();

    if (!game.isLoading &&
        game.currentResponse != null &&
        game.currentResponse!['question'] != null) {
      _setupGame(game.currentResponse!['question']);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: CustomAppBar(
        height: 70,
        title: widget.categoryName,
        isDashboard: false,
        customActions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                setState(() => _isInitialized = false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PredictionNameGridPage(
                      categoryName: widget.categoryName,
                      categoryId: widget.categoryId,
                      level: widget.level,
                    ),
                  ),
                );
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(.25)),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: game.isLoading
          ? _buildShimmerLoading()
          : game.hasNoData
          ? _buildNoQuestionsFound()
          : game.isCompleted
          ? _buildQuizCompleted()
          : _buildGameContent(game),
    );
  }

  Widget _buildShimmerLoading() {
    double screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerPlaceholder(
              width: screenWidth,
              height: screenWidth * 0.6,
              borderRadius: 24,
            ),
          ),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: List.generate(
                6,
                (index) => const ShimmerPlaceholder(
                  width: 38,
                  height: 50,
                  borderRadius: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerPlaceholder(
              width: screenWidth,
              height: 75,
              borderRadius: 16,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerPlaceholder(
              width: screenWidth,
              height: 75,
              borderRadius: 16,
            ),
          ),
          const SizedBox(height: 40),
          const ShimmerPlaceholder(width: 220, height: 55, borderRadius: 30),
        ],
      ),
    );
  }

  Widget _buildGameContent(PredictionGameProvider game) {
    final response = game.currentResponse;

    if (response == null) {
      return const SizedBox.shrink();
    }

    if (response['question'] == null) {
      return const SizedBox.shrink();
    }

    if (_correctAnswer.isEmpty) {
      return const SizedBox.shrink();
    }

    final images = List<String>.from(response['question']['images'] ?? []);

    final dynamicNotes =
        response['question']['notes'] ??
        response['question']['description'] ??
        "No notes available.";

    final dynamicRemarks = response['question']['remarks'] ?? "GENERAL";

    final String enteredWord = _enteredWord();
    final bool isCorrect = enteredWord == _cleanCorrectAnswer();

    final bool isBeginnerMode = widget.level.toLowerCase() == "beginner";

    final bool keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(bottom: keyboardOpen ? 4 : 14),
            child: Column(
              children: [
                const SizedBox(height: 16),

                if (images.isNotEmpty) _buildCardImageSlider(images),

                const SizedBox(height: 14),

                _buildAnswerHeader(isBeginnerMode: isBeginnerMode),

                SizedBox(height: keyboardOpen ? 8 : 14),

                _buildInputGrid(),

                if (!keyboardOpen) ...[
                  const SizedBox(height: 14),

                  _buildRemarksCard(dynamicRemarks),

                  if (isCorrect) ...[
                    const SizedBox(height: 12),
                    _buildNotesBox(dynamicNotes),
                  ],
                ],
              ],
            ),
          ),
        ),

        SafeArea(
          top: false,
          minimum: EdgeInsets.fromLTRB(
            28,
            keyboardOpen ? 4 : 8,
            28,
            keyboardOpen ? 4 : 10,
          ),
          child: _buildBottomButton(),
        ),
      ],
    );
  }

  Widget _buildQuizCompleted() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 58,
                color: Color(0xFF2E7D32),
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              'Category Completed!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Great job! You have completed all available questions '
              'in this category for this level.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'You can return to the categories and choose another topic '
              'or play this category again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey.shade500,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: 190,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                label: const Text(
                  'Choose Category',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestartShimmer() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildAnswerHeader({required bool isBeginnerMode}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 22, height: 1, color: Colors.grey.shade300),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isBeginnerMode ? _correctAnswer : "GUESS THE NAME",
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isBeginnerMode ? 22 : 13,
                fontWeight: FontWeight.w800,
                letterSpacing: isBeginnerMode ? 1.5 : 1.2,
                color: isBeginnerMode
                    ? const Color(0xFF322881)
                    : Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 22, height: 1, color: Colors.grey.shade300),
          if (!isBeginnerMode) ...[
            const SizedBox(width: 4),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Icon(
                _showAnswerReveal
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: 21,
                color: _showAnswerReveal
                    ? const Color(0xFF5A44C4)
                    : Colors.grey.shade400,
              ),
              onPressed: () {
                setState(() {
                  _showAnswerReveal = !_showAnswerReveal;
                });
              },
              tooltip: "Toggle Hint Layer",
            ),
          ],
        ],
      ),
    );
  }

  String _enteredWord() {
    final buffer = StringBuffer();
    for (int i = 0; i < _controllers.length; i++) {
      if (i < _correctAnswer.length && _correctAnswer[i] == ' ') continue;
      buffer.write(_controllers[i].text.toUpperCase());
    }
    return buffer.toString();
  }

  String _cleanCorrectAnswer() => _correctAnswer.replaceAll(' ', '');

  Widget _buildInputGrid() {
    final String targetPhrase = _correctAnswer.toUpperCase();

    final List<List<int>> wordIndices = [];
    List<int> currentWord = [];

    for (int i = 0; i < targetPhrase.length; i++) {
      if (targetPhrase[i] == ' ') {
        if (currentWord.isNotEmpty) {
          wordIndices.add(currentWord);
          currentWord = [];
        }
      } else {
        currentWord.add(i);
      }
    }

    if (currentWord.isNotEmpty) {
      wordIndices.add(currentWord);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double sidePadding = 24;
        const double letterSpacing = 4;

        final double availableWidth = constraints.maxWidth - sidePadding;

        final int longestWordLength = wordIndices.isEmpty
            ? 1
            : wordIndices
                  .map((word) => word.length)
                  .reduce((a, b) => a > b ? a : b);

        final double totalSpacing = (longestWordLength - 1) * letterSpacing;

        double boxWidth = (availableWidth - totalSpacing) / longestWordLength;

        // Short words keep comfortable boxes, long words automatically shrink.
        boxWidth = boxWidth.clamp(22.0, 40.0).toDouble();

        double boxHeight = (boxWidth * 1.25).clamp(36.0, 50.0).toDouble();

        return AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final double offset = _shakeController.isAnimating
                ? (0.5 - (0.5 - _shakeController.value).abs()) * 15
                : 0.0;

            return Transform.translate(
              offset: Offset(offset, 0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: wordIndices.map((indices) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(indices.length, (position) {
                        final int index = indices[position];

                        return Padding(
                          padding: EdgeInsets.only(
                            right: position == indices.length - 1
                                ? 0
                                : letterSpacing,
                          ),
                          child: _buildModernInputBox(
                            index,
                            width: boxWidth,
                            height: boxHeight,
                          ),
                        );
                      }),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernInputBox(
    int index, {
    required double width,
    required double height,
  }) {
    bool hasFocus = _focusNodes[index].hasFocus;
    bool hasText = _controllers[index].text.isNotEmpty;

    String enteredWord = _enteredWord();
    String cleanCorrectAnswer = _cleanCorrectAnswer();

    bool isWordComplete = enteredWord.length == cleanCorrectAnswer.length;
    bool isCorrect = enteredWord == cleanCorrectAnswer;

    Color boxBgColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    double borderWidth = 1.2;
    Color textColor = const Color(0xFF322881);

    if (isWordComplete) {
      if (isCorrect) {
        boxBgColor = const Color(0xFFE8F5E9);
        borderColor = Colors.green.shade600;
        borderWidth = 2.0;
        textColor = Colors.green.shade900;
      } else {
        boxBgColor = const Color(0xFFFFEBEE);
        borderColor = Colors.red.shade600;
        borderWidth = 2.0;
        textColor = Colors.red.shade900;
      }
    } else if (hasText || hasFocus) {
      boxBgColor = const Color(0xFFF2EFFF);
      if (hasFocus) {
        borderColor = const Color(0xFF5A44C4);
        borderWidth = 2.0;
      }
    }

    // Determine the actual letter solution at this absolute index position
    String hiddenLetterHint = _correctAnswer[index];

    final double fontSize = width < 28
        ? 13
        : width < 34
        ? 15
        : 18;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: boxBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          if (!hasFocus && !isWordComplete)
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 👁️ Faded Reveal layer placeholder inside the stack
          if (!hasText && _showAnswerReveal && hiddenLetterHint != " ")
            Opacity(
              opacity: 0.28,
              child: Text(
                hiddenLetterHint,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5A44C4).withOpacity(0.6),
                ),
              ),
            ),

          // Core entered value
          Text(
            _controllers[index].text.toUpperCase(),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            maxLength: 1,
            showCursor: false,
            enableSuggestions: false,
            autocorrect: false,
            style: const TextStyle(color: Colors.transparent),
            decoration: const InputDecoration(
              counterText: "",
              border: InputBorder.none,
              isCollapsed: true,
            ),
            onChanged: (value) {
              setState(() {});

              String enteredWord = _enteredWord();
              String cleanCorrectAnswer = _cleanCorrectAnswer();

              if (enteredWord == cleanCorrectAnswer) {
                _focusNodes[index].unfocus();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                });
              } else if (value.isNotEmpty) {
                int nextIndex = index + 1;
                if (nextIndex < _correctAnswer.length &&
                    _correctAnswer[nextIndex] == " ") {
                  nextIndex++;
                }

                if (nextIndex < _controllers.length) {
                  _focusNodes[nextIndex].requestFocus();
                } else {
                  _focusNodes[index].unfocus();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardImageSlider(List<String> images) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Listener(
              onPointerDown: (_) {
                _isUserTouchingSlider = true;
              },
              onPointerUp: (_) {
                _isUserTouchingSlider = false;
              },
              onPointerCancel: (_) {
                _isUserTouchingSlider = false;
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: images[index],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        memCacheWidth: 1000,
                        fadeInDuration: const Duration(milliseconds: 100),
                        placeholderFadeInDuration: const Duration(
                          milliseconds: 80,
                        ),
                        placeholder: (context, url) {
                          return Shimmer.fromColors(
                            baseColor: Colors.grey.shade200,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.white,
                            ),
                          );
                        },
                        errorWidget: (context, url, error) {
                          return Container(
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.broken_image_rounded,
                              size: 50,
                              color: Colors.redAccent,
                            ),
                          );
                        },
                      );
                    },
                  ),

                  if (images.length > 1)
                    Positioned(
                      bottom: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(images.length, (index) {
                          final bool active = index == _currentImageIndex;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 18 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        }),
                      ),
                    ),

                  if (images.length > 1 && _currentImageIndex > 0)
                    Positioned(
                      left: 12,
                      child: _buildArrowButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),

                  if (images.length > 1)
                    Positioned(
                      right: 12,
                      child: _buildArrowButton(
                        icon: Icons.arrow_forward_ios_rounded,
                        onTap: () {
                          int nextIndex = _currentImageIndex + 1;

                          if (nextIndex >= images.length) {
                            nextIndex = 0;
                          }

                          _pageController.animateToPage(
                            nextIndex,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF5A44C4)),
      ),
    );
  }

  Widget _buildStatusIcon() {
    return const SizedBox(height: 20);
  }

  Widget _buildRemarksCard(String remark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F9F3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2F0E5), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFD4ECD9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology_alt_outlined,
                color: Color(0xFF2E7D32),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "REMARKS",
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    remark.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF2D3142),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesBox(String notes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A3AA4), Color(0xFF6B53E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Notes:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              notes,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    final String enteredWord = _enteredWord();
    final bool isCorrect = enteredWord == _cleanCorrectAnswer();

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: GestureDetector(
        onTap: isCorrect ? _handleNext : _triggerShake,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCorrect
                  ? [const Color(0xFF432EA6), const Color(0xFF6C4EE0)]
                  : [Colors.grey.shade400, Colors.grey.shade500],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              if (isCorrect)
                BoxShadow(
                  color: const Color(0xFF5A44C4).withOpacity(0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Next",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusView({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required String buttonText,
    required VoidCallback onBtnPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 80, color: iconColor),
            ),
            const SizedBox(height: 30),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF432EA6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                onPressed: onBtnPressed,
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoQuestionsFound() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.image_search_rounded,
                size: 55,
                color: Color(0xFF6366F1),
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              'No Questions Available',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'There are currently no questions or images available '
              'for this category.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Please choose another category and continue playing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey.shade500,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: 190,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                label: const Text(
                  'Choose Category',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
