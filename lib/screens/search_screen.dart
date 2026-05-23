import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/venue.dart';
import '../services/venue_service.dart';
import 'venue_detail_screen.dart';

/// Native search screen with real-time search, search history,
/// and category filtering. Provides native search experience
/// to satisfy Apple Guideline 4.2.2.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Venue> _results = [];
  List<String> _searchHistory = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _selectedCategoryFilter = '';

  static const List<String> _suggestedSearches = [
    'En iyi restoranlar',
    'Kadıköy kafe',
    'Beşiktaş bar',
    'Taksim gece hayatı',
    'Beyoğlu restoran',
    'Karaköy brunch',
    'Üsküdar kahvaltı',
    'Bebek sahil',
  ];

  static const List<String> _categoryFilters = [
    'Tümü',
    'Restoran',
    'Kafe',
    'Bar',
    'Otel',
    'Gece Hayatı',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await VenueService.getSearchHistory();
    if (!mounted) return;
    setState(() => _searchHistory = history);
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    HapticFeedback.selectionClick();
    _focusNode.unfocus();
    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    // Save to history
    await VenueService.addSearchHistory(query.trim());
    await _loadHistory();

    try {
      final category = _selectedCategoryFilter == 'Tümü' || _selectedCategoryFilter.isEmpty
          ? null
          : _selectedCategoryFilter;
      final venues = await VenueService.searchVenues(
        query: query.trim(),
        category: category,
        limit: 30,
      );
      if (!mounted) return;
      setState(() {
        _results = venues;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('[Search] Error: $e');
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  void _onSuggestionTap(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  void _clearHistory() async {
    await VenueService.clearSearchHistory();
    await _loadHistory();
  }

  void _removeHistoryItem(String item) async {
    await VenueService.removeSearchHistoryItem(item);
    await _loadHistory();
  }

  void _openVenueDetail(Venue venue) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VenueDetailScreen(venue: venue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF45503f),
      appBar: AppBar(
        backgroundColor: const Color(0xFF45503f),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mekan Ara',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),

          // Category filters
          _buildCategoryFilters(),

          // Content
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _hasSearched
                    ? _buildResults()
                    : _buildSuggestions(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFd5e8d3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onSubmitted: _performSearch,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1a1a1a)),
          decoration: InputDecoration(
            hintText: 'Mekan, kategori veya ilçe ara...',
            hintStyle: TextStyle(
              color: const Color(0xFF1a1a1a).withValues(alpha: 0.4),
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF2d6b3f),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Color(0xFF2d6b3f)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _results = [];
                        _hasSearched = false;
                      });
                      _focusNode.requestFocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categoryFilters.length,
        itemBuilder: (context, index) {
          final cat = _categoryFilters[index];
          final isSelected = _selectedCategoryFilter == cat ||
              (_selectedCategoryFilter.isEmpty && cat == 'Tümü');
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategoryFilter = cat);
                if (_hasSearched && _searchController.text.isNotEmpty) {
                  _performSearch(_searchController.text);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2d6b3f)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestions() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      children: [
        // Search history
        if (_searchHistory.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.history_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Son Aramalar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _clearHistory,
                child: Text(
                  'Temizle',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(_searchHistory.length, (index) {
            final item = _searchHistory[index];
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.history_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 20,
              ),
              title: Text(
                item,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              trailing: GestureDetector(
                onTap: () => _removeHistoryItem(item),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 18,
                ),
              ),
              onTap: () => _onSuggestionTap(item),
            );
          }),
          const SizedBox(height: 24),
        ],

        // Suggested searches
        const Row(
          children: [
            Icon(Icons.explore_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Popüler Aramalar',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestedSearches.map((query) {
            return GestureDetector(
              onTap: () => _onSuggestionTap(query),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFd5e8d3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  query,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1a1a1a),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Sonuç bulunamadı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Farklı bir arama terimi deneyin.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: _results.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${_results.length} sonuç bulundu',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          );
        }
        final venue = _results[index - 1];
        return _SearchResultCard(
          venue: venue,
          onTap: () => _openVenueDetail(venue),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Search result card
// ---------------------------------------------------------------------------

class _SearchResultCard extends StatelessWidget {
  final Venue venue;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.venue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFd5e8d3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 60,
                height: 60,
                child: venue.imageUrl != null && venue.imageUrl!.isNotEmpty
                    ? Image.network(
                        venue.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF45503f).withValues(alpha: 0.3),
                          child: const Icon(Icons.place_rounded,
                              color: Color(0xFF2d6b3f), size: 28),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF45503f).withValues(alpha: 0.3),
                        child: const Icon(Icons.place_rounded,
                            color: Color(0xFF2d6b3f), size: 28),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a1a1a),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [venue.category, venue.district, venue.city]
                        .where((s) => s != null && s.isNotEmpty)
                        .join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF1a1a1a).withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                  ),
                  if (venue.rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFf59e0b)),
                        const SizedBox(width: 3),
                        Text(
                          venue.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1a1a1a),
                          ),
                        ),
                        if (venue.reviewCount != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${venue.reviewCount})',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF1a1a1a).withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF2d6b3f),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
