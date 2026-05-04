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

class _PredictionNamePageState extends State<PredictionNamePage> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late PageController _pageController;

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
    _shakeController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _pageController = PageController();
    Future.microtask(() => _fetchNewQuestion());
  }

  void _fetchNewQuestion({String? status}) {
    _resetLocalState();
    context.read<PredictionGameProvider>().loadQuestion(
        widget.categoryId,
        widget.level,
        status: status
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

    String rawValue = (questionData['answer'] ?? questionData['name'] ?? "").toString();
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
                baseOffset: 0, extentOffset: controller.text.length);
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
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<PredictionGameProvider>();

    if (!game.isLoading && game.currentResponse != null && game.currentResponse!['question'] != null) {
      _setupGame(game.currentResponse!['question']);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1B75BB), Color(0xFF6BCF2E)]),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    widget.categoryName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 22),
                    onPressed: () {
                      setState(() => _isInitialized = false);
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (routeContext) => PredictionNameGridPage(
                          categoryName: widget.categoryName,
                          categoryId: widget.categoryId,
                          level: widget.level,
                        ),
                      ));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // 🔹 UI Logic: Show Shimmer skeleton while game.isLoading is true
      body: game.isLoading
          ? _buildShimmerLoading()
          : _buildGameContent(game),
    );
  }

  // 🔹 REUSABLE SHIMMER LOADING SKELETON
  Widget _buildShimmerLoading() {
    double screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Image Slider Skeleton
          ShimmerPlaceholder(width: screenWidth, height: screenWidth * 0.55, borderRadius: 0),
          const SizedBox(height: 40),

          // Input Grid Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: List.generate(6, (index) => const ShimmerPlaceholder(width: 32, height: 45, borderRadius: 6)),
            ),
          ),
          const SizedBox(height: 40),

          // Status Icon Skeleton
          const ShimmerPlaceholder(width: 55, height: 55, borderRadius: 30),
          const SizedBox(height: 20),

          // Remarks Box Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerPlaceholder(width: screenWidth, height: 45, borderRadius: 10),
          ),
          const SizedBox(height: 25),

          // Feedback Box Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerPlaceholder(width: screenWidth, height: 42, borderRadius: 12),
          ),
          const SizedBox(height: 50),

          // Next Button Skeleton
          const ShimmerPlaceholder(width: 180, height: 50, borderRadius: 30),
        ],
      ),
    );
  }

  Widget _buildGameContent(PredictionGameProvider game) {
    if (game.isCompleted) {
      return _buildStatusView(
        title: "Level Completed!",
        message: "Outstanding! You have found all the words in this level.",
        icon: Icons.emoji_events_rounded, iconColor: Colors.orangeAccent, buttonText: "Play Again",
        onBtnPressed: () => _fetchNewQuestion(status: "new"),
      );
    }

    final response = game.currentResponse;
    if (response == null || response['status'].toString() == "false") {
      return _buildStatusView(
        title: "No More Questions",
        message: response?['message'] ?? "You've caught up with all questions for now!",
        icon: Icons.check_circle_outline_rounded, iconColor: Colors.green, buttonText: "Go Back",
        onBtnPressed: () => Navigator.pop(context),
      );
    }

    if (_correctAnswer.isEmpty) return const SizedBox.shrink();

    final images = List<String>.from(response['question']['images'] ?? []);
    final dynamicNotes = response['question']['notes'] ?? response['question']['description'] ?? "No notes available.";
    final dynamicRemarks = response['question']['remarks'] ?? "GENERAL";

    String enteredWord = _controllers.map((c) => c.text.toUpperCase()).join("");
    bool isCorrect = enteredWord == _correctAnswer.replaceAll(" ", "");

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (images.isNotEmpty) _buildFullWidthImageSlider(images),
                const SizedBox(height: 30),
                if (widget.level.toLowerCase() == "beginner")
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(_correctAnswer, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 4, color: Color(0xFF1B75BB))),
                  ),
                _buildInputGrid(),
                const SizedBox(height: 25),
                _buildStatusIcon(),
                const SizedBox(height: 10),
                _buildRemarksAndPoints(dynamicRemarks),
                const SizedBox(height: 25),

                if (isCorrect) ...[
                  _buildNotesBox(dynamicNotes),
                  const SizedBox(height: 25),
                ],

                _buildFeedbackBox(),
                const SizedBox(height: 40),
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

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        double offset = _shakeController.isAnimating
            ? (0.5 - (0.5 - _shakeController.value).abs()) * 15
            : 0.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Wrap(
              spacing: 3,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: List.generate(targetPhrase.length, (index) {
                if (targetPhrase[index] == " ") {
                  return const SizedBox(width: 15);
                }
                return _buildModernInputBox(index);
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
            width: hasFocus ? 2.0 : 1.0
        ),
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
            decoration: const InputDecoration(counterText: "", border: InputBorder.none, isCollapsed: true),
            onChanged: (value) {
              setState(() {});
              if (value.isNotEmpty) {
                int nextIndex = index + 1;
                if (nextIndex < _correctAnswer.length && _correctAnswer[nextIndex] == " ") {
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

  Widget _buildFullWidthImageSlider(List<String> images) {
    double screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      height: screenWidth * 0.55,
      width: screenWidth,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) => Image.network(images[index], fit: BoxFit.cover, width: screenWidth),
          ),
          if (_currentImageIndex > 0)
            Positioned(left: 10, child: _buildArrowButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut))),
          if (_currentImageIndex < images.length - 1)
            Positioned(right: 10, child: _buildArrowButton(icon: Icons.arrow_forward_ios_rounded, onTap: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut))),
        ],
      ),
    );
  }

  Widget _buildArrowButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: const Color(0xFF1B75BB)),
      ),
    );
  }

  Widget _buildStatusIcon() {
    String enteredWord = _controllers.map((c) => c.text.toUpperCase()).join("");
    if (enteredWord.length != _correctAnswer.replaceAll(" ", "").length) return const SizedBox(height: 60);
    bool isCorrect = enteredWord == _correctAnswer.replaceAll(" ", "");
    return GestureDetector(onTap: isCorrect ? null : _clearInputs, child: Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isCorrect ? Colors.green : Colors.red, size: 55));
  }

  Widget _buildRemarksAndPoints(String remark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(color: const Color(0xFFEAF4FF).withOpacity(0.9), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF1B75BB), width: 1)),
        child: Row(
          children: [
            const Text("REMARKS: ", style: TextStyle(color: Color(0xFF1B75BB), fontWeight: FontWeight.bold, fontSize: 14)),
            Expanded(child: Text(remark.toUpperCase(), style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 14))),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesBox(String notes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity, height: 120, padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF135A91), Color(0xFF4A911F)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(child: RichText(text: TextSpan(children: [const TextSpan(text: "Notes: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)), TextSpan(text: notes, style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4))]))),
      ),
    );
  }

  Widget _buildFeedbackBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 42, padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF1B75BB).withOpacity(0.22), const Color(0xFF6BCF2E).withOpacity(0.22)]), borderRadius: BorderRadius.circular(12), border: Border.all(color: _feedbackError != null ? Colors.red : const Color(0xFF1B75BB), width: 1.2)),
        child: Row(
          children: [
            const Text("Feedback: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
            Expanded(child: TextField(controller: _feedbackController, maxLength: _maxFeedbackLength, decoration: const InputDecoration(hintText: "Enter here...", border: InputBorder.none, counterText: "", isCollapsed: true), onChanged: (value) => setState(() => _feedbackError = value.length > _maxFeedbackLength ? "Limit reached" : null))),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    String enteredWord = _controllers.map((c) => c.text.toUpperCase()).join("");
    bool isCorrect = enteredWord == _correctAnswer.replaceAll(" ", "");
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Center(
        child: SizedBox(
          width: 180,
          child: GestureDetector(
            onTap: _handleNext,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(gradient: LinearGradient(colors: isCorrect ? [const Color(0xFF1B75BB), const Color(0xFF6BCF2E)] : [Colors.grey, Colors.grey.shade400]), borderRadius: BorderRadius.circular(30)),
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
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF2D3142))),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B75BB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(vertical: 18)), onPressed: onBtnPressed, child: Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            )
          ],
        ),
      ),
    );
  }
}