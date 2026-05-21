import 'package:flutter/material.dart';
import 'widgets.dart/appbar_page.dart';
import 'dart:async';
import 'package:translator/translator.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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

  // --- Speech Variables ---
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  // --- Clear Function ---
  void _clearAll() {
    setState(() {
      sourceController.clear();
      translatedText = "";
    });
  }

  // --- Microphone Logic ---
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

  // --- Translation Logic ---
  void _translateText(String text) async {
    if (text.trim().isEmpty) {
      setState(() => translatedText = "");
      return;
    }
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        var translation = await translator.translate(text, from: sourceCode, to: targetCode);
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

  // --- Language Data ---
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
      backgroundColor: const Color(0xFFE5E9F0),
      appBar: const CustomAppBar(height: 40, title: "Translator", isDashboard: false),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // --- Language Pickers ---
                    Row(
                      children: [
                        Expanded(child: _searchableDropdown(true)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: IconButton(
                            onPressed: _swapLanguages,
                            icon: const Icon(Icons.swap_horiz, color: Color(0xFF1E88E5), size: 28),
                          ),
                        ),
                        Expanded(child: _searchableDropdown(false)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // --- Clear Button Row (Color matched to Speak Now button) ---
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: _clearAll,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            // Applied the same gradient as the Speak Now button
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1B75BB), Color(0xFF6BCF2E)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Text(
                            "Clear",
                            style: TextStyle(
                              color: Colors.white, // Text color changed to white
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),

                    _buildTranslationBox(
                      label: sourceLanguage,
                      child: TextField(
                        controller: sourceController,
                        maxLines: 5,
                        onChanged: _translateText,
                        decoration: const InputDecoration(
                          hintText: "Speak or type here...",
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildTranslationBox(
                      label: targetLanguage,
                      child: SelectableText(
                        translatedText.isEmpty ? "Translation..." : translatedText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color: translatedText.isEmpty ? Colors.grey : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _micActionButton(onTap: _listen),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchableDropdown(bool isSource) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: Text(
          isSource ? sourceLanguage : targetLanguage,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 14
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        items: languages.keys.map((item) => DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        )).toList(),
        onChanged: (value) {
          setState(() {
            if (isSource) {
              sourceLanguage = value!;
              sourceCode = languages[value]!;
            } else {
              targetLanguage = value!;
              targetCode = languages[value]!;
            }
            _translateText(sourceController.text);
          });
        },
        buttonStyleData: ButtonStyleData(
          height: 38,
          padding: const EdgeInsets.only(left: 10, right: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B75BB), Color(0xFF6BCF2E)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
            ],
          ),
        ),
        iconStyleData: const IconStyleData(
          iconEnabledColor: Colors.white,
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 350,
          width: 170,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          offset: const Offset(0, -4),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF1FAF2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
              ),
            ),
          ),
          searchMatchFn: (item, searchValue) {
            return item.value.toString().toLowerCase().contains(searchValue.toLowerCase());
          },
        ),
        onMenuStateChange: (isOpen) {
          if (!isOpen) searchController.clear();
        },
      ),
    );
  }

  Widget _buildTranslationBox({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B75BB)),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 220,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1B75BB).withOpacity(0.22),
                const Color(0xFF6BCF2E).withOpacity(0.22),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _micActionButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isListening
                ? [Colors.red, Colors.orange]
                : [const Color(0xFF1B75BB), const Color(0xFF6BCF2E)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _isListening ? "Listening..." : "Speak Now",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}