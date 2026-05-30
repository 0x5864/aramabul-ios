import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/venue.dart';
import '../services/venue_service.dart';
import 'venue_detail_screen.dart';
import 'lezzet_duraklari_screen.dart';
import 'category_explore_screen.dart';
import '../widgets/app_footer.dart';
import '../widgets/maps_sheet.dart';
import '../widgets/venue_dialog.dart';

// ─── Color constants (matching WebView CSS injection) ────────────────────
const _kBg = Color(0xFF094174);       // body background
const _kCardBg = Color(0xFFbdd8e9);   // venue card background
const _kChipBg = Color(0xFFFDF8F0);   // tag chip background (cream)
const _kChipBorder = Color(0xFF7bbce8); // tag chip border
const _kCatBg = Color(0xFF48769f);    // category button bg
const _kBtnDark = Color(0xFF011e3a);  // dark button bg
const _kGuideBg = Color(0xFFd7d7d7);  // content guide bg
const _kGuideHighlight = Color(0xFF7bbce8); // ustalara saygi bg

/// Native explore screen — pixel-perfect match of the Android WebView version.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Venue> _venues = [];
  bool _isLoading = true;
  Position? _currentPosition;

  // Top categories — exactly as shown in Android WebView
  static const List<String> _categories = [
    'Yeme-İçme', 'Gezi', 'Hizmetler',
    'Sağlık', 'Kültür', 'Sanat',
  ];

  @override
  void initState() {
    super.initState();
    _loadVenues();
    _getPosition();
  }

  Future<void> _getPosition() async {
    try {
      final status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
        // Reload venues with position for distance calculation
        if (mounted && _venues.isNotEmpty) setState(() {});
      }
    } catch (e) {
      debugPrint('[Explore] Position error: $e');
    }
  }

  Future<void> _loadVenues() async {
    setState(() => _isLoading = true);
    try {
      final venues = await VenueService.fetchFeaturedVenues(limit: 150);
      if (!mounted) return;
      
      // Shuffle all fetched venues
      var allVenues = List<Venue>.from(venues)..shuffle();
      
      // Filter only Yeme-İçme and Gezi categories AND ensure they have a photo
      final filteredVenues = allVenues.where((v) {
        final cat = v.category.toLowerCase();
        final hasPhoto = v.imageUrl != null && v.imageUrl!.isNotEmpty && v.imageUrl!.startsWith('http');
        final isCorrectCategory = cat == 'yeme-icme' || cat == 'gezi' || cat == 'restoran' || cat == 'kafe' || cat == 'bar' || cat == 'otel' || cat == 'yeme-içme';
        return isCorrectCategory && hasPhoto;
      }).toList();
      
      setState(() {
        _venues = filteredVenues.isNotEmpty 
            ? filteredVenues.take(3).toList() 
            : VenueService.fallbackVenues
                .where((v) {
                  final cat = v.category.toLowerCase();
                  final hasPhoto = v.imageUrl != null && v.imageUrl!.isNotEmpty && v.imageUrl!.startsWith('http');
                  final isCorrectCategory = cat == 'yeme-icme' || cat == 'gezi' || cat == 'restoran' || cat == 'kafe' || cat == 'bar' || cat == 'otel' || cat == 'yeme-içme';
                  return isCorrectCategory && hasPhoto;
                })
                .take(3)
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      var fallback = List<Venue>.from(VenueService.fallbackVenues)..shuffle();
      final filteredFallback = fallback.where((v) {
        final cat = v.category.toLowerCase();
        final hasPhoto = v.imageUrl != null && v.imageUrl!.isNotEmpty && v.imageUrl!.startsWith('http');
        final isCorrectCategory = cat == 'yeme-icme' || cat == 'gezi' || cat == 'restoran' || cat == 'kafe' || cat == 'bar' || cat == 'otel' || cat == 'yeme-içme';
        return isCorrectCategory && hasPhoto;
      }).toList();
      
      setState(() {
        _venues = filteredFallback.take(3).toList();
        _isLoading = false;
      });
    }
  }

  void _onCategoryTap(String category) {
    HapticFeedback.selectionClick();
    // Map display name to API key
    final keyMap = {
      'Yeme-İçme': 'yeme-icme',
      'Gezi': 'gezi',
      'Hizmetler': 'hizmetler',
      'Sağlık': 'saglik',
      'Kültür': 'kultur',
      'Sanat': 'sanat',
    };
    final key = keyMap[category] ?? category.toLowerCase();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryExploreScreen(
          mainCategoryKey: key,
          mainCategoryTitle: category,
        ),
      ),
    );
  }

  void _openVenueDetail(Venue venue) {
    showVenuePopup(context, venue);
  }

  String _calcDistance(Venue v) {
    if (v.latitude == null || v.longitude == null) return '';
    final lat = _currentPosition?.latitude ?? 41.0370;
    final lng = _currentPosition?.longitude ?? 28.9850;
    final d = Geolocator.distanceBetween(
      lat, lng,
      v.latitude!, v.longitude!,
    );
    if (d > 100000) return '';
    if (d < 1000) return '${d.toStringAsFixed(0)} m';
    return '${(d / 1000).toStringAsFixed(1)} km';
  }

  Future<void> _onRefresh() async {
    await _loadVenues();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: RefreshIndicator(
        color: _kChipBorder,
        onRefresh: _onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            // ── 1. Header ──
            Text(
              "İstanbul'u keşfet!",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),

            // ── 2. Category Grid (3x2) ──
            _buildCategoryGrid(),
            const SizedBox(height: 16),

            // ── 3. Venue Cards ──
            if (_isLoading)
              ..._buildShimmerCards()
            else
              ..._venues.map((v) => _VenueCard(
                venue: v,
                distance: _calcDistance(v),
                onTap: () => _openVenueDetail(v),
              )),

            // ── 4. Content Guide: Ustalara Saygı ──
            const SizedBox(height: 16),
            _buildUstalaraSaygi(),

            const SizedBox(height: 14),
            const AppFooter(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Category Grid ──
  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.8,
      ),
      itemCount: _categories.length,
      itemBuilder: (_, i) {
        return GestureDetector(
          onTap: () => _onCategoryTap(_categories[i]),
          child: Container(
            decoration: BoxDecoration(
              color: _kCatBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _categories[i],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Shimmer ──
  List<Widget> _buildShimmerCards() {
    return List.generate(3, (_) => Container(
      height: 320,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kCardBg.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
      ),
    ));
  }

  // ── Ustalara Saygı ──
  Widget _buildUstalaraSaygi() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LezzetDuraklariScreen()),
      ),
      child: Container(
      decoration: BoxDecoration(
        color: _kGuideHighlight,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ustalara saygı!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1a1a1a),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Mehmet Yaşin ve Teoman Hünal — İstanbul Lezzet Durakları',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1a1a1a),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "İstanbul'un zengin mutfak kültürünü keşfetmek denildiğinde akla gelen ilk isimlerden ikisi, gastronomi yazarı Mehmet Yaşin ve The North Shield Pub zincirinin kurucusu, içki kültürü uzmanı Teoman Hünal'dır.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF1a1a1a).withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lezzet Duraklarını AramaBul ile Keşfet!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF1a1a1a),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              'https://aramabul.com/assets/gorevimiz-yemek.jpg',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: _kCatBg,
                child: const Center(child: Icon(Icons.image, size: 40, color: Colors.white54)),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Venue Card — exact match of Android WebView design
// ═══════════════════════════════════════════════════════════════════════════

class _VenueCard extends StatelessWidget {
  final Venue venue;
  final String distance;
  final VoidCallback onTap;
  const _VenueCard({required this.venue, required this.distance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo ──
            SizedBox(
              height: 200,
              width: double.infinity,
              child: _buildImage(),
            ),

            // ── Venue Name ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Text(
                venue.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1a1a1a),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ── Tag chips row (district, neighborhood, category) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (venue.district != null && venue.district!.isNotEmpty)
                    _TagChip(venue.district!),
                  if (venue.subcategory != null && venue.subcategory!.isNotEmpty)
                    _TagChip(venue.subcategory!),
                  _TagChip(venue.category),
                ],
              ),
            ),

            // ── Bottom info row (budget, distance, rating) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  // Budget chip
                  _InfoImageChip(assetPath: 'assets/cuzdan.png', label: _budgetLabel(venue)),
                  // Distance chip
                  if (distance.isNotEmpty)
                    _InfoImageChip(assetPath: 'assets/uzak.png', label: distance),
                  // Rating chip
                  if (venue.rating != null)
                    _InfoChip(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFf59e0b),
                      label: '${venue.rating!.toStringAsFixed(1)}${venue.reviewCount != null ? ' (${_formatCount(venue.reviewCount!)})' : ''}',
                    ),
                ],
              ),
            ),
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
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _imagePlaceholder(loading: true);
        },
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder({bool loading = false}) {
    if (loading) {
      return Container(
        color: _kCatBg,
        child: const Center(
          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
        ),
      );
    }
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Image.asset(
          'assets/no_image.png',
          width: 48,
          height: 48,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  IconData _categoryIcon() {
    switch (venue.category.toLowerCase()) {
      case 'restoran': case 'yeme-içme': return Icons.restaurant_rounded;
      case 'kafe': return Icons.coffee_rounded;
      case 'bar': return Icons.local_bar_rounded;
      case 'otel': return Icons.hotel_rounded;
      case 'müze': case 'kültür': return Icons.museum_rounded;
      default: return Icons.place_rounded;
    }
  }

  String _formatCount(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}B' : n.toString();

  String _budgetLabel(Venue venue) {
    switch (venue.budget) {
      case 'low': return 'Uygun';
      case 'mid': return 'Makul';
      case 'high': return 'Yüksek';
      default: return 'Makul';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tag Chip — cream background with blue border (exactly like WebView)
// ═══════════════════════════════════════════════════════════════════════════

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _kChipBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kChipBorder, width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: const Color(0xFF093826),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Info Chip — with icon (budget, distance, rating)
// ═══════════════════════════════════════════════════════════════════════════

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  const _InfoChip({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kChipBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kChipBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? const Color(0xFF093826)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF093826),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoImageChip extends StatelessWidget {
  final String assetPath;
  final String label;
  const _InfoImageChip({required this.assetPath, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kChipBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kChipBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(assetPath, width: 16, height: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF093826),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Haritalarda Aç Chip — customized Google Maps blue color (#1a73e7)
// ═══════════════════════════════════════════════════════════════════════════

class _MapsChip extends StatelessWidget {
  final VoidCallback onTap;
  const _MapsChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE8FDF0), // soft green background
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFB5F4CD), width: 0.8), // light green border
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/welcome/detail.png', width: 16, height: 16),
            const SizedBox(width: 5),
            Text(
              'Ayrıntılı Bilgi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF0D8A43), // emerald green text
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Category Results Page — opens when a category is tapped
// ═══════════════════════════════════════════════════════════════════════════

class _CategoryResultsPage extends StatefulWidget {
  final String category;
  final Position? currentPosition;
  const _CategoryResultsPage({required this.category, this.currentPosition});

  @override
  State<_CategoryResultsPage> createState() => _CategoryResultsPageState();
}

class _CategoryResultsPageState extends State<_CategoryResultsPage> {
  List<Venue> _venues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final venues = await VenueService.searchVenues(query: widget.category, limit: 20);
      if (!mounted) return;
      setState(() {
        _venues = venues;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _calcDistance(Venue v) {
    if (v.latitude == null || v.longitude == null) return '';
    final lat = widget.currentPosition?.latitude ?? 41.0370;
    final lng = widget.currentPosition?.longitude ?? 28.9850;
    final d = Geolocator.distanceBetween(
      lat, lng,
      v.latitude!, v.longitude!,
    );
    if (d > 100000) return '';
    if (d < 1000) return '${d.toStringAsFixed(0)} m';
    return '${(d / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(widget.category, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: _kBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kChipBorder))
          : _venues.isEmpty
              ? Center(
                  child: Text(
                    'Bu kategoride mekan bulunamadı',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: _venues.length,
                  itemBuilder: (_, i) {
                    final v = _venues[i];
                    return _VenueCard(
                      venue: v,
                      distance: _calcDistance(v),
                      onTap: () => showVenuePopup(context, v),
                    );
                  },
                ),
    );
  }
}
