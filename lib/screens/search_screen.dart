import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/venue.dart';
import '../services/venue_service.dart';
import 'venue_detail_screen.dart';

// ─── Colors matching WebView ──────────────────────────────
const _kBg = Color(0xFF094174);
const _kCardBg = Color(0xFFbdd8e9);
const _kChipBg = Color(0xFFFDF8F0);
const _kChipBorder = Color(0xFF7bbce8);
const _kBtnDark = Color(0xFF011e3a);

/// Native search screen — matches the Android WebView design.
/// Simple search bar + "Bul" button, then venue cards.
class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Venue> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialQuery!);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
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

    try {
      final venues = await VenueService.searchVenues(query: query.trim(), limit: 30);
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

  void _openVenueDetail(Venue venue) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VenueDetailScreen(venue: venue)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => setState(() { _results = []; _hasSearched = false; _searchController.clear(); }),
                    child: Image.asset('assets/welcome/refresh.png', width: 22, height: 22),
                  ),
                ],
              ),
            ),

            // ── Search Bar (matching WebView: "Ne bulmamı istersin?" + "Bul") ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  // Text field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        onSubmitted: _performSearch,
                        textInputAction: TextInputAction.search,
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, color: const Color(0xFF1a1a1a)),
                        decoration: InputDecoration(
                          hintText: 'Ne bulmamı istersin?',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF1a1a1a).withValues(alpha: 0.4),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: Color(0xFF094174)),
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
                        ),
                        onChanged: (v) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // "Bul" button
                  GestureDetector(
                    onTap: () => _performSearch(_searchController.text),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      decoration: BoxDecoration(
                        color: _kBtnDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Bul',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Results ──
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator(color: _kChipBorder, strokeWidth: 2.5))
                  : _hasSearched
                      ? _buildResults()
                      : const SizedBox.shrink(), // Empty like WebView
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.white.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Sonuç bulunamadı',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 8),
            Text(
              'Farklı bir arama terimi deneyin.',
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final venue = _results[i];
        return _SearchResultCard(venue: venue, onTap: () => _openVenueDetail(venue));
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Search result card — matching the venue card design
// ═══════════════════════════════════════════════════════════════════════════

class _SearchResultCard extends StatelessWidget {
  final Venue venue;
  final VoidCallback onTap;
  const _SearchResultCard({required this.venue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kCardBg,
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
                child: _buildImage(),
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
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1a1a1a)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [venue.category, venue.district, venue.city]
                        .where((s) => s != null && s.isNotEmpty)
                        .join(' · '),
                    style: TextStyle(fontSize: 12, color: const Color(0xFF1a1a1a).withValues(alpha: 0.5)),
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
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1a1a1a)),
                        ),
                        if (venue.reviewCount != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${venue.reviewCount})',
                            style: TextStyle(fontSize: 11, color: const Color(0xFF1a1a1a).withValues(alpha: 0.4)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF094174), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    String? url;
    if (venue.imageUrl != null && venue.imageUrl!.isNotEmpty) {
      url = venue.imageUrl!.startsWith('http') ? venue.imageUrl! : 'https://aramabul.com${venue.imageUrl!}';
    }
    if (url != null) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF094174).withValues(alpha: 0.3),
      child: const Icon(Icons.place_rounded, color: Color(0xFF094174), size: 28),
    );
  }
}
