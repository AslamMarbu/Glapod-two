import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class VerbFormsPage extends StatefulWidget {
  const VerbFormsPage({super.key});

  @override
  State<VerbFormsPage> createState() => _VerbFormsPageState();
}

class _VerbFormsPageState extends State<VerbFormsPage> {
  // ===========================================================================
  // API
  // ===========================================================================

  static const String _apiUrl =
      'https://edmaster.in/api/english-master/verb-forms';

  static const int _perPage = 50;

  final Dio _dio = Dio();

  // ===========================================================================
  // SEARCH / SCROLL
  // ===========================================================================

  final TextEditingController _searchController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final ScrollController _horizontalScrollController = ScrollController();

  final FocusNode _landscapeSearchFocusNode = FocusNode();

  bool _landscapeSearchOpen = false;

  static const double _columnWidth = 160.0;
  static const double _tableWidth = _columnWidth * 5;

  Timer? _searchDebounce;

  // ===========================================================================
  // DATA
  // ===========================================================================

  final List<Map<String, String>> _verbs = [];

  int _currentPage = 0;
  int _lastPage = 1;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;

  String _errorMessage = '';

  bool _requestInProgress = false;

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    _loadFirstPage();
  }

  // ===========================================================================
  // TOKEN
  // ===========================================================================

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('token') ??
        prefs.getString('access_token') ??
        prefs.getString('auth_token');
  }

  // ===========================================================================
  // API OPTIONS
  // ===========================================================================

  Future<Options> _requestOptions() async {
    final token = await _getToken();

    final headers = <String, dynamic>{'Accept': 'application/json'};

    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    return Options(headers: headers, responseType: ResponseType.json);
  }

  // ===========================================================================
  // LOAD FIRST PAGE
  // ===========================================================================

  Future<void> _loadFirstPage() async {
    if (_requestInProgress) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      _requestInProgress = true;

      debugPrint('========================================');
      debugPrint('VERB API: Loading first page');
      debugPrint('VERB API URL: $_apiUrl');
      debugPrint('VERB SEARCH: ${_searchController.text.trim()}');

      final response = await _dio.get(
        _apiUrl,
        queryParameters: {
          'page': 1,
          'per_page': _perPage,
          if (_searchController.text.trim().isNotEmpty)
            'search': _searchController.text.trim(),
        },
        options: await _requestOptions(),
      );

      debugPrint('VERB API STATUS: ${response.statusCode}');

      debugPrint('VERB API RESPONSE: ${response.data}');

      debugPrint('========================================');

      _handleResponse(response, replaceData: true);
    } on DioException catch (e) {
      debugPrint('VERB API DIO ERROR: $e');

      _handleDioError(e);
    } catch (e, stackTrace) {
      debugPrint('VERB API ERROR: $e');

      debugPrint('VERB API STACKTRACE: $stackTrace');

      _handleError(e.toString());
    } finally {
      _requestInProgress = false;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  //============================================================================
  //Rotate
  //============================================================================

  Future<void> _rotateToLandscape() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // ===========================================================================
  // LOAD NEXT PAGE
  // ===========================================================================

  Future<void> _loadNextPage() async {
    if (_requestInProgress ||
        _isLoading ||
        _isLoadingMore ||
        _currentPage >= _lastPage) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
      _hasError = false;
    });

    try {
      _requestInProgress = true;

      final nextPage = _currentPage + 1;

      debugPrint('VERB API: Loading page $nextPage');

      final response = await _dio.get(
        _apiUrl,
        queryParameters: {
          'page': nextPage,
          'per_page': _perPage,
          if (_searchController.text.trim().isNotEmpty)
            'search': _searchController.text.trim(),
        },
        options: await _requestOptions(),
      );

      debugPrint(
        'VERB API PAGE $nextPage STATUS: '
        '${response.statusCode}',
      );

      _handleResponse(response, replaceData: false);
    } on DioException catch (e) {
      debugPrint('VERB NEXT PAGE DIO ERROR: $e');

      _handleDioError(e);
    } catch (e, stackTrace) {
      debugPrint('VERB NEXT PAGE ERROR: $e');

      debugPrint('VERB NEXT PAGE STACKTRACE: $stackTrace');

      _handleError(e.toString());
    } finally {
      _requestInProgress = false;

      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  // ===========================================================================
  // SAFE INTEGER PARSER
  // ===========================================================================

  int _readInt(dynamic value, {int fallback = 0}) {
    if (value == null) {
      return fallback;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? fallback;
  }

  // ===========================================================================
  // RESPONSE
  // ===========================================================================

  void _handleResponse(Response response, {required bool replaceData}) {
    final dynamic body = response.data;

    debugPrint('VERB RESPONSE TYPE: ${body.runtimeType}');

    // -------------------------------------------------------------------------
    // Validate response
    // -------------------------------------------------------------------------

    if (body is! Map) {
      throw Exception('Invalid API response format.');
    }

    // -------------------------------------------------------------------------
    // Success
    // -------------------------------------------------------------------------

    final dynamic success = body['success'];

    if (success != true) {
      final dynamic message = body['message'];

      throw Exception(
        message != null ? message.toString() : 'Unable to load verb forms.',
      );
    }

    // -------------------------------------------------------------------------
    // Data
    // -------------------------------------------------------------------------

    final dynamic rawData = body['data'];

    if (rawData is! List) {
      throw Exception('Invalid verb forms data.');
    }

    // -------------------------------------------------------------------------
    // Convert API records
    // -------------------------------------------------------------------------

    final List<Map<String, String>> newVerbs = [];

    for (final dynamic item in rawData) {
      if (item is! Map) {
        continue;
      }

      final String v1 = item['v1']?.toString() ?? '';

      final String v2 = item['v2']?.toString() ?? '';

      final String v3 = item['v3']?.toString() ?? '';

      final String v4 = item['v4']?.toString() ?? '';

      final String v5 = item['v5']?.toString() ?? '';

      newVerbs.add({'v1': v1, 'v2': v2, 'v3': v3, 'v4': v4, 'v5': v5});
    }

    // -------------------------------------------------------------------------
    // Pagination
    // -------------------------------------------------------------------------

    final dynamic rawPagination = body['pagination'];

    int currentPage = 1;
    int lastPage = 1;

    if (rawPagination is Map) {
      currentPage = _readInt(rawPagination['current_page'], fallback: 1);

      lastPage = _readInt(rawPagination['last_page'], fallback: currentPage);
    }

    // Make sure values are always valid.
    if (currentPage < 1) {
      currentPage = 1;
    }

    if (lastPage < currentPage) {
      lastPage = currentPage;
    }

    debugPrint('VERB DATA COUNT: ${newVerbs.length}');

    debugPrint('VERB CURRENT PAGE: $currentPage');

    debugPrint('VERB LAST PAGE: $lastPage');

    // -------------------------------------------------------------------------
    // Update UI
    // -------------------------------------------------------------------------

    if (!mounted) {
      return;
    }

    setState(() {
      if (replaceData) {
        _verbs
          ..clear()
          ..addAll(newVerbs);
      } else {
        _verbs.addAll(newVerbs);
      }

      _currentPage = currentPage;
      _lastPage = lastPage;

      _hasError = false;
      _errorMessage = '';
    });

    debugPrint(
      'VERB TOTAL ROWS CURRENTLY LOADED: '
      '${_verbs.length}',
    );
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) {
        return;
      }

      _loadFirstPage();
    });

    setState(() {});
  }

  // ===========================================================================
  // CLEAR SEARCH
  // ===========================================================================

  void _clearSearch() {
    _searchController.clear();

    setState(() {});

    _loadFirstPage();
  }

  void _showSearchDialog() {
    final TextEditingController searchController = TextEditingController(
      text: _searchController.text,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Search Verb',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: searchController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search verb...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFFF16704),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (value) {
              _searchController.text = value.trim();
              _onSearchChanged(value.trim());

              Navigator.pop(dialogContext);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _searchController.text = searchController.text.trim();

                _onSearchChanged(searchController.text.trim());

                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF16704),
                foregroundColor: Colors.white,
              ),
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }
  // ===========================================================================
  // INFINITE SCROLL
  // ===========================================================================

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;

    // Start loading before reaching bottom.
    if (position.pixels >= position.maxScrollExtent - 400) {
      _loadNextPage();
    }
  }

  // ===========================================================================
  // ERROR
  // ===========================================================================

  void _handleDioError(DioException e) {
    String message = 'Unable to load verb forms.';

    final int? statusCode = e.response?.statusCode;

    if (statusCode == 401) {
      message = 'Session expired. Please login again.';
    } else if (statusCode == 403) {
      message = 'You do not have permission to access verb forms.';
    } else if (statusCode == 404) {
      message = 'Verb forms API was not found.';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      message = 'Connection timed out. Please try again.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection.';
    } else {
      final dynamic responseData = e.response?.data;

      if (responseData is Map) {
        final dynamic apiMessage = responseData['message'];

        if (apiMessage != null) {
          message = apiMessage.toString();
        }
      }
    }

    _handleError(message);
  }

  void _handleError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _hasError = true;
      _errorMessage = message;
    });
  }

  Future<void> _retry() async {
    await _loadFirstPage();
  }

  // ===========================================================================
  // COLUMN COLORS
  // ===========================================================================

  Color _getColumnColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFFDE7);

      case 1:
        return const Color(0xFFEAF3FF);

      case 2:
        return const Color(0xFFFFF1EB);

      case 3:
        return const Color(0xFFEEFAF0);

      case 4:
        return const Color(0xFFF0F0FF);

      default:
        return Colors.white;
    }
  }

  // ===========================================================================
  // HEADER COLORS
  // ===========================================================================

  Color _getHeaderColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFDF57);

      case 1:
        return const Color(0xFFB9D5F4);

      case 2:
        return const Color(0xFFF4C7B5);

      case 3:
        return const Color(0xFFBFE5C5);

      case 4:
        return const Color(0xFFC9C9F0);

      default:
        return Colors.grey;
    }
  }

  // ===========================================================================
  // FORM NAMES
  // ===========================================================================

  String _getFormName(int index) {
    const names = [
      'Base Form (V1)',
      'Past Simple (V2)',
      'Past Participle (V3)',
      'Present Participle (V4)',
      '3rd Person Singular (V5)',
    ];

    return names[index];
  }

  // ===========================================================================
  // SEARCH BOX
  // ===========================================================================

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: TextField(
        controller: _searchController,

        textInputAction: TextInputAction.search,

        onChanged: _onSearchChanged,

        decoration: InputDecoration(
          hintText: 'Search verb...',

          hintStyle: const TextStyle(color: Color(0xFF8A94A3), fontSize: 15),

          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFFF16704),
          ),

          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: Color(0xFF7A8490),
                  ),
                )
              : null,

          filled: true,

          fillColor: Colors.white,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFF16704), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeSearchBar() {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _landscapeSearchOpen
                  ? Row(
                      key: const ValueKey('search_open'),
                      children: [
                        SizedBox(
                          width: 280,
                          height: 40,
                          child: TextField(
                            controller: _searchController,
                            focusNode: _landscapeSearchFocusNode,
                            autofocus: true,
                            textInputAction: TextInputAction.search,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search verb...',
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 22,
                                color: Color(0xFFF16704),
                              ),
                              suffixIcon: IconButton(
                                tooltip: 'Close',
                                onPressed: _closeLandscapeSearch,
                                icon: const Icon(Icons.close_rounded, size: 21),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD7D7D7),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD7D7D7),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFF16704),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : IconButton(
                      key: const ValueKey('search_closed'),
                      tooltip: 'Search',
                      onPressed: _openLandscapeSearch,
                      icon: const Icon(
                        Icons.search_rounded,
                        size: 27,
                        color: Color(0xFF455A64),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLandscapeSearch() {
    setState(() {
      _landscapeSearchOpen = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _landscapeSearchFocusNode.requestFocus();
    });
  }

  void _closeLandscapeSearch() {
    _landscapeSearchFocusNode.unfocus();

    setState(() {
      _landscapeSearchOpen = false;
    });
  }
  // ===========================================================================
  // TABLE HEADER
  // ===========================================================================

  Widget _buildTableHeader({required double columnWidth}) {
    return SizedBox(
      width: columnWidth * 5,
      child: Row(
        children: List.generate(5, (index) {
          return SizedBox(
            width: columnWidth,
            height: 68,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: _getHeaderColor(index),
                border: Border(
                  left: index == 0
                      ? const BorderSide(color: Color(0xFFD6D6D6))
                      : BorderSide.none,
                  right: const BorderSide(color: Color(0xFFD6D6D6)),
                  bottom: const BorderSide(color: Color(0xFFD6D6D6)),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _getFormName(index),
                textAlign: TextAlign.center,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF263238),
                  height: 1.2,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ===========================================================================
  // VERB ROW
  // ===========================================================================

  Widget _buildVerbRow(
    Map<String, String> verb, {
    required double columnWidth,
  }) {
    final values = [
      verb['v1'] ?? '',
      verb['v2'] ?? '',
      verb['v3'] ?? '',
      verb['v4'] ?? '',
      verb['v5'] ?? '',
    ];

    return SizedBox(
      width: columnWidth * 5,
      child: Row(
        children: List.generate(5, (columnIndex) {
          return SizedBox(
            width: columnWidth,
            height: 52,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _getColumnColor(columnIndex),
                border: Border(
                  left: columnIndex == 0
                      ? const BorderSide(color: Color(0xFFD6D6D6))
                      : BorderSide.none,
                  right: const BorderSide(color: Color(0xFFE0E0E0)),
                  bottom: const BorderSide(color: Color(0xFFD6D6D6)),
                ),
              ),
              child: Text(
                values[columnIndex],
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF37474F),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ===========================================================================
  // EMPTY / LOADING / ERROR STATE
  // ===========================================================================

  Widget _buildEmptyState() {
    // -------------------------------------------------------------------------
    // Loading
    // -------------------------------------------------------------------------

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF16704)),
      );
    }

    // -------------------------------------------------------------------------
    // Error
    // -------------------------------------------------------------------------

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              const Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey),

              const SizedBox(height: 12),

              Text(
                _errorMessage,
                textAlign: TextAlign.center,

                style: const TextStyle(fontSize: 16, color: Color(0xFF455A64)),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _retry,

                icon: const Icon(Icons.refresh),

                label: const Text('Retry'),

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF16704),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // No data
    // -------------------------------------------------------------------------

    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey),

            SizedBox(height: 12),

            Text(
              'No verbs found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF455A64),
              ),
            ),

            SizedBox(height: 5),

            Text(
              'Try another search term.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM LOADER
  // ===========================================================================

  Widget _buildBottomLoader() {
    if (!_isLoadingMore) {
      return const SizedBox(height: 20);
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),

      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,

          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Color(0xFFF16704),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _searchDebounce?.cancel();

    _searchController.dispose();

    _landscapeSearchFocusNode.dispose();

    _scrollController.dispose();

    _horizontalScrollController.dispose();

    _dio.close(force: true);

    // Return to portrait when leaving this page.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),

      // ===============================================================
      // PORTRAIT APP BAR
      // ===============================================================
      appBar: isLandscape
          ? null
          : AppBar(
              elevation: 0,
              backgroundColor: const Color(0xFF89A8D4),
              foregroundColor: Colors.black,
              centerTitle: true,
              title: const Text(
                'Verb Forms (V1 - V5)',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Landscape',
                  onPressed: _rotateToLandscape,
                  icon: const Icon(
                    Icons.screen_rotation_alt_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

      body: SafeArea(
        child: Column(
          children: [
            // =========================================================
            // SEARCH
            // =========================================================
            if (isLandscape) _buildLandscapeSearchBar() else _buildSearchBox(),

            // =========================================================
            // TABLE
            // =========================================================
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // ---------------------------------------------------
                  // LANDSCAPE:
                  // 100% of available screen width
                  // 5 equal columns
                  // ---------------------------------------------------
                  final double columnWidth = isLandscape
                      ? constraints.maxWidth / 5
                      : _columnWidth;

                  final double tableWidth = columnWidth * 5;

                  // ---------------------------------------------------
                  // LANDSCAPE
                  // ---------------------------------------------------
                  if (isLandscape) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Column(
                        children: [
                          _buildTableHeader(columnWidth: columnWidth),

                          const SizedBox(height: 4),

                          Expanded(
                            child: _verbs.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                    controller: _scrollController,
                                    keyboardDismissBehavior:
                                        ScrollViewKeyboardDismissBehavior
                                            .onDrag,
                                    padding: const EdgeInsets.only(bottom: 20),
                                    itemCount:
                                        _verbs.length +
                                        (_isLoadingMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index >= _verbs.length) {
                                        return _buildBottomLoader();
                                      }

                                      return _buildVerbRow(
                                        _verbs[index],
                                        columnWidth: columnWidth,
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );
                  }

                  // ---------------------------------------------------
                  // PORTRAIT
                  // Horizontal scrolling remains enabled
                  // ---------------------------------------------------
                  return Scrollbar(
                    controller: _horizontalScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    scrollbarOrientation: ScrollbarOrientation.bottom,
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        height: constraints.maxHeight,
                        child: Column(
                          children: [
                            _buildTableHeader(columnWidth: columnWidth),

                            const SizedBox(height: 4),

                            Expanded(
                              child: _verbs.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                      controller: _scrollController,
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
                                      padding: const EdgeInsets.only(
                                        bottom: 20,
                                      ),
                                      itemCount:
                                          _verbs.length +
                                          (_isLoadingMore ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index >= _verbs.length) {
                                          return _buildBottomLoader();
                                        }

                                        return _buildVerbRow(
                                          _verbs[index],
                                          columnWidth: columnWidth,
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
