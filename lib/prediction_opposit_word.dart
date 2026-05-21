import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart'; // Ensure this is in pubspec.yaml
import '../providers/prediction_opposite_provider.dart';
import '../utils/app_colors.dart';
import 'widgets.dart/appbar_page.dart';

class PredictionOppositePage extends StatefulWidget {
  final String level;
  const PredictionOppositePage({super.key, required this.level});

  @override
  State<PredictionOppositePage> createState() => _PredictionOppositePageState();
}

class _PredictionOppositePageState extends State<PredictionOppositePage> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];

  String _targetWord = "";
  String _wordHint = "";
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    Future.microtask(() => _fetchNewQuestion());
  }

  void _fetchNewQuestion({String? status}) {
    _resetLocalState();
    context.read<PredictionOppositeProvider>().loadQuestion(widget.level, status: status);
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
        List<int> indices = List.generate(cleanTarget.length, (i) => i)..shuffle();
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

  void _handleNext() {
    String enteredWord = _controllers.map((c) => c.text.toUpperCase()).join("");
    if (enteredWord != _targetWord.replaceAll(" ", "")) {
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
    for (var controller in _controllers) {
      controller.clear();
    }
    setState(() {});
    _focusFirstEmpty();
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
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: const CustomAppBar(height: 60, title: "Antonyms", isDashboard: false),
      // 🔹 Shimmer is called here without changing the rest of the file
      body: opp.isLoading
          ? _buildShimmerLoading()
          : _buildBody(opp),
    );
  }

  // 🔹 ADDED: Shimmer skeleton that matches your UI proportions
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 200,
                height: 70,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              ),
            ),
            const SizedBox(height: 70),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 5,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: List.generate(6, (index) => Container(
                  width: 32,
                  height: 45,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                )),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 65,
              height: 65,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(PredictionOppositeProvider opp) {
    if (opp.isCompleted) {
      return _buildStatusView(
        title: "Level Completed!",
        message: "Outstanding! You have found all the opposite words in this level.",
        icon: Icons.emoji_events_rounded, iconColor: Colors.orangeAccent, buttonText: "Play Again",
        onBtnPressed: () => _fetchNewQuestion(status: "new"),
      );
    }

    final response = opp.currentResponse;
    if (response == null || response['status'].toString() == "false") {
      return _buildStatusView(
        title: "No More Questions",
        message: response?['message'] ?? "You've caught up with all questions for now!",
        icon: Icons.check_circle_outline_rounded, iconColor: Colors.green, buttonText: "Go Back",
        onBtnPressed: () => Navigator.pop(context),
      );
    }

    _setupGame(response['question']);
    if (_targetWord.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                _buildHintCard(),
                if (widget.level.toLowerCase() == "beginner")
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                        _targetWord,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                            color: Colors.green
                        )
                    ),
                  ),
                const SizedBox(height: 50),
                _buildInputGrid(),
                const SizedBox(height: 40),
                _buildStatusIcon(),
              ],
            ),
          ),
        ),
        _buildBottomButton(),
      ],
    );
  }

  Widget _buildInputGrid() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        double offset = _shakeController.isAnimating ? (0.5 - (0.5 - _shakeController.value).abs()) * 15 : 0.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 5,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: List.generate(_targetWord.length, (i) {
                if (_targetWord[i] == " ") {
                  return const SizedBox(width: 10);
                }
                int controllerIdx = _targetWord.substring(0, i).replaceAll(" ", "").length;
                return _buildModernInputBox(controllerIdx);
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernInputBox(int index) {
    bool hasFocus = _focusNodes[index].hasFocus;

    return Container(
      width: 32,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: hasFocus ? const Color(0xFF1B75BB) : Colors.grey.shade300,
            width: hasFocus ? 2.0 : 1.0),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            _controllers[index].text.toUpperCase(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                counterText: "", border: InputBorder.none, isCollapsed: true),
            onChanged: (value) {
              setState(() {});
              if (value.isNotEmpty) {
                int nextIndex = index + 1;
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

  Widget _buildHintCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Text(_wordHint.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B75BB), letterSpacing: 4)),
    );
  }

  Widget _buildStatusIcon() {
    String enteredWord = _controllers.map((c) => c.text.toUpperCase()).join("");
    if (enteredWord.length != _targetWord.replaceAll(" ", "").length) return const SizedBox(height: 70);
    bool isCorrect = enteredWord == _targetWord.replaceAll(" ", "");

    return GestureDetector(
      onTap: isCorrect ? null : _clearInputs,
      child: Icon(
          isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isCorrect ? Colors.green : Colors.red,
          size: 65
      ),
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50),
      child: Center(
        child: SizedBox(
          width: 180,
          child: GestureDetector(
            onTap: _handleNext,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1B75BB), Color(0xFF6BCF2E)]), borderRadius: BorderRadius.circular(30)),
              child: const Center(child: Text("Next", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusView({required String title, required String message, required IconData icon, required Color iconColor, required String buttonText, required VoidCallback onBtnPressed}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 80, color: iconColor)),
            const SizedBox(height: 30),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2D3142))),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B75BB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(vertical: 18), elevation: 0),
                onPressed: onBtnPressed,
                child: Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}