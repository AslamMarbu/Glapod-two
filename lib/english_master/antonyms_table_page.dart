import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/student_service.dart';
import '../widgets.dart/appbar_page.dart';

class AntonymsTablePage extends StatefulWidget {
  const AntonymsTablePage({super.key});

  @override
  State<AntonymsTablePage> createState() => _AntonymsTablePageState();
}

class _AntonymsTablePageState extends State<AntonymsTablePage> {
  static const Color _navy = Color(0xFF24345A);
  static const Color _green = Color(0xFF16A765);
  static const Color _teal = Color(0xFF0F9D91);
  static const Color _purple = Color(0xFF7956C8);
  static const Color _orange = Color(0xFFEF8500);
  static const Color _background = Color(0xFFFFFCF2);
  static const Color _muted = Color(0xFF78839A);

  static const List<Color> _wordColors = [
    Color(0xFFE3F4E5),
    Color(0xFFFFE4ED),
    Color(0xFFE1F1FF),
    Color(0xFFFFF0CC),
    Color(0xFFEDE4FF),
    Color(0xFFDDF6F2),
  ];

  static const List<Color> _oppositeColors = [
    Color(0xFFFFE9D9),
    Color(0xFFE8E1FF),
    Color(0xFFFFE2F1),
    Color(0xFFDFF5FA),
    Color(0xFFFFE9C9),
    Color(0xFFE6F2DC),
  ];

  static const List<Color> _arrowColors = [
    Color(0xFF168BE0),
    Color(0xFFE83E8C),
    Color(0xFF8E44AD),
    Color(0xFF18A765),
    Color(0xFFEF8500),
    Color(0xFF6554C0),
  ];

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _antonyms = [];

  bool _isLoading = true;
  bool _isBackgroundLoading = false;
  String? _errorMessage;
  Timer? _searchDebounce;

  static const String _cacheKey = 'antonyms_table_all_records_v1';

  // Prevent an older search response from replacing newer results.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _loadAntonyms();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _parseAntonymsResponse(dynamic response) {
    final Map<String, dynamic> body = _toMap(response);
    dynamic rawData = body['data'];
    Map<String, dynamic> pagination = _toMap(body['pagination']);

    if (rawData is Map) {
      final nested = _toMap(rawData);
      if (nested['data'] is List) {
        rawData = nested['data'];
      }
      if (pagination.isEmpty) {
        pagination = _toMap(nested['pagination']);
      }
    }

    final bool success =
        body['status'] == true ||
        body['status'] == 1 ||
        body['status']?.toString().toLowerCase() == 'true' ||
        body['success'] == true;

    if (!success) {
      throw FormatException(
        body['message']?.toString() ??
            'The server did not return the antonym list.',
      );
    }

    if (rawData is! List) {
      throw const FormatException(
        'The API response does not contain a word list.',
      );
    }

    final records = rawData
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item['word'] != null || item['opposite_word'] != null)
        .toList();

    return <String, dynamic>{
      'records': records,
      'last_page': _toInt(pagination['last_page'], 1),
    };
  }

  Future<void> _loadAntonyms({bool forceRefresh = false}) async {
    final int thisRequest = ++_requestId;
    final String search = _searchController.text.trim();
    final bool isFullList = search.isEmpty;
    bool showingCachedList = false;

    _searchDebounce?.cancel();

    // Show the complete cached list immediately when reopening the page.
    if (isFullList && !forceRefresh) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedJson = prefs.getString(_cacheKey);
        if (cachedJson != null && cachedJson.isNotEmpty) {
          final decoded = jsonDecode(cachedJson);
          if (decoded is List) {
            final cachedRecords = decoded
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            if (mounted &&
                thisRequest == _requestId &&
                cachedRecords.isNotEmpty) {
              setState(() {
                _antonyms = cachedRecords;
                _isLoading = false;
                _errorMessage = null;
                showingCachedList = true;
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Could not read antonym cache: $e');
      }
    }

    if (!mounted || thisRequest != _requestId) return;

    setState(() {
      // Keep cached/already-loaded rows visible during refreshes and searches.
      _isLoading = _antonyms.isEmpty;
      _isBackgroundLoading = false;
      _errorMessage = null;
    });

    try {
      final firstResponse = await StudentService.fetchAntonyms(
        page: 1,
        perPage: 100,
        search: search,
      );

      if (!mounted || thisRequest != _requestId) return;

      final firstParsed = _parseAntonymsResponse(firstResponse);
      final List<Map<String, dynamic>> records =
          List<Map<String, dynamic>>.from(firstParsed['records'] as List);
      final int lastPage = (firstParsed['last_page'] as int)
          .clamp(1, 100000)
          .toInt();

      // Display the first 100 records as soon as the first request completes.
      setState(() {
        // Keep a complete cached list visible while refreshing it in background.
        if (!showingCachedList) _antonyms = records;
        _isLoading = false;
        _isBackgroundLoading = lastPage > 1;
      });

      // Fetch remaining pages sequentially in the background, adding each
      // batch as soon as it arrives instead of waiting for the entire dataset.
      for (int page = 2; page <= lastPage; page++) {
        final response = await StudentService.fetchAntonyms(
          page: page,
          perPage: 100,
          search: search,
        );

        if (!mounted || thisRequest != _requestId) return;

        final parsed = _parseAntonymsResponse(response);
        final nextBatch = List<Map<String, dynamic>>.from(
          parsed['records'] as List,
        );
        records.addAll(nextBatch);

        setState(() {
          if (!showingCachedList) {
            _antonyms = List<Map<String, dynamic>>.from(records);
          }
          _isLoading = false;
          _isBackgroundLoading = page < lastPage;
        });
      }

      if (!mounted || thisRequest != _requestId) return;

      // Cache only the complete, unfiltered dataset; don't overwrite it with
      // search results or an incomplete download.
      if (isFullList) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, jsonEncode(records));
        } catch (e) {
          debugPrint('Could not save antonym cache: $e');
        }
      }

      setState(() {
        _antonyms = records;
        _isLoading = false;
        _isBackgroundLoading = false;
        _errorMessage = null;
      });

      debugPrint('Antonyms rows loaded: ${records.length}');
    } catch (e, stackTrace) {
      debugPrint('Antonyms load error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted || thisRequest != _requestId) return;

      setState(() {
        _isLoading = false;
        _isBackgroundLoading = false;
        // Preserve rows already displayed if a later background page fails.
        if (_antonyms.isEmpty) {
          _errorMessage = e is FormatException
              ? e.message
              : 'Could not load words. Please check your internet connection and try again.';
        }
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    setState(() {});
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _loadAntonyms(forceRefresh: true);
    });
  }

  Future<void> _refresh() async {
    await _loadAntonyms(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: CustomAppBar(height: 70, title: 'Antonyms Table'),
      body: SafeArea(
        child: RefreshIndicator(
          color: _teal,
          onRefresh: _refresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 600;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 24 : 12,
                  vertical: 16,
                ),
                children: [
                  _buildSearchBox(),
                  const SizedBox(height: 16),
                  _buildTableCard(isWide: isWide),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E8D8)),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(
          color: _navy,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Search a word or its opposite...',
          hintStyle: const TextStyle(color: _muted, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: _teal, size: 25),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _searchDebounce?.cancel();
                    setState(() {});
                    _loadAntonyms(forceRefresh: true);
                  },
                  icon: const Icon(Icons.close_rounded, color: _muted),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCard({required bool isWide}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E5D7)),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTableHeader(isWide: isWide),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 45),
              child: Column(
                children: [
                  CircularProgressIndicator(color: _teal),
                  SizedBox(height: 12),
                  Text(
                    'Loading words...',
                    style: TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else if (_errorMessage != null)
            _buildErrorState()
          else if (_antonyms.isEmpty)
            _buildEmptyState()
          else ...[
            _buildWordRows(isWide: isWide),
            if (_isBackgroundLoading)
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 4, 12, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _teal,
                      ),
                    ),
                    SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        'Loading more words in the background...',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeader({required bool isWide}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 12 : 6, vertical: 15),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF16A765), Color(0xFF0F9D91)],
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 5,
            child: Center(
              child: Text(
                'WORD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          SizedBox(
            width: isWide ? 54 : 34,
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const Expanded(
            flex: 5,
            child: Center(
              child: Text(
                'OPPOSITE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordRows({required bool isWide}) {
    return Padding(
      padding: EdgeInsets.all(isWide ? 12 : 7),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _antonyms.length,
        itemBuilder: (context, index) {
          final item = _antonyms[index];
          final String word = item['word']?.toString() ?? '';
          final String opposite = item['opposite_word']?.toString() ?? '';
          final int colorIndex = index % _wordColors.length;

          return Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 5,
                  child: _wordCell(
                    text: word,
                    background: _wordColors[colorIndex],
                    isWide: isWide,
                  ),
                ),
                SizedBox(
                  width: isWide ? 54 : 34,
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    size: isWide ? 34 : 26,
                    color: _arrowColors[colorIndex],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: _wordCell(
                    text: opposite,
                    background: _oppositeColors[colorIndex],
                    isWide: isWide,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _wordCell({
    required String text,
    required Color background,
    required bool isWide,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 10 : 4, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _navy.withValues(alpha: 0.035)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        softWrap: true,
        style: TextStyle(
          color: _navy,
          fontSize: isWide ? 16 : 13,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 42,
            color: _purple.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 10),
          const Text(
            'No words found',
            style: TextStyle(
              color: _navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Try another search, or pull down to refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: _orange, size: 40),
          const SizedBox(height: 10),
          Text(
            _errorMessage ?? 'Unable to load words.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _navy, fontSize: 13),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => _loadAntonyms(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
