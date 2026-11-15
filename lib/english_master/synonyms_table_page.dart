import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/student_service.dart';
import '../widgets.dart/appbar_page.dart';

class SynonymsTablePage extends StatefulWidget {
  const SynonymsTablePage({super.key});

  @override
  State<SynonymsTablePage> createState() => _SynonymsTablePageState();
}

class _SynonymsTablePageState extends State<SynonymsTablePage> {
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

  List<Map<String, dynamic>> _synonyms = [];

  bool _isLoading = true;
  String? _errorMessage;

  int _currentPage = 1;
  int _lastPage = 1;
  static const int _pageSize = 100;
  static const String _cacheKey = 'english_master_synonyms_cache_v1';

  Timer? _searchDebounce;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _loadSynonyms();
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

  Map<String, dynamic> _parseResponse(dynamic response) {
    Map<String, dynamic> body = _toMap(response);
    Map<String, dynamic> pagination = {};
    dynamic rawData;

    for (int depth = 0; depth < 4; depth++) {
      final candidatePagination = _toMap(body['pagination']);
      if (candidatePagination.isNotEmpty) pagination = candidatePagination;
      if (body['data'] is List) {
        rawData = body['data'];
        break;
      }
      final nested = _toMap(body['data']);
      if (nested.isEmpty) break;
      body = nested;
    }

    final dynamic status = body['status'];
    final bool success =
        status == true ||
        status == 1 ||
        status?.toString().toLowerCase() == 'true' ||
        body['success'] == true ||
        rawData is List;

    if (!success || rawData is! List) {
      throw Exception(
        body['message']?.toString() ??
            'The server did not return the synonyms list.',
      );
    }

    final records = rawData
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item['word'] != null || item['synonyms'] != null)
        .map(
          (item) => <String, dynamic>{
            'id': item['id'],
            'word': item['word']?.toString() ?? '',
            'synonyms': item['synonyms']?.toString() ?? '',
          },
        )
        .toList();

    return {
      'records': records,
      'current_page': _toInt(pagination['current_page'], 1),
      'last_page': _toInt(pagination['last_page'], 1).clamp(1, 1 << 30),
      'per_page': _toInt(pagination['per_page'], _pageSize),
    };
  }

  Future<List<Map<String, dynamic>>> _fetchPage(
    int page, {
    required String search,
  }) async {
    final response = await StudentService.fetchSynonyms(
      page: page,
      perPage: _pageSize,
      search: search,
    );
    return List<Map<String, dynamic>>.from(
      _parseResponse(response)['records'] as List,
    );
  }

  Future<void> _downloadRemainingPages({
    required int requestId,
    required String search,
    required int lastPage,
    required List<Map<String, dynamic>> firstPage,
    required bool cacheWasDisplayed,
  }) async {
    final allRecords = <Map<String, dynamic>>[...firstPage];

    for (int page = 2; page <= lastPage; page++) {
      if (!mounted || requestId != _requestId) return;
      final records = await _fetchPage(page, search: search);
      if (!mounted || requestId != _requestId) return;
      allRecords.addAll(records);

      if (!cacheWasDisplayed) {
        setState(() {
          _synonyms = List<Map<String, dynamic>>.from(allRecords);
          _isLoading = false;
          _errorMessage = null;
        });
      }
    }

    if (!mounted || requestId != _requestId) return;

    if (search.isEmpty) await _saveSynonymsCache(allRecords);
    if (cacheWasDisplayed) {
      setState(() {
        _synonyms = allRecords;
        _isLoading = false;
        _errorMessage = null;
      });
    }
  }

  Future<List<Map<String, dynamic>>?> _readSynonymsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(
            (item) => <String, dynamic>{
              'id': item['id'],
              'word': item['word']?.toString() ?? '',
              'synonyms': item['synonyms']?.toString() ?? '',
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Could not read synonyms cache: $e');
      return null;
    }
  }

  Future<void> _saveSynonymsCache(List<Map<String, dynamic>> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(records));
    } catch (e) {
      debugPrint('Could not save synonyms cache: $e');
    }
  }

  Future<void> _loadSynonyms({int page = 1, bool forceRefresh = false}) async {
    final int thisRequest = ++_requestId;
    final String search = _searchController.text.trim();
    final bool canUseCache = search.isEmpty && page == 1 && !forceRefresh;
    bool cacheWasDisplayed = false;

    if (canUseCache) {
      final cached = await _readSynonymsCache();
      if (!mounted || thisRequest != _requestId) return;
      if (cached != null && cached.isNotEmpty) {
        cacheWasDisplayed = true;
        setState(() {
          _synonyms = cached;
          _isLoading = false;
          _errorMessage = null;
          _currentPage = 1;
          _lastPage = 1;
        });
      }
    }

    if (!mounted || thisRequest != _requestId) return;
    setState(() {
      if (!cacheWasDisplayed) _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
    });

    try {
      final response = await StudentService.fetchSynonyms(
        page: 1,
        perPage: _pageSize,
        search: search,
      );
      if (!mounted || thisRequest != _requestId) return;

      final parsed = _parseResponse(response);
      final firstPage = List<Map<String, dynamic>>.from(
        parsed['records'] as List,
      );
      final int lastPage = (parsed['last_page'] as int).clamp(1, 1 << 30);

      setState(() {
        _lastPage = lastPage;
        _currentPage = 1;
        if (!cacheWasDisplayed) {
          _synonyms = firstPage;
          _isLoading = false;
        }
        _errorMessage = null;
      });

      if (lastPage > 1) {
        await _downloadRemainingPages(
          requestId: thisRequest,
          search: search,
          lastPage: lastPage,
          firstPage: firstPage,
          cacheWasDisplayed: cacheWasDisplayed,
        );
      } else {
        if (search.isEmpty) await _saveSynonymsCache(firstPage);
        if (mounted && thisRequest == _requestId && cacheWasDisplayed) {
          setState(() {
            _synonyms = firstPage;
            _isLoading = false;
            _errorMessage = null;
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Synonyms load error: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted || thisRequest != _requestId) return;
      setState(() {
        if (!cacheWasDisplayed && _synonyms.isEmpty) {
          _errorMessage =
              'Could not load synonyms. Please check your internet connection and try again.';
        }
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _requestId++;
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _loadSynonyms();
    });
    setState(() {});
  }

  Future<void> _refresh() async {
    await _loadSynonyms(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: CustomAppBar(height: 70, title: 'Synonyms Table'),
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
          hintText: 'Search a word or its synonyms...',
          hintStyle: const TextStyle(color: _muted, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: _teal, size: 25),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _searchDebounce?.cancel();
                    _loadSynonyms();
                    setState(() {});
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
          else if (_synonyms.isEmpty)
            _buildEmptyState()
          else
            _buildWordRows(isWide: isWide),
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
                'SYNONYMS',
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_synonyms.length, (index) {
          final item = _synonyms[index];

          final String word = item['word']?.toString() ?? '';
          final String synonyms = item['synonyms']?.toString() ?? '';
          final String displayedSynonyms = synonyms.trim().isEmpty
              ? '-'
              : synonyms;

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
                    text: displayedSynonyms,
                    background: _oppositeColors[colorIndex],
                    isWide: isWide,
                  ),
                ),
              ],
            ),
          );
        }),
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
            onPressed: () => _loadSynonyms(page: _currentPage),
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
