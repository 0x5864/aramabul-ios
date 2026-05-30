import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_review_helper.dart';

/// Shows a beautiful bottom sheet choice popup to let the user select
/// their preferred mapping application (Apple Maps or Google Maps).
void showMapsSheet(BuildContext context, {
  required double? lat,
  required double? lng,
  String? mapsUrl,
}) {
  HapticFeedback.mediumImpact();

  if (lat == null || lng == null) {
    if (mapsUrl != null && mapsUrl.trim().isNotEmpty) {
      try {
        launchUrl(Uri.parse(mapsUrl), mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
    return;
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext ctx) {
      return Container(
        decoration: const BoxDecoration(
          color: Color(0xFF092A4A), // Deep elegant dark blue matching the image perfectly
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top drag handle capsule
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Ayrıntılı Bilgi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            
            // Apple Haritalar Option
            _buildMapOption(
              ctx,
              label: 'Apple Haritalar',
              icon: Icons.map_outlined, // Folded map icon
              onTap: () {
                final uri = Uri.parse('https://maps.apple.com/?q=$lat,$lng');
                launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
            const SizedBox(height: 12),
            
            // Google Maps Option
            _buildMapOption(
              ctx,
              label: 'Google Haritalar',
              icon: Icons.near_me_outlined, // Navigation arrow
              onTap: () async {
                // Tier 1: Try launching the direct Google mapsUrl (like specific venue search or place link)
                if (mapsUrl != null && mapsUrl.trim().isNotEmpty) {
                  final uri = Uri.parse(mapsUrl.trim());
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                    return;
                  }
                }

                // Tier 2: Try launching native Google Maps app directly using URL scheme
                final nativeAppUri = Uri.parse('comgooglemaps://?q=$lat,$lng');
                if (await canLaunchUrl(nativeAppUri)) {
                  await launchUrl(nativeAppUri);
                } else {
                  // Tier 3: Universal Web fallback search query
                  final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                  await launchUrl(webUri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildMapOption(
  BuildContext context, {
  required String label,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(context);
        onTap();
        AppReviewHelper.recordSignificantAction();
      },
      borderRadius: BorderRadius.circular(12),
      hoverColor: Colors.white.withValues(alpha: 0.08),
      splashColor: Colors.white.withValues(alpha: 0.12),
      highlightColor: Colors.white.withValues(alpha: 0.08),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white10, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 20),
          ],
        ),
      ),
    ),
  );
}
