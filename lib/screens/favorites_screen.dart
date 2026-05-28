import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../models/venue.dart';
import '../services/venue_service.dart';
import 'venue_detail_screen.dart';

/// Native favorites screen — shows locally saved venues.
/// Works fully offline, providing value beyond the WebView.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Venue> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final faves = await VenueService.getFavorites();
    if (!mounted) return;
    setState(() {
      _favorites = faves;
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(Venue venue) async {
    HapticFeedback.mediumImpact();
    await VenueService.removeFavorite(venue.id);
    await _loadFavorites();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${venue.name} favorilerden kaldırıldı'),
        backgroundColor: const Color(0xFF094174),
        action: SnackBarAction(
          label: 'Geri Al',
          textColor: Colors.white,
          onPressed: () async {
            await VenueService.addFavorite(venue);
            await _loadFavorites();
          },
        ),
      ),
    );
  }

  void _openVenueDetail(Venue venue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VenueDetailScreen(venue: venue),
      ),
    ).then((_) => _loadFavorites()); // refresh in case favorite was toggled
  }

  void _shareVenue(Venue venue) {
    final slug = venue.slug ?? '';
    final url = slug.isNotEmpty
        ? 'https://aramabul.com/mekan/$slug'
        : venue.mapsUrl ?? 'https://aramabul.com';
    Share.share('${venue.name} — $url');
  }

  void _callVenue(Venue venue) {
    if (venue.phone != null && venue.phone!.isNotEmpty) {
      launchUrl(Uri.parse('tel:${venue.phone}'));
    }
  }

  void _openDirections(Venue venue) {
    if (venue.latitude == null || venue.longitude == null) {
      if (venue.mapsUrl != null && venue.mapsUrl!.isNotEmpty) {
        launchUrl(Uri.parse(venue.mapsUrl!), mode: LaunchMode.externalApplication);
      }
      return;
    }
    final lat = venue.latitude!;
    final lng = venue.longitude!;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0d2137),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Yol Tarifi',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.map_rounded, color: Colors.white),
                title: const Text('Apple Haritalar', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  launchUrl(Uri.parse('https://maps.apple.com/?daddr=$lat,$lng'),
                      mode: LaunchMode.externalApplication);
                },
              ),
              ListTile(
                leading: const Icon(Icons.directions_rounded, color: Colors.white),
                title: const Text('Google Maps', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
                      mode: LaunchMode.externalApplication);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF094174),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Anasayfa  /  Favorilerim',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  GestureDetector(
                    onTap: _loadFavorites,
                    child: Image.asset('assets/welcome/refresh.png', width: 22, height: 22),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _favorites.isEmpty
                      ? _buildEmptyState()
                      : _buildFavoritesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Favori mekanların\nburada görünecek',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Yeme-İçme ekranından mekan\nkaydetmeye başlayabilirsin.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return RefreshIndicator(
      color: const Color(0xFF094174),
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final venue = _favorites[index];
          return Dismissible(
            key: ValueKey(venue.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFe74c3c),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                  SizedBox(height: 4),
                  Text(
                    'Sil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              return true;
            },
            onDismissed: (direction) {
              _removeFavorite(venue);
            },
            child: _FavoriteCard(
              venue: venue,
              onRemove: () => _removeFavorite(venue),
              onTap: () => _openVenueDetail(venue),
              onShare: () => _shareVenue(venue),
              onCall: venue.phone != null && venue.phone!.isNotEmpty
                  ? () => _callVenue(venue)
                  : null,
              onDirections: () => _openDirections(venue),
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final Venue venue;
  final VoidCallback onRemove;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback? onCall;
  final VoidCallback onDirections;

  const _FavoriteCard({
    required this.venue,
    required this.onRemove,
    required this.onTap,
    required this.onShare,
    this.onCall,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFFbdd8e9),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image/icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF094174).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: venue.imageUrl != null && venue.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              venue.imageUrl!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.place_rounded,
                                color: Color(0xFF094174),
                                size: 28,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.place_rounded,
                            color: Color(0xFF094174),
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Text info
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (venue.district != null || venue.city != null)
                          Text(
                            [venue.district, venue.city]
                                .where((s) => s != null && s.isNotEmpty)
                                .join(', '),
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFF1a1a1a).withValues(alpha: 0.6),
                            ),
                          ),
                        if (venue.rating != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: Color(0xFFf59e0b)),
                              const SizedBox(width: 3),
                              Text(
                                venue.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1a1a1a),
                                ),
                              ),
                              if (venue.reviewCount != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(${venue.reviewCount})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFF1a1a1a).withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Remove button
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.favorite_rounded),
                    color: const Color(0xFFe74c3c),
                    iconSize: 22,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                    tooltip: 'Favorilerden kaldır',
                  ),
                ],
              ),

              // Quick actions
              const SizedBox(height: 10),
              Row(
                children: [
                  _QuickAction(
                    icon: Icons.directions_rounded,
                    label: 'Yol tarifi',
                    onTap: onDirections,
                  ),
                  if (onCall != null) ...[
                    const SizedBox(width: 8),
                    _QuickAction(
                      icon: Icons.phone_rounded,
                      label: 'Ara',
                      onTap: onCall!,
                    ),
                  ],
                  const SizedBox(width: 8),
                  _QuickAction(
                    icon: Icons.share_rounded,
                    label: 'Paylaş',
                    onTap: onShare,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF094174).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF094174)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF094174),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
