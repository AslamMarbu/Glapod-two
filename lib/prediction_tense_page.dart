import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/prediction_tense_provider.dart';
import 'widgets.dart/appbar_page.dart';

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
  bool _showAnswer = false; // <-- Tracks toggle state for viewing answer

  bool _isRestartingQuestions = false;

  final Color brandorange = const Color.fromARGB(255, 249, 116, 22);
  final Color deepOrangeText = const Color(0xfff16704);
  final Color lightCardPurple = const Color(0xFFF3F5FC);
  final Color dividerLineColor = const Color(0xFFD6C8F4);

  bool get _isIntermediateOrAdvanced {
    final lvl = widget.level.trim().toLowerCase();
    return lvl == "intermediate" || lvl == "advanced";
  }

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
      _showAnswer = false; // <-- Reset toggle for the next question
      _targetWord = "";
      _v3Hint = "";
      for (var c in _controllers) c.dispose();
      for (var f in _focusNodes) f.dispose();
      _controllers.clear();
      _focusNodes.clear();
    });
  }

  void _setupGame(Map<String, dynamic> question) {
    _isRestartingQuestions = false;

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
      _clearInputs();
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
    FocusScope.of(context).unfocus();
    for (var controller in _controllers) {
      controller.clear();
    }
    setState(() {});
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
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF6F8FE),
      appBar: const CustomAppBar(
        height: 50,
        title: "Past Tense",
        isDashboard: false,
      ),
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
    final response = tense.currentResponse;

    // Never show completed/no-more-questions screen.
    // Automatically restart from the beginning.
    if (tense.isCompleted ||
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

    if (!_isInitialized && response['question'] != null) {
      Future.microtask(() => _setupGame(response['question']));

      return _buildShimmerLoading();
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
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
                      if (widget.level.trim().toLowerCase() == "beginner") ...[
                        const SizedBox(height: 20),
                        Text(
                          _targetWord.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                            color: Color(0xFF43A047),
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
                      // View / Hide Answer Toggle Button for Intermediate & Advanced
                      if (_isIntermediateOrAdvanced) ...[
                        const SizedBox(height: 20),
                        _buildViewAnswerButton(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildV3RowCard(),
                const SizedBox(height: 30),
                _buildBottomGradientAction(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewAnswerButton() {
    return IconButton(
      onPressed: () {
        setState(() {
          _showAnswer = !_showAnswer;
        });
      },
      style: IconButton.styleFrom(
        foregroundColor: brandorange,
        side: BorderSide(color: brandorange.withOpacity(0.4), width: 1.5),
        padding: const EdgeInsets.all(12),
        shape: const CircleBorder(), // Keeps it clean and circular
      ),
      icon: Icon(
        _showAnswer ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size:
            22, // Slightly increased size for a better touch target since text is removed
      ),
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
          letterSpacing: 10,
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
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _buildModernInputBox(controllerIdx, _targetWord[i]),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildModernInputBox(int index, String correctLetter) {
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

    // Determine what text to render inside the stack
    String displayedText = _controllers[index].text.toUpperCase();
    Color textColor = deepOrangeText;

    // If the controller text is empty and toggle is on, show the faded system answer hint
    if (displayedText.isEmpty && _showAnswer && _isIntermediateOrAdvanced) {
      displayedText = correctLetter.toUpperCase();
      textColor = Colors.grey.withOpacity(0.4); // Faded color look
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
              displayedText,
              style: TextStyle(
                fontSize: 16,
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
                if (value.isNotEmpty) {
                  int nextIndex = index + 1;
                  if (nextIndex < _controllers.length) {
                    _focusNodes[nextIndex].requestFocus();
                  } else {
                    _focusNodes[index].unfocus();
                  }
                } else {
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
