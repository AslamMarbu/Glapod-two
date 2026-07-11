import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/prediction_tense_provider.dart';
import '../utils/app_colors.dart';

class PredictionTensePage extends StatefulWidget {
  final String level;
  const PredictionTensePage({super.key, required this.level});

  @override
  State<PredictionTensePage> createState() => _PredictionTensePageState();
}

class _PredictionTensePageState extends State<PredictionTensePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];

  String _targetWord = "";
  String _presentHint = "";
  String _v3Hint = "";
  bool _isInitialized = false;

  final Color brandorange = const Color.fromARGB(255, 249, 116, 22);
  final Color deepOrangeText = const Color(0xfff16704);
  final Color lightCardPurple = const Color(0xFFF3F5FC);
  final Color dividerLineColor = const Color(0xFFD6C8F4);

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    Future.microtask(() => _fetchNewQuestion());
  }

  void _fetchNewQuestion({String? status}) {
    _resetLocalState();
    context.read<PredictionTenseProvider>().loadQuestion(
      widget.level,
      status: status,
    );
  }

  void _resetLocalState() {
    setState(() {
      _isInitialized = false;
      _targetWord = "";
      _v3Hint = "";
      for (var c in _controllers) c.dispose();
      for (var f in _focusNodes) f.dispose();
      _controllers.clear();
      _focusNodes.clear();
    });
  }

  void _setupGame(Map<String, dynamic> question) {
    final newTarget = (question['past'] ?? "").toString().toUpperCase();

    setState(() {
      _presentHint = (question['present'] ?? "").toString();
      _targetWord = newTarget;
      _v3Hint = (question['future'] ?? question['past_participle'] ?? "---")
          .toString();

      for (var c in _controllers) c.dispose();
      for (var f in _focusNodes) f.dispose();
      _controllers.clear();
      _focusNodes.clear();

      String cleanTarget = _targetWord.replaceAll(" ", "");
      for (int i = 0; i < cleanTarget.length; i++) {
        _controllers.add(TextEditingController());
        _focusNodes.add(FocusNode());
      }

      if (widget.level.trim().toLowerCase() == "intermediate") {
        int hintCount = (cleanTarget.length / 3).ceil();
        List<int> indices = List.generate(cleanTarget.length, (i) => i)
          ..shuffle();
        for (int i = 0; i < hintCount; i++) {
          int targetIdx = indices[i];
          _controllers[targetIdx].text = cleanTarget[targetIdx];
        }
      }
      _isInitialized = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _focusFirstEmpty();
      });
    });
  }

  void _focusFirstEmpty() {
    for (int i = 0; i < _controllers.length; i++) {
      if (_controllers[i].text.isEmpty) {
        _focusNodes[i].requestFocus();
        break;
      }
    }
  }

  void _handleNext() {
    String enteredWord = _controllers.map((c) => c.text.toUpperCase()).join("");
    if (enteredWord != _targetWord.replaceAll(" ", "")) {
      _triggerShake();
      _clearInputs(); // <-- Automatically clears fields and hides the keyboard on error
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
    // 1. Dismiss the keyboard
    FocusScope.of(context).unfocus();

    // 2. Clear all text controllers
    for (var controller in _controllers) {
      controller.clear();
    }

    setState(() {});

    // Note: If you want the keyboard to STAY down, do NOT call _focusFirstEmpty() here,
    // because requesting focus on a text field will bring the keyboard right back up.
    // _focusFirstEmpty();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tense = context.watch<PredictionTenseProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: true, // Ensures layout adjusts for keyboard
      backgroundColor: const Color(0xFFF6F8FE),
      body: tense.isLoading ? _buildShimmerLoading() : _buildBody(tense),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(height: 140, color: Colors.white),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(PredictionTenseProvider tense) {
    if (tense.isCompleted) {
      return _buildStatusView(
        title: "Level Mastered!",
        message: "Fantastic! Level completed.",
        icon: Icons.auto_awesome,
        iconColor: Colors.amber,
        buttonText: "Play Again",
        onBtnPressed: () => _fetchNewQuestion(status: "new"),
      );
    }

    final response = tense.currentResponse;
    if (response == null || response['status'].toString() == "false") {
      return _buildStatusView(
        title: "Sorry!",
        message: response?['message'] ?? "No more questions.",
        icon: Icons.info_outline,
        iconColor: Colors.blue,
        buttonText: "Go Back",
        onBtnPressed: () => Navigator.pop(context),
      );
    }

    if (!_isInitialized && response['question'] != null) {
      Future.microtask(() => _setupGame(response['question']));
      return _buildShimmerLoading();
    }

    return Column(
      children: [
        // Top Header
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [brandorange, brandorange.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            bottom: 35,
            left: 20,
            right: 20,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                "Past tense",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),

        // Main Content Area
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: SingleChildScrollView(
              // Extra bottom padding ensures scrolling space above the keyboard
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 30 : 10,
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSectionHeader("Base Form [V1]"),
                        const SizedBox(height: 14),
                        _buildV1Card(),

                        if (widget.level.trim().toLowerCase() ==
                            "beginner") ...[
                          const SizedBox(height: 20),
                          Text(
                            _targetWord.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              color: deepOrangeText,
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),
                        _buildSectionHeader("Simple Past [V2]"),
                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: _buildInputGrid(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildV3RowCard(),

                  // By inserting the button into the scroll view, it flows naturally
                  // and stops overlapping your V2 boxes.
                  const SizedBox(height: 30),
                  _buildBottomGradientAction(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String headingTitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 20, height: 1.5, color: dividerLineColor),
        const SizedBox(width: 6),
        Icon(
          Icons.diamond_outlined,
          size: 10,
          color: brandorange.withOpacity(0.5),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            headingTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3AA64C),
            ),
          ),
        ),
        Icon(
          Icons.diamond_outlined,
          size: 10,
          color: brandorange.withOpacity(0.5),
        ),
        const SizedBox(width: 6),
        Container(width: 20, height: 1.5, color: dividerLineColor),
      ],
    );
  }

  Widget _buildV1Card() {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
      decoration: BoxDecoration(
        color: lightCardPurple,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        _presentHint.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: deepOrangeText,
          letterSpacing: 10, // Natural internal system letterspacing
        ),
      ),
    );
  }

  Widget _buildV3RowCard() {
    String enteredWord = _controllers.map((c) => c.text.toUpperCase()).join("");
    String cleanTarget = _targetWord.replaceAll(" ", "");
    bool isCorrect = enteredWord == cleanTarget && cleanTarget.isNotEmpty;
    bool isBeginner = widget.level.trim().toLowerCase() == "beginner";

    if (!isBeginner && !isCorrect) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8F1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4EED9), width: 1.5),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFFD8F2DE),
            child: Icon(
              Icons.psychology_outlined,
              color: Color(0xFF2E8A42),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Past Participle [V3]:",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E8A42),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _v3Hint.toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: deepOrangeText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackRowCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDBE4FF), width: 1.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFFDCE4FF),
            child: Icon(Icons.chat_bubble, color: brandorange, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "FEEDBACK",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: brandorange,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Enter here...",
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputGrid() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        double offset = _shakeController.isAnimating
            ? (0.5 - (0.5 - _shakeController.value).abs()) * 15
            : 0.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_targetWord.length, (i) {
              if (_targetWord[i] == " ") return const SizedBox(width: 6);
              int controllerIdx = _targetWord
                  .substring(0, i)
                  .replaceAll(" ", "")
                  .length;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 3,
                ), // Reduced horizontal gaps
                child: _buildModernInputBox(controllerIdx),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildModernInputBox(int index) {
    bool hasFocus = _focusNodes[index].hasFocus;

    String enteredWord = _controllers.map((c) => c.text.toUpperCase()).join("");
    String correctWord = _targetWord.replaceAll(" ", "");

    bool isCompleted = enteredWord.length == correctWord.length;
    bool isCorrect = enteredWord == correctWord;

    Color borderColor;
    if (isCompleted) {
      borderColor = isCorrect ? Colors.green : Colors.red;
    } else {
      borderColor = hasFocus ? brandorange : const Color(0xFFD6DCED);
    }

    // Wrap with KeyboardListener to detect Backspace on empty boxes
    return KeyboardListener(
      focusNode: FocusNode(
        skipTraversal: true,
      ), // Internal node just for listening
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.backspace) {
            // If current box is empty and backspace is pressed, go to previous box
            if (_controllers[index].text.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
              _controllers[index - 1]
                  .clear(); // Optional: clears previous box too
              setState(() {});
            }
          }
        }
      },
      child: Container(
        width: 32,
        height: 44,
        decoration: BoxDecoration(
          color: lightCardPurple,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isCompleted ? 2.2 : (hasFocus ? 1.8 : 1.2),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              _controllers[index].text.toUpperCase(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: deepOrangeText,
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
                if (value.isNotEmpty) {
                  int nextIndex = index + 1;
                  if (nextIndex < _controllers.length) {
                    _focusNodes[nextIndex].requestFocus();
                  } else {
                    _focusNodes[index].unfocus();
                  }
                } else {
                  // Regular backspace when box HAS text handles moving back here
                  if (index > 0) {
                    _focusNodes[index - 1].requestFocus();
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomGradientAction() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [brandorange, const Color.fromARGB(255, 239, 125, 45)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: brandorange.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _handleNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
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
                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
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
            Icon(icon, size: 80, color: iconColor),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: onBtnPressed,
              style: ElevatedButton.styleFrom(backgroundColor: brandorange),
              child: Text(
                buttonText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
