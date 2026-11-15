import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Edmaster/services/student_service.dart';

import '../widgets.dart/appbar_page.dart';

class WordFamilyPage extends StatefulWidget {
  const WordFamilyPage({super.key});

  @override
  State<WordFamilyPage> createState() => _WordFamilyPageState();
}

class _WordFamilyPageState extends State<WordFamilyPage> {
  final TextEditingController _searchController = TextEditingController();

  static const int _perPage = 100;
  static const String _cacheKey = 'english_master_word_families_cache_v1';

  Timer? _searchDebounce;
  List<Map<String, String>> _wordFamilies = [];
  String _searchText = '';
  String? _errorMessage;

  bool _isLoading = true;
  bool _isRetrying = false;
  bool _isBackgroundLoading = false;

  int _lastPage = 1;
  int _totalRecords = 0;
  int _requestNumber = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadWordFamilies();
  }

  void _onSearchChanged() {
    final search = _searchController.text.trim();
    if (search == _searchText) return;

    setState(() {
      _searchText = search;
    });

    // Invalidate requests already in flight while the new query is debounced.
    _requestNumber++;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _loadWordFamilies();
    });
  }

  int _readInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  List<Map<String, String>> _parseFamilies(dynamic rawData) {
    if (rawData is! List) return <Map<String, String>>[];

    return rawData.whereType<Map>().map((item) {
      String valueOf(String key) => item[key]?.toString() ?? '';
      return <String, String>{
        'id': valueOf('id'),
        'headword': valueOf('headword'),
        'verb': valueOf('verb'),
        'noun': valueOf('noun'),
        'adjective': valueOf('adjective'),
        'adverb': valueOf('adverb'),
      };
    }).toList();
  }

  Future<List<Map<String, String>>?> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson == null || cachedJson.isEmpty) return null;

      final decoded = jsonDecode(cachedJson);
      if (decoded is! List) return null;
      return _parseFamilies(decoded);
    } catch (e) {
      debugPrint('Read Word Families cache error: $e');
      return null;
    }
  }

  Future<void> _saveCache(List<Map<String, String>> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(records));
    } catch (e) {
      debugPrint('Save Word Families cache error: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchPage(int page, String search) async {
    final response = await StudentService.fetchWordFamilies(
      page: page,
      perPage: _perPage,
      search: search,
    );

    if (response['status'] != true) {
      throw Exception(
        response['message']?.toString() ?? 'Unable to load Word Families.',
      );
    }
    return response;
  }

  Future<void> _loadWordFamilies({bool retry = false}) async {
    final int requestId = ++_requestNumber;
    final String search = _searchText;
    final bool shouldUseCache = search.isEmpty;

    setState(() {
      _isLoading = true;
      _isRetrying = retry;
      _errorMessage = null;
      _isBackgroundLoading = false;
    });

    List<Map<String, String>>? cached;
    if (shouldUseCache) {
      cached = await _readCache();
      if (!mounted || requestId != _requestNumber) return;

      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _wordFamilies = cached!;
          _totalRecords = cached.length;
          _lastPage = 1;
          _isLoading = false;
          _isBackgroundLoading = true;
        });
      }
    }

    try {
      final firstResponse = await _fetchPage(1, search);
      if (!mounted || requestId != _requestNumber) return;

      final firstPageRecords = _parseFamilies(firstResponse['data']);
      final pagination = firstResponse['pagination'];
      final int lastPage = pagination is Map
          ? _readInt(pagination['last_page'], 1).clamp(1, 1 << 30).toInt()
          : 1;
      final int total = pagination is Map
          ? _readInt(pagination['total'], firstPageRecords.length)
          : firstPageRecords.length;

      if (cached == null || cached.isEmpty) {
        setState(() {
          _wordFamilies = firstPageRecords;
          _lastPage = lastPage;
          _totalRecords = total;
          _isLoading = false;
          _errorMessage = null;
          _isBackgroundLoading = lastPage > 1;
        });
      }

      if (lastPage <= 1) {
        if (shouldUseCache) await _saveCache(firstPageRecords);
        if (!mounted || requestId != _requestNumber) return;
        setState(() {
          _wordFamilies = firstPageRecords;
          _lastPage = 1;
          _totalRecords = total;
          _isLoading = false;
          _isBackgroundLoading = false;
          _errorMessage = null;
        });
        return;
      }

      // Download remaining pages sequentially, while the first page is already
      // visible. Keep a separate list when cached rows are being displayed.
      final allFreshRecords = <Map<String, String>>[...firstPageRecords];
      for (int page = 2; page <= lastPage; page++) {
        final response = await _fetchPage(page, search);
        if (!mounted || requestId != _requestNumber) return;
        allFreshRecords.addAll(_parseFamilies(response['data']));

        if (cached == null || cached.isEmpty) {
          setState(() {
            _wordFamilies = List<Map<String, String>>.from(allFreshRecords);
            _totalRecords = total > allFreshRecords.length
                ? total
                : allFreshRecords.length;
          });
        }
      }

      if (shouldUseCache) await _saveCache(allFreshRecords);
      if (!mounted || requestId != _requestNumber) return;

      setState(() {
        _wordFamilies = allFreshRecords;
        _totalRecords = allFreshRecords.length > total
            ? allFreshRecords.length
            : total;
        _lastPage = lastPage;
        _isLoading = false;
        _isBackgroundLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted || requestId != _requestNumber) return;
      setState(() {
        if (_wordFamilies.isEmpty) {
          _errorMessage = e.toString().replaceFirst('Exception: ', '').trim();
        }
        _isLoading = false;
        _isRetrying = false;
        _isBackgroundLoading = false;
      });
      debugPrint('Word Families load error: $e');
    } finally {
      if (mounted && requestId == _requestNumber) {
        setState(() {
          _isLoading = false;
          _isRetrying = false;
          _isBackgroundLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: const CustomAppBar(height: 70, title: 'Word Family'),
      body: Column(
        children: [
          // SEARCH
          Container(
            color: const Color(0xFFF5F7FB),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFD7DEE8)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search word family...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF8A94A3),
                    fontSize: 15,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF4267B2),
                    size: 25,
                  ),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          onPressed: () => _searchController.clear(),
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: Color(0xFF7A8490),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // LIST / LOADING / ERROR / EMPTY
          Expanded(
            child: _isLoading && _wordFamilies.isEmpty
                ? _buildLoading()
                : _errorMessage != null && _wordFamilies.isEmpty
                ? _buildError()
                : _wordFamilies.isEmpty
                ? _buildNoResults()
                : Stack(
                    children: [
                      ListView.builder(
                        key: PageStorageKey<String>('word-family-$_searchText'),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        itemCount: _wordFamilies.length,
                        itemBuilder: (context, index) =>
                            _buildFamilyCard(_wordFamilies[index]),
                      ),
                      if (_isLoading || _isBackgroundLoading)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            color: const Color(0xFF00897B),
                            backgroundColor: const Color(0xFFE8F7F5),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF00897B)),
          SizedBox(height: 14),
          Text(
            'Loading word families...',
            style: TextStyle(color: Color(0xFF667085), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: Color(0xFFE65100),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load Word Families',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF344054),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF8A94A3)),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _isRetrying
                  ? null
                  : () => _loadWordFamilies(retry: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FAMILY CARD - design retained from the existing page.
  Widget _buildFamilyCard(Map<String, String> family) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE3EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_tree_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    family['headword'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Column(
              children: [
                _buildWordRow(
                  label: 'VERB',
                  word: family['verb'] ?? '',
                  icon: Icons.play_arrow_rounded,
                  color: const Color(0xFF1976D2),
                  background: const Color(0xFFEAF3FF),
                ),
                _buildDivider(),
                _buildWordRow(
                  label: 'NOUN',
                  word: family['noun'] ?? '',
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF00897B),
                  background: const Color(0xFFE8F7F5),
                ),
                _buildDivider(),
                _buildWordRow(
                  label: 'ADJECTIVE',
                  word: family['adjective'] ?? '',
                  icon: Icons.auto_awesome_rounded,
                  color: const Color(0xFF7B1FA2),
                  background: const Color(0xFFF5EAF8),
                ),
                _buildDivider(),
                _buildWordRow(
                  label: 'ADVERB',
                  word: family['adverb'] ?? '',
                  icon: Icons.speed_rounded,
                  color: const Color(0xFFE65100),
                  background: const Color(0xFFFFF0E8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordRow({
    required String label,
    required String word,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            word,
            softWrap: true,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF263238),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 9),
      child: Divider(height: 1, thickness: 0.7, color: Color(0xFFE8ECF1)),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5F3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: Color(0xFF00897B),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No word family found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF344054),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try searching another word',
              style: TextStyle(fontSize: 13, color: Color(0xFF8A94A3)),
            ),
          ],
        ),
      ),
    );
  }
}
