import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/prediction_opposite_provider.dart';
import '../utils/app_colors.dart';

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
    context.read<PredictionOppositeProvider>().loadQuestion(
      widget.level,
      status: status,
    );
  }

  void _resetLocalState() {
    setState(() {
      _isInitialized = false;
      _targetWord = "";
      for (var c in _controllers) c.dispose();
      for (var f in _focusNodes) f.dispose();
      _controllers.clear();
      _focusNodes.clear();
    });
  }

  void _setupGame(Map<String, dynamic> question) {
    if (_isInitialized) return;

    _wordHint = (question['word'] ?? "").toString();
    _targetWord = (question['opposite_word'] ?? "").toString().toUpperCase();

    if (_targetWord.isNotEmpty) {
      String cleanTarget = _targetWord.replaceAll(" ", "");
      for (int i = 0; i < cleanTarget.length; i++) {
        _controllers.add(TextEditingController());
        FocusNode node = FocusNode();

        node.addListener(() {
          if (node.hasFocus) {
            if (_controllers[i].text.isNotEmpty) {
              _controllers[i].clear();
            }
            setState(() {});
          }
        });
        _focusNodes.add(node);
      }

      if (widget.level.toLowerCase() == "intermediate") {
        int hintCount = (cleanTarget.length / 3).ceil();
        List<int> indices = List.generate(cleanTarget.length, (i) => i)
          ..shuffle();
        for (int i = 0; i < hintCount; i++) {
          int targetIdx = indices[i];
          _controllers[targetIdx].text = cleanTarget[targetIdx];
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

  // 🔹 Hides keyboard and clears out entry on error mismatch
  void _clearInputsOnError() {
    FocusManager.instance.primaryFocus?.unfocus();

    for (var controller in _controllers) {
      controller.clear();
    }
    setState(() {});
  }

  void _handleNext() {
    String enteredWord = _controllers.map((c) => c.text.toUpperCase()).join("");
    String cleanTarget = _targetWord.replaceAll(" ", "");

    if (enteredWord != cleanTarget) {
      _triggerShake();
      _clearInputsOnError(); //  Hides keyboard and resets grid input fields
      return;
    }

    FocusScope.of(context).unfocus();
    _fetchNewQuestion();
  }

  void _triggerShake() {
    if (!_shakeController.isAnimating) {
      _shakeController.forward(from: 0.0);
      HapticFeedback.vibrate();
    }
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
    final opp = context.watch<PredictionOppositeProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: opp.isLoading ? _buildShimmerLoading() : _buildBody(opp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: const Color(0xfff16704),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "Antonyms",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.apps, color: Colors.white, size: 28),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBody(PredictionOppositeProvider opp) {
    if (opp.isCompleted) {
      return _buildStatusView(
        title: "Level Completed!",
        message:
            "Outstanding! You have found all the opposite words in this level.",
        icon: Icons.emoji_events_rounded,
        iconColor: Colors.orangeAccent,
        buttonText: "Play Again",
        onBtnPressed: () => _fetchNewQuestion(status: "new"),
      );
    }

    final response = opp.currentResponse;
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

    _setupGame(response['question']);
    if (_targetWord.isEmpty) return const SizedBox.shrink();

    bool isBeginner = widget.level.toLowerCase() == "beginner";

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 36,
                    horizontal: 16,
                  ),
                  child: Column(
                    children: [
                      _buildHintCard(),

                      if (isBeginner) ...[
                        const SizedBox(height: 20),
                        Text(
                          _targetWord.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xfff16704),
                            letterSpacing: 3,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      _buildInputGrid(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildBottomButton(),
      ],
    );
  }

  Widget _buildHintCard() {
    if (_wordHint.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _wordHint.toUpperCase(),
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: Color(0xFF1B1A55),
          letterSpacing: 6,
        ),
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
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: LayoutBuilder(
              builder: (context, constraints) {
                int totalLetters = _targetWord.replaceAll(" ", "").length;

                double spacing = totalLetters > 8 ? 4.0 : 6.0;
                double boxWidth = totalLetters > 8 ? 30.0 : 34.0;
                double boxHeight = boxWidth * 1.35;
                double fontSize = totalLetters > 8 ? 18.0 : 22.0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_targetWord.length, (i) {
                    if (_targetWord[i] == " ") {
                      return const SizedBox(width: 8);
                    }
                    int controllerIdx = _targetWord
                        .substring(0, i)
                        .replaceAll(" ", "")
                        .length;
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                      child: _buildModernInputBox(
                        controllerIdx,
                        boxWidth,
                        boxHeight,
                        fontSize,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernInputBox(
    int index,
    double width,
    double height,
    double fontSize,
  ) {
    Color borderColor = Colors.purple.shade100;
    double borderWidth = 1.0;
    BorderRadius borderRadius = BorderRadius.circular(6);

    String currentText = _controllers[index].text.toUpperCase();
    String cleanTarget = _targetWord.replaceAll(" ", "");

    if (currentText.isNotEmpty) {
      String expectedChar = cleanTarget[index];
      if (currentText == expectedChar) {
        borderColor = Colors.green.shade600;
        borderWidth = 2.0;
        borderRadius = BorderRadius.circular(8);
      } else {
        borderColor = Colors.red.shade600;
        borderWidth = 2.0;
        borderRadius = BorderRadius.circular(8);
      }
    } else if (_focusNodes[index].hasFocus) {
      borderColor = const Color(0xfff16704);
      borderWidth = 1.5;
    }

    // Wrap Box in a KeyboardListener to track backspaces in the middle of typing
    return KeyboardListener(
      focusNode: FocusNode(skipTraversal: true),
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.backspace) {
            // If field is empty and backspace pressed, drop focus backward
            if (_controllers[index].text.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
              _controllers[index - 1].clear();
              setState(() {});
            }
          }
        }
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F2FD),
          borderRadius: borderRadius,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              currentText,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1B1A55),
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
                  // Fallback regular backspace navigation when deleting populated boxes
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

  Widget _buildRemarksCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.shade700,
            child: const Icon(Icons.psychology, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "REMARKS",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                "Synonyms",
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _targetWord.isNotEmpty ? _targetWord : "...",
                style: const TextStyle(color: Colors.black87, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF3FE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade700,
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "FEEDBACK",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Enter here...",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top: 10),
      child: GestureDetector(
        onTap: _handleNext,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xfff16704), Color.fromARGB(255, 249, 116, 22)],
            ),
            borderRadius: BorderRadius.circular(32),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Next  ",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Icon(Icons.arrow_forward, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 70, color: iconColor),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xfff16704),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onBtnPressed,
                  child: Text(
                    buttonText,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
