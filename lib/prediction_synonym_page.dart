import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/prediction_synonym_provider.dart';
import 'widgets.dart/appbar_page.dart';

class PredictionSynonymPage extends StatefulWidget {
  final String level;

  const PredictionSynonymPage({super.key, required this.level});

  @override
  State<PredictionSynonymPage> createState() => _PredictionSynonymPageState();
}

class _PredictionSynonymPageState extends State<PredictionSynonymPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  List<TextEditingController> _controllers = [];
  List<FocusNode> _focusNodes = [];

  String _targetWord = "";
  String _wordHint = "";

  Set<int> _hintIndexes = {};

  bool _isInitialized = false;
  bool _showAnswer = false;
  bool _isRestartingQuestions = false;
  bool _hasRequestedQuestion = false;

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
    _hasRequestedQuestion = true;

    _resetLocalState();

    context.read<PredictionSynonymProvider>().loadQuestion(
      widget.level,
      status: status,
    );
  }

  void _resetLocalState() {
    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final node in _focusNodes) {
      node.dispose();
    }

    _controllers = [];
    _focusNodes = [];

    setState(() {
      _isInitialized = false;
      _showAnswer = false;
      _targetWord = "";
      _wordHint = "";
    });
  }

  void _setupGame(Map<String, dynamic> question) {
    if (_isInitialized) return;

    _wordHint = question['word']?.toString() ?? "";
    _targetWord = question['synonym_word']?.toString().toUpperCase() ?? "";

    final cleanWord = _targetWord.replaceAll(' ', '');

    _controllers = List.generate(
      cleanWord.length,
      (_) => TextEditingController(),
    );

    _focusNodes = List.generate(cleanWord.length, (_) => FocusNode());

    // Clear previous hints.
    _hintIndexes = {};

    // Intermediate level:
    // Store hint positions separately.
    if (widget.level.toLowerCase() == "intermediate" && cleanWord.isNotEmpty) {
      final revealCount = (cleanWord.length / 3).ceil();

      final indexes = List.generate(cleanWord.length, (index) => index)
        ..shuffle();

      _hintIndexes = indexes.take(revealCount).toSet();
    }

    _isInitialized = true;

    // Always start from the FIRST box.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _focusFirstEmpty() {
    for (int i = 0; i < _controllers.length; i++) {
      if (_controllers[i].text.isEmpty) {
        _focusNodes[i].requestFocus();
        return;
      }
    }

    if (_focusNodes.isNotEmpty) {
      _focusNodes.last.requestFocus();
    }
  }

  bool _isAnswerCorrect() {
    final entered = _controllers
        .map((controller) => controller.text)
        .join()
        .replaceAll(' ', '')
        .toUpperCase();

    return entered == _targetWord.replaceAll(' ', '').toUpperCase();
  }

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _focusNextEmpty(int currentIndex) {
    for (int i = currentIndex + 1; i < _controllers.length; i++) {
      if (_controllers[i].text.isEmpty) {
        _focusNodes[i].requestFocus();
        return;
      }
    }

    _hideKeyboard();
  }

  void _clearInputsOnError() {
    for (final controller in _controllers) {
      controller.clear();
    }

    _showAnswer = false;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _focusFirstEmpty();
      }
    });
  }

  void _handleNext() {
    if (!_isInitialized) return;

    if (_isAnswerCorrect()) {
      _hideKeyboard();

      _fetchNewQuestion();
    } else {
      _triggerShake();

      _clearInputsOnError();
    }
  }

  void _triggerShake() {
    _shakeController.forward(from: 0);
  }

  @override
  void dispose() {
    _shakeController.dispose();

    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final node in _focusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final synonym = context.watch<PredictionSynonymProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: const CustomAppBar(
        height: 70,
        title: "Synonyms",
        isDashboard: false,
      ),
      body: _buildBody(synonym),
    );
  }

  Widget _buildBody(PredictionSynonymProvider synonym) {
    final response = synonym.currentResponse;

    // Show shimmer during the initial API request.
    if (!_hasRequestedQuestion || synonym.isLoading) {
      return _buildShimmerLoading();
    }

    // Keep the existing Synonyms completion/error handling._buildModernInputBox
    // Keep the existing Synonyms completion/error handling.
    if (synonym.isCompleted) {
      if (!_isRestartingQuestions) {
        _isRestartingQuestions = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          _isRestartingQuestions = false;
          _fetchNewQuestion(status: "new");
        });
      }

      return _buildShimmerLoading();
    }

    if (response == null) {
      return _buildStatusView("Unable to load question.");
    }

    if (response['status'] != true) {
      return _buildStatusView(
        response['message']?.toString() ?? "Unable to load question.",
      );
    }

    final question = response['question'];

    if (question == null) {
      return _buildStatusView("Question not available.");
    }

    _setupGame(Map<String, dynamic>.from(question));

    if (_targetWord.isEmpty) {
      return _buildStatusView("Question not available.");
    }

    // Same visual layout as the Antonyms page.
    final bool keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

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
                _buildHintCard(),

                SizedBox(height: keyboardOpen ? 16 : 24),

                _buildInputGrid(),

                if (_canViewAnswer) ...[
                  SizedBox(height: keyboardOpen ? 14 : 20),
                  _buildViewAnswerButton(),
                ],
              ],
            ),
          ),

          if (_isBeginner) ...[
            SizedBox(height: keyboardOpen ? 8 : 12),
            _buildBeginnerAnswer(),
          ],

          SizedBox(height: sectionSpacing),

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
    if (_controllers.isEmpty) {
      return const SizedBox.shrink();
    }

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

          if (totalLetters <= 5) {
            spacing = 7;
            boxWidth = 42;
          } else if (totalLetters <= 7) {
            spacing = 6;
            boxWidth = 38;
          } else if (totalLetters <= 9) {
            spacing = 5;
            boxWidth = 34;
          } else if (totalLetters <= 11) {
            spacing = 4;
            boxWidth = 30;
          } else if (totalLetters <= 13) {
            spacing = 3;
            boxWidth = 27;
          } else {
            spacing = 2;
            boxWidth = 24;
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
                    child: _buildModernInputBox(controllerIndex, boxWidth),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernInputBox(int index, double boxSize) {
    final String currentText = _controllers[index].text.toUpperCase();
    final String cleanTarget = _targetWord.replaceAll(" ", "");
    final String expectedChar = cleanTarget[index];

    final bool hasText = currentText.isNotEmpty;
    final bool isCorrect = hasText && currentText == expectedChar;
    final bool isFocused = _focusNodes[index].hasFocus;
    final bool isHint = _hintIndexes.contains(index);

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

    if (!hasText && isHint) {
      displayedText = expectedChar;
      textColor = const Color(0xFF24205D).withOpacity(0.45);
    }

    if (!hasText && _showAnswer) {
      displayedText = expectedChar;
      textColor = const Color(0xFF24205D).withOpacity(0.22);
    }

    return SizedBox(
      width: boxSize,
      height: boxSize + 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ------------------------------------------------
          // VISUAL LETTER BOX
          // ------------------------------------------------
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: boxSize,
            height: boxSize + 8,
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
            child: Center(
              child: Text(
                displayedText,
                style: TextStyle(
                  fontSize: boxSize > 40 ? 22 : 18,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ),
          ),

          // ------------------------------------------------
          // KEYBOARD INPUT
          // ------------------------------------------------
          Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace) {
                // ------------------------------------------
                // CASE 1:
                // Current box has a letter.
                //
                // Let TextField delete the current letter.
                // ------------------------------------------
                if (_controllers[index].text.isNotEmpty) {
                  return KeyEventResult.ignored;
                }

                // ------------------------------------------
                // CASE 2:
                // Current box is empty.
                //
                // Move to previous box and delete its letter.
                // ------------------------------------------
                if (index > 0) {
                  _controllers[index - 1].clear();

                  _focusNodes[index - 1].requestFocus();

                  setState(() {});

                  return KeyEventResult.handled;
                }

                return KeyEventResult.handled;
              }

              return KeyEventResult.ignored;
            },

            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              maxLength: 1,
              enabled: !_showAnswer,
              showCursor: false,
              enableSuggestions: false,
              autocorrect: false,

              // Hide the real TextField text.
              // We display it using the Text widget above.
              style: const TextStyle(color: Colors.transparent),

              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
              ],

              decoration: const InputDecoration(
                counterText: "",
                border: InputBorder.none,
                isCollapsed: true,
              ),

              // ------------------------------------------------
              // WHEN USER TYPES A LETTER
              // ------------------------------------------------
              onChanged: (value) {
                if (value.isNotEmpty) {
                  // Keep only one character.
                  if (value.length > 1) {
                    _controllers[index].text = value.substring(
                      value.length - 1,
                    );

                    _controllers[index].selection =
                        const TextSelection.collapsed(offset: 1);
                  }

                  setState(() {});

                  // ------------------------------------------
                  // Automatically move to next box.
                  // ------------------------------------------
                  if (index < _controllers.length - 1) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;

                      final nextIndex = index + 1;

                      if (_controllers[nextIndex].text.isEmpty) {
                        _focusNodes[nextIndex].requestFocus();
                      }
                    });
                  }
                } else {
                  setState(() {});
                }
              },

              // ------------------------------------------------
              // TAP
              // ------------------------------------------------
              onTap: () {
                if (_showAnswer) {
                  _hideKeyboard();
                }
              },

              // ------------------------------------------------
              // ENTER / SUBMIT
              // ------------------------------------------------
              onSubmitted: (_) {
                _focusNextEmpty(index);
              },
            ),
          ),
        ],
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

  Widget _buildStatusView(String message) {
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
                  color: const Color(0xFFF16704).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 46,
                  color: Color(0xFFF16704),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Unable to Load",
                textAlign: TextAlign.center,
                style: TextStyle(
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
                  onPressed: _fetchNewQuestion,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFFF16704),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Retry",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
