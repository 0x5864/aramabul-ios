import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

import '../models/venue.dart';
import '../services/venue_service.dart';
import 'venue_detail_screen.dart';
import 'lezzet_duraklari_screen.dart';
import 'category_explore_screen.dart';

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
      final venues = await VenueService.fetchFeaturedVenues(limit: 15);
      if (!mounted) return;
      // Only venues with photos, shuffle and pick 3
      final withPhoto = venues.where((v) => v.imageUrl != null && v.imageUrl!.isNotEmpty).toList();
      withPhoto.shuffle();
      final picked = withPhoto.take(3).toList();
      setState(() {
        _venues = picked.isNotEmpty ? picked : VenueService.fallbackVenues.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _venues = VenueService.fallbackVenues;
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VenueDetailScreen(venue: venue)),
    );
  }

  String _calcDistance(Venue v) {
    if (_currentPosition == null || v.latitude == null || v.longitude == null) return '';
    final d = Geolocator.distanceBetween(
      _currentPosition!.latitude, _currentPosition!.longitude,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "İstanbul'u keşfet!",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: _onRefresh,
                  child: Image.asset('assets/welcome/refresh.png', width: 22, height: 22),
                ),
              ],
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

            // ── 5. Content Guide: Platform Rehberi ──
            const SizedBox(height: 14),
            _buildPlatformGuide(),

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
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1a1a1a),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Mehmet Yaşin ve Teoman Hünal — İstanbul Lezzet Durakları',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1a1a1a),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "İstanbul'un zengin mutfak kültürünü keşfetmek denildiğinde akla gelen ilk isimlerden ikisi, gastronomi yazarı Mehmet Yaşin ve The North Shield Pub zincirinin kurucusu, içki kültürü uzmanı Teoman Hünal'dır.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF1a1a1a).withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lezzet Duraklarını AramaBul ile Keşfet!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
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

  // ── Platform Guide ──
  Widget _buildPlatformGuide() {
    return Container(
      decoration: BoxDecoration(
        color: _kGuideBg,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "İstanbul'da aradığın her şey burada!",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1a1a1a),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Aramabul, İstanbul'daki 29 binden fazla mekanı tek bir noktada toplayan yerel mekan keşif platformudur. Kategoriler, kullanıcı ihtiyacına göre; yeme-içme, gezi, hizmet, sağlık, kültür ve sanat başlıkları altında oluşturulmuştur.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.6,
              color: const Color(0xFF1a1a1a).withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          _guideItem('Yeme-İçme', "İstanbul'un her köşesindeki restoranlar, meyhaneler, kafeler ve pastaneler gibi mekanları keşfedin."),
          _guideItem('Gezi', 'Oteller, butik oteller, pansiyonlar ve kamp alanları gibi seçenekleri inceleyin.'),
          _guideItem('Hizmetler', 'Kuaför, veteriner ve akaryakıt istasyonları gibi günlük yaşam hizmet noktalarını bulun.'),
          _guideItem('Sağlık', 'Hastaneler, aile sağlık merkezleri ve eczaneler gibi sağlık kuruluşlarına ulaşın.'),
          _guideItem('Kültür', 'Müzeler, tarihi camiler, saraylar ve arkeolojik alanları keşfedin.'),
          _guideItem('Sanat', 'Tiyatrolar, galeriler, konser salonları ve etkinlik mekanlarını listeleyin.'),
        ],
      ),
    );
  }

  Widget _guideItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: const Color(0xFF1a1a1a).withValues(alpha: 0.8)),
          children: [
            TextSpan(text: '$title ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: desc),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
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
                      iconColor: const Color(0xFF093826),
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
    } else if (venue.slug != null && venue.slug!.isNotEmpty) {
      url = 'https://aramabul.com/venue-photos/${venue.slug}.jpg';
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
    return Container(
      color: _kCatBg,
      child: Center(
        child: loading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54))
            : Icon(_categoryIcon(), size: 40, color: Colors.white38),
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
          fontSize: 12,
          fontWeight: FontWeight.w600,
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
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
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
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF093826),
            ),
          ),
        ],
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
    if (widget.currentPosition == null || v.latitude == null || v.longitude == null) return '';
    final d = Geolocator.distanceBetween(
      widget.currentPosition!.latitude, widget.currentPosition!.longitude,
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
        title: Text(widget.category, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
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
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
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
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => VenueDetailScreen(venue: v)),
                      ),
                    );
                  },
                ),
    );
  }
}
