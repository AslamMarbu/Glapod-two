import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/prediction_name_provider.dart';
import '../services/student_service.dart';
import '../utils/app_colors.dart';
import 'prediction_name_grid_page.dart';

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

  final TextEditingController _feedbackController = TextEditingController();
  final int _maxFeedbackLength = 300;
  String? _feedbackError;

  int _currentImageIndex = 0;
  String _correctAnswer = "";
  dynamic _currentQuestionId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pageController = PageController();
    _scrollController = ScrollController();
    Future.microtask(() => _fetchNewQuestion());
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
    setState(() {
      _isInitialized = false;
      _currentImageIndex = 0;
      _feedbackController.clear();
      if (_pageController.hasClients) _pageController.jumpToPage(0);
      for (var c in _controllers) c.dispose();
      for (var f in _focusNodes) f.dispose();
      _controllers.clear();
      _focusNodes.clear();
    });
  }

  void _setupGame(Map<String, dynamic> questionData) {
    _currentQuestionId = questionData['id'];

    String rawValue = (questionData['answer'] ?? questionData['name'] ?? "")
        .toString();
    _correctAnswer = rawValue.toUpperCase();

    if (_feedbackController.text.isEmpty && questionData['feedback'] != null) {
      _feedbackController.text = questionData['feedback'].toString();
    }

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
    String enteredWord = _controllers.map((c) => c.text.toUpperCase()).join("");
    if (enteredWord != _correctAnswer.replaceAll(" ", "")) {
      _triggerShake();
      return;
    }

    if (_feedbackController.text.trim().isNotEmpty) {
      await StudentService.submitGuessNameFeedback(
        guessNameId: _currentQuestionId.toString(),
        feedback: _feedbackController.text.trim(),
      );
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
    _shakeController.dispose();
    _pageController.dispose();
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    _scrollController.dispose();
    _feedbackController.dispose();
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF231E70), Color(0xFF38238C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    widget.categoryName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.grid_view_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() => _isInitialized = false);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (routeContext) => PredictionNameGridPage(
                              categoryName: widget.categoryName,
                              categoryId: widget.categoryId,
                              level: widget.level,
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
        ),
      ),
      body: game.isLoading ? _buildShimmerLoading() : _buildGameContent(game),
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
    if (game.isCompleted) {
      return _buildStatusView(
        title: "Level Completed!",
        message: "Outstanding! You have found all the words in this level.",
        icon: Icons.emoji_events_rounded,
        iconColor: Colors.orangeAccent,
        buttonText: "Play Again",
        onBtnPressed: () => _fetchNewQuestion(status: "new"),
      );
    }

    final response = game.currentResponse;
    if (response == null || response['status'].toString() == "false") {
      return _buildStatusView(
        title: "No More Questions",
        message:
            response?['message'] ??
            "You've caught up with all questions for now!",
        icon: Icons.check_circle_outline_rounded,
        iconColor: Colors.green,
        buttonText: "Go Back",
        onBtnPressed: () => Navigator.pop(context),
      );
    }

    if (_correctAnswer.isEmpty) return const SizedBox.shrink();

    final images = List<String>.from(response['question']['images'] ?? []);
    print("Images: $images");
    final dynamicNotes =
        response['question']['notes'] ??
        response['question']['description'] ??
        "No notes available.";
    final dynamicRemarks = response['question']['remarks'] ?? "GENERAL";

    String enteredWord = _controllers.map((c) => c.text.toUpperCase()).join("");
    bool isCorrect = enteredWord == _correctAnswer.replaceAll(" ", "");

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const SizedBox(height: 16),
                if (images.isNotEmpty) _buildCardImageSlider(images),

                // Decorative Middle Visual Badge
                Transform.translate(
                  offset: const Offset(0, -18),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.visibility_outlined,
                      color: Color(0xFF5A44C4),
                      size: 28,
                    ),
                  ),
                ),

                // Center Decorated Word Category/Title Title Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 25,
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _correctAnswer,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Color(0xFF322881),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 25,
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildInputGrid(),
                const SizedBox(height: 15),
                _buildStatusIcon(),
                const SizedBox(height: 15),
                _buildRemarksCard(dynamicRemarks),
                const SizedBox(height: 16),

                if (isCorrect) ...[
                  _buildNotesBox(dynamicNotes),
                  const SizedBox(height: 16),
                ],

                _buildFeedbackCard(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
        _buildBottomButton(),
      ],
    );
  }

  Widget _buildInputGrid() {
    String targetPhrase = _correctAnswer.toUpperCase();

    // 1. Group letter indices cleanly by word boundaries to preserve exact global controller tracking
    List<List<int>> wordIndices = [];
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

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        double offset = _shakeController.isAnimating
            ? (0.5 - (0.5 - _shakeController.value).abs()) * 15
            : 0.0;

        return Transform.translate(
          offset: Offset(offset, 0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 16, // 🔹 Natural spacing between distinct words
              runSpacing:
                  12, // 🔹 Vertical gap when an entire word wraps downward
              alignment: WrapAlignment.center,
              children: wordIndices.map((indices) {
                return Wrap(
                  spacing:
                      4, // 🔹 Fine-tuned internal spacing between individual letters
                  children: indices
                      .map((index) => _buildModernInputBox(index))
                      .toList(),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernInputBox(int index) {
    bool hasFocus = _focusNodes[index].hasFocus;
    bool hasText = _controllers[index].text.isNotEmpty;

    // 1. Calculate validation states
    String enteredWord = _controllers.map((c) => c.text.toUpperCase()).join("");
    String cleanCorrectAnswer = _correctAnswer.replaceAll(" ", "");

    // Only validate colors if the user has filled out all the letters
    bool isWordComplete = enteredWord.length == cleanCorrectAnswer.length;
    bool isCorrect = enteredWord == cleanCorrectAnswer;

    // 2. Dynamic Colors based on your requirements
    Color boxBgColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    double borderWidth = 1.2;
    Color textColor = const Color(0xFF322881);

    if (isWordComplete) {
      if (isCorrect) {
        boxBgColor = const Color(0xFFE8F5E9); // Light green highlight
        borderColor = Colors.green.shade600; // Green border
        borderWidth = 2.0;
        textColor = Colors.green.shade900;
      } else {
        boxBgColor = const Color(0xFFFFEBEE); // Light red highlight
        borderColor = Colors.red.shade600; // Red border
        borderWidth = 2.0;
        textColor = Colors.red.shade900;
      }
    } else if (hasText || hasFocus) {
      boxBgColor = const Color(0xFFF2EFFF); // Purple tint when typing
      if (hasFocus) {
        borderColor = const Color(0xFF5A44C4); // Active purple border
        borderWidth = 2.0;
      }
    }

    return Container(
      width: 38,
      height: 50,
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
          Text(
            _controllers[index].text.toUpperCase(),
            style: TextStyle(
              fontSize: 18,
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

              // 🔹 Check if the entire word is now correct
              String enteredWord = _controllers
                  .map((c) => c.text.toUpperCase())
                  .join("");
              String cleanCorrectAnswer = _correctAnswer.replaceAll(" ", "");

              if (enteredWord == cleanCorrectAnswer) {
                // Unfocus everything to drop the keyboard out of the way smoothly
                _focusNodes[index].unfocus();

                // Animate down to the bottom of the viewport
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
                // Normal auto-focus hopping logic
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
    double screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: screenWidth * 0.6,
        width: screenWidth,
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (index) =>
                    setState(() => _currentImageIndex = index),
                itemBuilder: (context, index) => Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  width: screenWidth,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print("Image Error: $error");
                    print("Image URL: ${images[index]}");

                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 60,
                          color: Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_currentImageIndex > 0)
                Positioned(
                  left: 12,
                  child: _buildArrowButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
              if (_currentImageIndex < images.length - 1)
                Positioned(
                  right: 12,
                  child: _buildArrowButton(
                    icon: Icons.arrow_forward_ios_rounded,
                    onTap: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
            ],
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
    // Clear out the icon layout entirely and leave a clean layout gap
    // so your boxes don't flush tightly against the cards below them.
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

  Widget _buildFeedbackCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _feedbackError != null
                ? Colors.red
                : const Color(0xFFE6EAF5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFE2E7F7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFF3F51B5),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "FEEDBACK",
                    style: TextStyle(
                      color: Color(0xFF5A67BA),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextField(
                    controller: _feedbackController,
                    maxLength: _maxFeedbackLength,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Enter here...",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      counterText: "",
                      isCollapsed: true,
                    ),
                    onChanged: (value) => setState(
                      () => _feedbackError = value.length > _maxFeedbackLength
                          ? "Limit reached"
                          : null,
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
    String enteredWord = _controllers.map((c) => c.text.toUpperCase()).join("");
    bool isCorrect = enteredWord == _correctAnswer.replaceAll(" ", "");
    return Padding(
      padding: const EdgeInsets.only(bottom: 30, left: 35, right: 35),
      child: Center(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: GestureDetector(
            onTap: _handleNext,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCorrect
                      ? [const Color(0xFF432EA6), const Color(0xFF6C4EE0)]
                      : [Colors.grey.shade400, Colors.grey.shade500],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isCorrect
                                ? const Color(0xFF5A44C4)
                                : Colors.transparent)
                            .withOpacity(0.3),
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
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
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
}
