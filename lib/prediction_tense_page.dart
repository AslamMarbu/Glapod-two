import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart'; // 🔹 Ensure this is in pubspec.yaml
import '../providers/prediction_tense_provider.dart';
import '../utils/app_colors.dart';
import 'widgets.dart/appbar_page.dart';

class PredictionTensePage extends StatefulWidget {
  final String level;
  const PredictionTensePage({super.key, required this.level});

  @override
  State<PredictionTensePage> createState() => _PredictionTensePageState();
}

class _PredictionTensePageState extends State<PredictionTensePage> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];

  String _targetWord = "";
  String _presentHint = "";
  String _v3Hint = "";
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    Future.microtask(() => _fetchNewQuestion());
  }

  void _fetchNewQuestion({String? status}) {
    _resetLocalState();
    context.read<PredictionTenseProvider>().loadQuestion(widget.level, status: status);
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

      _v3Hint = (question['future'] ?? question['past_participle'] ?? "---").toString();

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
        List<int> indices = List.generate(cleanTarget.length, (i) => i)..shuffle();
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
    _shakeController.dispose();
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tense = context.watch<PredictionTenseProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: const CustomAppBar(height: 60, title: "Past Tense", isDashboard: false),
      body: tense.isLoading
          ? _buildShimmerLoading() // 🔹 UI remains same, just replaced the Spinner
          : _buildBody(tense),
    );
  }

  // 🔹 ADDED: Shimmer Method that mimics your exact UI layout
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Container(width: 100, height: 14, color: Colors.white),
                  const SizedBox(height: 15),
                  Container(width: 180, height: 75, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15))),
                  const SizedBox(height: 40),
                  Container(width: 100, height: 14, color: Colors.white),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 5,
                    children: List.generate(6, (i) => Container(width: 32, height: 45, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            Container(width: double.infinity, height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Container(width: 65, height: 65, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(PredictionTenseProvider tense) {
    if (tense.isCompleted) {
      return _buildStatusView(
        title: "Level Mastered!",
        message: "Fantastic! Level completed.",
        icon: Icons.auto_awesome, iconColor: Colors.amber, buttonText: "Play Again",
        onBtnPressed: () => _fetchNewQuestion(status: "new"),
      );
    }

    final response = tense.currentResponse;
    if (response == null || response['status'].toString() == "false") {
      return _buildStatusView(
        title: "Sorry!",
        message: response?['message'] ?? "No more questions.",
        icon: Icons.info_outline, iconColor: Colors.blue, buttonText: "Go Back",
        onBtnPressed: () => Navigator.pop(context),
      );
    }

    if (!_isInitialized && response['question'] != null) {
      Future.microtask(() => _setupGame(response['question']));
      return _buildShimmerLoading(); // 🔹 Replaced spinner here too
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text("Base Form  [V1]", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 15),
                      _buildV1HintCard(),

                      if (widget.level.trim().toLowerCase() == "beginner")
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                              _targetWord,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 8, color: Color(0xFF1B75BB))
                          ),
                        ),

                      const SizedBox(height: 40),
                      const Text("Simple Past [V2]", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 20),
                      _buildInputGrid(),
                    ],
                  ),
                ),

                const SizedBox(height: 50),
                _buildV3Section(),
                const SizedBox(height: 20),
                _buildStatusIcon(),
              ],
            ),
          ),
        ),
        _buildBottomButton(),
      ],
    );
  }

  Widget _buildV1HintCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 25),
      decoration: BoxDecoration(
          color: const Color(0xFFF7F9FF),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))]
      ),
      child: Text(_presentHint.toUpperCase(),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1B75BB), letterSpacing: 6)),
    );
  }

  Widget _buildV3Section() {
    String enteredWord = _controllers.map((c) => c.text.toUpperCase()).join("");
    String cleanTarget = _targetWord.replaceAll(" ", "");
    bool isCorrect = enteredWord == cleanTarget && cleanTarget.isNotEmpty;
    bool isBeginner = widget.level.trim().toLowerCase() == "beginner";

    if (!isBeginner && !isCorrect) return const SizedBox(height: 60);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          children: [
            const TextSpan(text: "Past Participle [V3]: ", style: TextStyle(color: Colors.green)),
            TextSpan(text: _v3Hint.toUpperCase(), style: const TextStyle(color: Color(0xFF1B75BB))),
          ],
        ),
      ),
    );
  }

  Widget _buildInputGrid() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        double offset = _shakeController.isAnimating ? (0.5 - (0.5 - _shakeController.value).abs()) * 15 : 0.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: Wrap(
            spacing: 5,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: List.generate(_targetWord.length, (i) {
              if (_targetWord[i] == " ") return const SizedBox(width: 10);
              int controllerIdx = _targetWord.substring(0, i).replaceAll(" ", "").length;
              return _buildModernInputBox(controllerIdx);
            }),
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

  Widget _buildStatusIcon() {
    String enteredWord = _controllers.map((c) => c.text.toUpperCase()).join("");
    if (enteredWord.length != _targetWord.replaceAll(" ", "").length) return const SizedBox(height: 60);
    bool isCorrect = enteredWord == _targetWord.replaceAll(" ", "");

    return GestureDetector(
      onTap: isCorrect ? null : _clearInputs,
      child: Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isCorrect ? Colors.green : Colors.red, size: 65),
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Center(
        child: SizedBox(
          width: 250,
          child: GestureDetector(
            onTap: _handleNext,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1B75BB), Color(0xFF6BCF2E)]),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]
              ),
              child: const Center(child: Text("Next", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
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
            Icon(icon, size: 80, color: iconColor),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: onBtnPressed,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B75BB)),
              child: Text(buttonText, style: const TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}