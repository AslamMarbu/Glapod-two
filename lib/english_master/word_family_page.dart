import 'package:flutter/material.dart';
import '../widgets.dart/appbar_page.dart';

class WordFamilyPage extends StatefulWidget {
  const WordFamilyPage({super.key});

  @override
  State<WordFamilyPage> createState() => _WordFamilyPageState();
}

class _WordFamilyPageState extends State<WordFamilyPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  final List<Map<String, String>> wordFamilies = [
    {
      'headword': 'CREATE',
      'verb': 'create',
      'noun': 'creation',
      'adjective': 'creative',
      'adverb': 'creatively',
    },
    {
      'headword': 'BEAUTY',
      'verb': 'beautify',
      'noun': 'beauty',
      'adjective': 'beautiful',
      'adverb': 'beautifully',
    },
    {
      'headword': 'SUCCESS',
      'verb': 'succeed',
      'noun': 'success',
      'adjective': 'successful',
      'adverb': 'successfully',
    },
    {
      'headword': 'ACT',
      'verb': 'act',
      'noun': 'action',
      'adjective': 'active',
      'adverb': 'actively',
    },
    {
      'headword': 'CARE',
      'verb': 'care',
      'noun': 'care',
      'adjective': 'careful',
      'adverb': 'carefully',
    },
    {
      'headword': 'DIFFER',
      'verb': 'differ',
      'noun': 'difference',
      'adjective': 'different',
      'adverb': 'differently',
    },
    {
      'headword': 'EDUCATE',
      'verb': 'educate',
      'noun': 'education',
      'adjective': 'educational',
      'adverb': 'educationally',
    },
    {
      'headword': 'BEAUTIFY',
      'verb': 'beautify',
      'noun': 'beautification',
      'adjective': 'beautiful',
      'adverb': 'beautifully',
    },
    {
      'headword': 'INFORM',
      'verb': 'inform',
      'noun': 'information',
      'adjective': 'informative',
      'adverb': 'informatively',
    },
    {
      'headword': 'DECIDE',
      'verb': 'decide',
      'noun': 'decision',
      'adjective': 'decisive',
      'adverb': 'decisively',
    },
    {
      'headword': 'ACTUAL',
      'verb': 'actualize',
      'noun': 'actuality',
      'adjective': 'actual',
      'adverb': 'actually',
    },
    {
      'headword': 'DIFFERENCE',
      'verb': 'differentiate',
      'noun': 'difference',
      'adjective': 'different',
      'adverb': 'differently',
    },
  ];

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get filteredWordFamilies {
    if (_searchText.isEmpty) {
      return wordFamilies;
    }

    return wordFamilies.where((family) {
      return (family['headword'] ?? '').toLowerCase().contains(_searchText) ||
          (family['verb'] ?? '').toLowerCase().contains(_searchText) ||
          (family['noun'] ?? '').toLowerCase().contains(_searchText) ||
          (family['adjective'] ?? '').toLowerCase().contains(_searchText) ||
          (family['adverb'] ?? '').toLowerCase().contains(_searchText);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = filteredWordFamilies;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: const CustomAppBar(height: 70, title: 'Word Family'),

      body: Column(
        children: [
          // ------------------------------------------------
          // SEARCH
          // ------------------------------------------------
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
                          onPressed: () {
                            _searchController.clear();
                          },
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

          // ------------------------------------------------
          // WORD FAMILY LIST
          // ------------------------------------------------
          Expanded(
            child: data.isEmpty
                ? _buildNoResults()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return _buildFamilyCard(data[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // FAMILY CARD
  // ======================================================

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
          // ------------------------------------------------
          // HEADWORD HEADER
          // ------------------------------------------------
          Container(
            width: double.infinity,

            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),

            decoration: const BoxDecoration(
              // NEW COLOR
              gradient: LinearGradient(
                colors: [Color(0xFF00897B), Color(0xFF26A69A)],

                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),

              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),

            child: Row(
              children: [
                // ICON
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

                // HEADWORD
                Expanded(
                  child: Text(
                    family['headword'] ?? '',

                    style: const TextStyle(
                      fontSize: 16, // REDUCED
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------
          // WORDS
          // ------------------------------------------------
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

  // ======================================================
  // WORD ROW
  // ======================================================

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
        // ICON
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

        // TYPE
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

        // WORD
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

  // ======================================================
  // DIVIDER
  // ======================================================

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 9),

      child: Divider(height: 1, thickness: 0.7, color: Color(0xFFE8ECF1)),
    );
  }

  // ======================================================
  // NO RESULTS
  // ======================================================

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
