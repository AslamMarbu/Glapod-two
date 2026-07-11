import 'package:flutter/material.dart';
import 'widgets.dart/appbar_page.dart';
import 'dart:async';
import 'package:translator/translator.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class TranslatorPage extends StatefulWidget {
  const TranslatorPage({super.key});

  @override
  State<TranslatorPage> createState() => _TranslatorPageState();
}

class _TranslatorPageState extends State<TranslatorPage> {
  // --- State Variables ---
  String sourceLanguage = "English";
  String targetLanguage = "Hindi";
  String sourceCode = "en";
  String targetCode = "hi";

  final TextEditingController sourceController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  String translatedText = "";
  Timer? _debounce;
  final translator = GoogleTranslator();
  final FlutterTts _tts = FlutterTts();

  // --- Speech Variables ---
  late stt.SpeechToText _speech;
  bool _isListening = false;

  // --- UI Styling Palette From Dashboard ---
  final Color backgroundColor = const Color(0xFFF1F5F9); // Light iOS-style tint
  final Color translatorOrange = const Color(
    0xFFED7E22,
  ); // From your Dashboard tile!
  final Color speakButtonColor = const Color.fromARGB(255, 255, 131, 42);
  final Color textDark = const Color(0xFF1E293B);
  final Color surfaceWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _tts.stop();
    sourceController.dispose();
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      sourceController.clear();
      translatedText = "";
    });
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == "done" || status == "notListening") {
            setState(() => _isListening = false);
          }
        },
        onError: (error) => debugPrint('Speech Error: $error'),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: sourceCode,
          onResult: (result) {
            setState(() {
              sourceController.text = result.recognizedWords;
              _translateText(result.recognizedWords);
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _speak(String text, String languageCode) async {
    if (text.trim().isEmpty) return;

    await _tts.stop();

    await _tts.setLanguage(languageCode);

    await _tts.setSpeechRate(0.5);

    await _tts.setPitch(1.0);

    await _tts.speak(text);
  }

  void _translateText(String text) async {
    if (text.trim().isEmpty) {
      setState(() => translatedText = "");
      return;
    }
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        var translation = await translator.translate(
          text,
          from: sourceCode,
          to: targetCode,
        );
        setState(() => translatedText = translation.text);
      } catch (e) {
        setState(() => translatedText = "Check Connection...");
      }
    });
  }

  void _swapLanguages() {
    setState(() {
      String tempName = sourceLanguage;
      sourceLanguage = targetLanguage;
      targetLanguage = tempName;

      String tempCode = sourceCode;
      sourceCode = targetCode;
      targetCode = tempCode;

      sourceController.text = translatedText;
      _translateText(sourceController.text);
    });
  }

  final Map<String, String> languages = {
    'Afrikaans': 'af',
    'Arabic': 'ar',
    'Bengali': 'bn',
    'Chinese': 'zh-cn',
    'English': 'en',
    'French': 'fr',
    'German': 'de',
    'Gujarati': 'gu',
    'Hindi': 'hi',
    'Japanese': 'ja',
    'Kannada': 'kn',
    'Korean': 'ko',
    'Malayalam': 'ml',
    'Marathi': 'mr',
    'Portuguese': 'pt',
    'Russian': 'ru',
    'Spanish': 'es',
    'Tamil': 'ta',
    'Telugu': 'te',
    'Urdu': 'ur',
    'Punjabi': 'pa',
    'Assamese': 'as',
    'Odia': 'or',
    'Nepali': 'ne',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      // CustomAppBar with matching clean text title style
      appBar: const CustomAppBar(
        height: 70,
        title: "Translator",
        isDashboard: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Language Selectors Block ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: surfaceWhite,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(child: _searchableDropdown(true)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _swapLanguages,
                          icon: Icon(
                            Icons.swap_horiz_rounded,
                            color: speakButtonColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: _searchableDropdown(false)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- 2. Input/Output Bento Cards ---
              _buildDashboardCard(
                label: sourceLanguage,
                isSource: true,
                child: TextField(
                  controller: sourceController,
                  maxLines: 5,
                  onChanged: _translateText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: textDark,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Tap to type text...",
                    hintStyle: TextStyle(color: Colors.black26),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildDashboardCard(
                label: targetLanguage,
                isSource: false,
                child: SelectableText(
                  translatedText.isEmpty
                      ? "Translation appears here..."
                      : translatedText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: translatedText.isEmpty
                        ? Colors.black26
                        : speakButtonColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 3. Dynamic Footer Actions ---
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _clearAll,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: surfaceWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black12, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            "Clear",
                            style: TextStyle(
                              color: textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _listen,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: _isListening
                              ? Colors.redAccent
                              : speakButtonColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_isListening
                                          ? Colors.redAccent
                                          : speakButtonColor)
                                      .withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isListening
                                  ? Icons.stop_circle_rounded
                                  : Icons.mic_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isListening ? "Listening..." : "Speak Now",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchableDropdown(bool isSource) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: Text(
          isSource ? sourceLanguage : targetLanguage,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textDark,
            fontSize: 15,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        items: languages.keys
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            if (isSource) {
              sourceLanguage = value;
              sourceCode = languages[value]!;
            } else {
              targetLanguage = value;
              targetCode = languages[value]!;
            }
            _translateText(sourceController.text);
          });
        },
        buttonStyleData: ButtonStyleData(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        iconStyleData: IconStyleData(iconEnabledColor: textDark),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 300,
          decoration: BoxDecoration(
            color: surfaceWhite,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        dropdownSearchData: DropdownSearchData(
          searchController: searchController,
          searchInnerWidgetHeight: 50,
          searchInnerWidget: Container(
            height: 55,
            padding: const EdgeInsets.all(8),
            child: TextFormField(
              controller: searchController,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                hintText: 'Search language...',
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          searchMatchFn: (item, searchValue) {
            return item.value.toString().toLowerCase().contains(
              searchValue.toLowerCase(),
            );
          },
        ),
        onMenuStateChange: (isOpen) {
          if (!isOpen) searchController.clear();
        },
      ),
    );
  }

  Widget _buildDashboardCard({
    required String label,
    required bool isSource,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isSource ? textDark.withOpacity(.5) : speakButtonColor,
                ),
              ),

              Row(
                children: [
                  Icon(
                    isSource
                        ? Icons.edit_note_rounded
                        : Icons.g_translate_rounded,
                    color: isSource
                        ? Colors.black26
                        : speakButtonColor.withOpacity(.4),
                    size: 20,
                  ),

                  const SizedBox(width: 8),

                  InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      _speak(
                        isSource ? sourceController.text : translatedText,
                        isSource ? sourceCode : targetCode,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: speakButtonColor.withOpacity(.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.volume_up_rounded,
                        color: speakButtonColor,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 110),
            child: child,
          ),
        ],
      ),
    );
  }
}
