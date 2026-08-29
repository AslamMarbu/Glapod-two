import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/prediction_opposite_provider.dart';
import 'widgets.dart/appbar_page.dart';

class PredictionOppositePage extends StatefulWidget {
  final String level;

  const PredictionOppositePage({super.key, required this.level});

  @override
  State<PredictionOppositePage> createState() => _PredictionOppositePageState();
}

class _PredictionOppositePageState extends State<PredictionOppositePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];

  String _targetWord = "";
  String _wordHint = "";

  bool _isInitialized = false;
  bool _showAnswer = false;

  bool _isRestartingQuestions = false;

  bool get _isBeginner => widget.level.toLowerCase() == "beginner";

  bool get _canViewAnswer {
    final level = widget.level.toLowerCase();

    return level == "intermediate" || level == "advanced";
  }

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    Future.microtask(() {
      _fetchNewQuestion();
    });
  }

  void _fetchNewQuestion({String? status}) {
    _resetLocalState();

    context.read<PredictionOppositeProvider>().loadQuestion(
      widget.level,
      status: status,
    );
  }

  void _resetLocalState() {
    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final focus in _focusNodes) {
      focus.dispose();
    }

    _controllers.clear();
    _focusNodes.clear();

    setState(() {
      _isInitialized = false;
      _showAnswer = false;
      _targetWord = "";
      _wordHint = "";
    });
  }

  void _setupGame(Map<String, dynamic> question) {
    _isRestartingQuestions = false;

    if (_isInitialized) return;

    _wordHint = (question['word'] ?? "").toString();

    _targetWord = (question['opposite_word'] ?? "").toString().toUpperCase();

    if (_targetWord.isEmpty) {
      return;
    }

    final String cleanTarget = _targetWord.replaceAll(" ", "");

    for (int i = 0; i < cleanTarget.length; i++) {
      _controllers.add(TextEditingController());

      final FocusNode node = FocusNode();

      node.addListener(() {
        if (!mounted) return;
        setState(() {});
      });

      _focusNodes.add(node);
    }

    /// Intermediate:
    /// prefill around 1/3 of the letters.
    if (widget.level.toLowerCase() == "intermediate") {
      final int hintCount = (cleanTarget.length / 3).ceil();

      final List<int> indices = List.generate(
        cleanTarget.length,
        (index) => index,
      )..shuffle();

      for (int i = 0; i < hintCount; i++) {
        final int targetIndex = indices[i];

        _controllers[targetIndex].text = cleanTarget[targetIndex];
      }
    }

    _isInitialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          _focusFirstEmpty();
        }
      });
    });
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

  bool _isAnswerCorrect() {
    final String enteredWord = _controllers
        .map((controller) => controller.text.trim().toUpperCase())
        .join("");

    final String correctWord = _targetWord
        .replaceAll(" ", "")
        .trim()
        .toUpperCase();

    return correctWord.isNotEmpty && enteredWord == correctWord;
  }

  void _hideKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void _focusNextEmpty(int currentIndex) {
    for (int i = currentIndex + 1; i < _controllers.length; i++) {
      if (_controllers[i].text.isEmpty) {
        _focusNodes[i].requestFocus();
        return;
      }
    }

    // No empty box remains.
    _hideKeyboard();
  }

  void _clearInputsOnError() {
    FocusManager.instance.primaryFocus?.unfocus();

    final String cleanTarget = _targetWord.replaceAll(" ", "");

    for (int i = 0; i < _controllers.length; i++) {
      if (widget.level.toLowerCase() == "intermediate" &&
          _controllers[i].text.isNotEmpty &&
          _controllers[i].text.toUpperCase() == cleanTarget[i]) {
        continue;
      }

      _controllers[i].clear();
    }

    setState(() {});
  }

  void _handleNext() {
    final String enteredWord = _controllers
        .map((controller) => controller.text.toUpperCase())
        .join("");

    final String cleanTarget = _targetWord.replaceAll(" ", "");

    if (enteredWord != cleanTarget) {
      _triggerShake();
      _clearInputsOnError();
      return;
    }

    _hideKeyboard();

    _fetchNewQuestion();
  }

  void _triggerShake() {
    if (!_shakeController.isAnimating) {
      _shakeController.forward(from: 0);

      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();

    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final focus in _focusNodes) {
      focus.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opp = context.watch<PredictionOppositeProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: const CustomAppBar(
        height: 70,
        title: "Antonyms",
        isDashboard: false,
      ),

      body: opp.isLoading ? _buildShimmerLoading() : _buildBody(opp),
    );
  }

  Widget _buildBody(PredictionOppositeProvider opp) {
    final response = opp.currentResponse;

    // When every question is completed,
    // automatically start the level again.
    if (opp.isCompleted ||
        response == null ||
        response['status'].toString() == "false") {
      if (!_isRestartingQuestions) {
        _isRestartingQuestions = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          _fetchNewQuestion(status: "new");
        });
      }

      return _buildShimmerLoading();
    }

    final dynamic rawQuestion = response['question'];

    if (rawQuestion is Map<String, dynamic>) {
      _setupGame(rawQuestion);
    } else if (rawQuestion is Map) {
      _setupGame(Map<String, dynamic>.from(rawQuestion));
    }

    if (_targetWord.isEmpty) {
      return const SizedBox.shrink();
    }

    // KEEP THE REST OF YOUR EXISTING _buildBody CODE HERE

    // Detect keyboard
    final bool keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // Smaller spacing when keyboard is visible
    final double topPadding = keyboardOpen ? 8 : 18;
    final double cardTopPadding = keyboardOpen ? 14 : 22;
    final double cardBottomPadding = keyboardOpen ? 16 : 22;
    final double sectionSpacing = keyboardOpen ? 14 : 22;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(18, topPadding, 18, keyboardOpen ? 12 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // =========================
          // MAIN CARD
          // =========================
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              18,
              cardTopPadding,
              18,
              cardBottomPadding,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFEEF0F5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.055),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // WORD / QUESTION CARD
                _buildHintCard(),

                SizedBox(height: keyboardOpen ? 16 : 24),

                // LETTER BOXES
                _buildInputGrid(),

                // VIEW ANSWER
                if (_canViewAnswer) ...[
                  SizedBox(height: keyboardOpen ? 14 : 20),
                  _buildViewAnswerButton(),
                ],
              ],
            ),
          ),

          // =========================
          // BEGINNER HINT
          // =========================
          if (_isBeginner) ...[
            SizedBox(height: keyboardOpen ? 8 : 12),
            _buildBeginnerAnswer(),
          ],

          SizedBox(height: sectionSpacing),

          // =========================
          // NEXT BUTTON
          // =========================
          _buildNextButton(),

          SizedBox(height: keyboardOpen ? 8 : 16),
        ],
      ),
    );
  }

  Widget _buildHintCard() {
    if (_wordHint.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF6F4FF), Color(0xFFFAF9FF)],
        ),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: const Color(0xFFE6E1FA)),
      ),

      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          _wordHint.toUpperCase(),

          textAlign: TextAlign.center,

          style: TextStyle(
            fontSize: _wordHint.length > 10 ? 24 : 30,

            fontWeight: FontWeight.w900,

            color: const Color(0xFF24205D),

            letterSpacing: _wordHint.length > 10 ? 3 : 5,
          ),
        ),
      ),
    );
  }

  /// Compact beginner hint displayed
  /// BELOW the main white card.
  Widget _buildBeginnerAnswer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FBF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBDEBD0), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: Color(0xFF1DAA61),
            size: 20,
          ),

          const SizedBox(width: 9),

          const Text(
            "Hint:",
            style: TextStyle(
              color: Color(0xFF727A84),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(width: 7),

          Expanded(
            child: Text(
              _targetWord,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF128B4E),
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAnswerButton() {
    return TextButton.icon(
      onPressed: () {
        setState(() {
          _showAnswer = !_showAnswer;
        });
      },
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFF16704),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFFFCAA4)),
        ),
      ),
      icon: Icon(
        _showAnswer ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
      ),
      label: Text(
        _showAnswer ? "Hide Answer" : "View Answer",
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildInputGrid() {
    return AnimatedBuilder(
      animation: _shakeController,

      builder: (context, child) {
        final double offset = _shakeController.isAnimating
            ? (0.5 - (0.5 - _shakeController.value).abs()) * 15
            : 0;

        return Transform.translate(offset: Offset(offset, 0), child: child);
      },

      child: LayoutBuilder(
        builder: (context, constraints) {
          final int totalLetters = _targetWord.replaceAll(" ", "").length;

          double spacing;
          double boxWidth;
          double boxHeight;
          double fontSize;

          /// Automatically shrink
          /// letter boxes for long words.
          if (totalLetters <= 5) {
            spacing = 7;
            boxWidth = 42;
            boxHeight = 54;
            fontSize = 22;
          } else if (totalLetters <= 7) {
            spacing = 6;
            boxWidth = 38;
            boxHeight = 50;
            fontSize = 21;
          } else if (totalLetters <= 9) {
            spacing = 5;
            boxWidth = 34;
            boxHeight = 46;
            fontSize = 19;
          } else if (totalLetters <= 11) {
            spacing = 4;
            boxWidth = 30;
            boxHeight = 42;
            fontSize = 17;
          } else if (totalLetters <= 13) {
            spacing = 3;
            boxWidth = 27;
            boxHeight = 39;
            fontSize = 16;
          } else {
            spacing = 2;
            boxWidth = 24;
            boxHeight = 36;
            fontSize = 14;
          }

          return SizedBox(
            width: double.infinity,

            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,

              child: Row(
                mainAxisSize: MainAxisSize.min,

                mainAxisAlignment: MainAxisAlignment.center,

                children: List.generate(_targetWord.length, (i) {
                  if (_targetWord[i] == " ") {
                    return SizedBox(width: totalLetters > 10 ? 5 : 10);
                  }

                  final int controllerIndex = _targetWord
                      .substring(0, i)
                      .replaceAll(" ", "")
                      .length;

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: spacing / 2),

                    child: _buildModernInputBox(
                      controllerIndex,
                      boxWidth,
                      boxHeight,
                      fontSize,
                    ),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernInputBox(
    int index,
    double width,
    double height,
    double fontSize,
  ) {
    final String currentText = _controllers[index].text.toUpperCase();

    final String cleanTarget = _targetWord.replaceAll(" ", "");

    final String expectedChar = cleanTarget[index];

    final bool hasText = currentText.isNotEmpty;

    final bool isCorrect = hasText && currentText == expectedChar;

    final bool isFocused = _focusNodes[index].hasFocus;

    Color borderColor = const Color(0xFFE1DDF3);

    double borderWidth = 1.2;

    if (hasText) {
      borderColor = isCorrect
          ? const Color(0xFF24B76A)
          : const Color(0xFFE94B4B);

      borderWidth = 1.8;
    } else if (isFocused) {
      borderColor = const Color(0xFFF16704);

      borderWidth = 1.8;
    }

    String displayedText = currentText;

    Color textColor = const Color(0xFF24205D);

    if (!hasText && _showAnswer) {
      displayedText = expectedChar;

      textColor = const Color(0xFF24205D).withOpacity(0.22);
    }

    return KeyboardListener(
      focusNode: FocusNode(skipTraversal: true),

      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_controllers[index].text.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();

              _controllers[index - 1].clear();

              setState(() {});
            }
          }
        }
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),

        width: width,
        height: height,

        decoration: BoxDecoration(
          color: hasText && isCorrect
              ? const Color(0xFFF1FBF5)
              : const Color(0xFFF8F7FC),

          borderRadius: BorderRadius.circular(10),

          border: Border.all(color: borderColor, width: borderWidth),

          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: const Color(0xFFF16704).withOpacity(0.10),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),

        child: Stack(
          alignment: Alignment.center,

          children: [
            Text(
              displayedText,

              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
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

              textCapitalization: TextCapitalization.characters,

              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
              ],

              style: const TextStyle(color: Colors.transparent),

              decoration: const InputDecoration(
                counterText: "",
                border: InputBorder.none,
                isCollapsed: true,
              ),

              onChanged: (value) {
                setState(() {});

                if (value.isNotEmpty) {
                  // As soon as the complete answer is correct,
                  // close the keyboard automatically.
                  if (_isAnswerCorrect()) {
                    _hideKeyboard();
                    HapticFeedback.lightImpact();
                    return;
                  }

                  // Go to the next empty letter box.
                  // This also skips the pre-filled Intermediate letters.
                  _focusNextEmpty(index);
                } else if (index > 0) {
                  _focusNodes[index - 1].requestFocus();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return GestureDetector(
      onTap: _handleNext,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF16704), Color(0xFFFF7D1D)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF16704).withOpacity(0.20),
              blurRadius: 12,
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
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 21),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,

      highlightColor: Colors.grey.shade100,

      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),

        child: Column(
          children: [
            Container(
              height: 260,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
            ),

            const SizedBox(height: 14),

            Container(
              height: 42,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),

            const SizedBox(height: 18),

            Container(
              height: 58,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ],
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),

        child: Container(
          width: double.infinity,

          padding: const EdgeInsets.all(26),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(26),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Container(
                width: 84,
                height: 84,

                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),

                child: Icon(icon, size: 46, color: iconColor),
              ),

              const SizedBox(height: 20),

              Text(
                title,

                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF202124),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                message,

                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF7B8190),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,

                child: ElevatedButton(
                  onPressed: onBtnPressed,

                  style: ElevatedButton.styleFrom(
                    elevation: 0,

                    backgroundColor: const Color(0xFFF16704),

                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  child: Text(
                    buttonText,

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
      ),
    );
  }
}
