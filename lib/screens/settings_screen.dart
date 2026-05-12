import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/venue_service.dart';

/// Native settings / profile screen.
/// Provides account management including account deletion (Apple 5.1.1v).
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onSignOut;

  const SettingsScreen({super.key, this.onSignOut});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = '';
  String _userEmail = '';
  bool _isLoggedIn = false;
  String _selectedLang = 'TR';
  int _favoriteCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('auth_user_name') ?? '';
    final email = prefs.getString('auth_user_email') ?? '';
    final lang = prefs.getString('app_language')?.toUpperCase() ?? 'TR';
    final favorites = await VenueService.getFavorites();
    if (!mounted) return;
    setState(() {
      _userName = name;
      _userEmail = email;
      _isLoggedIn = name.isNotEmpty && email.isNotEmpty;
      _selectedLang = lang;
      _favoriteCount = favorites.length;
    });
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_user_name');
    await prefs.remove('auth_user_email');
    await prefs.remove('auth_apple_id');
    await prefs.setBool('welcome_seen', false);
    widget.onSignOut?.call();
  }

  Future<void> _deleteAccount() async {
    if (_userEmail.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Hesabı Sil',
          style: TextStyle(color: Color(0xFFe74c3c), fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu işlem geri alınamaz. Tüm verileriniz kalıcı olarak silinecektir:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text('• Hesap bilgileri', style: TextStyle(fontSize: 13)),
            const Text('• Yorumlar', style: TextStyle(fontSize: 13)),
            const Text('• Favoriler', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            Text(
              'Hesap: $_userEmail',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFe74c3c)),
            child: const Text('Kalıcı Olarak Sil', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF425921)),
      ),
    );

    final success = await VenueService.deleteAccount(_userEmail);

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading

    if (success) {
      // Clear local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_user_name');
      await prefs.remove('auth_user_email');
      await prefs.remove('auth_apple_id');
      await prefs.setBool('welcome_seen', false);
      // Clear favorites
      await prefs.remove('aramabul_favorites');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hesabınız başarıyla silindi.'),
          backgroundColor: Color(0xFF425921),
        ),
      );
      widget.onSignOut?.call();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Hesap silinemedi. Lütfen daha sonra tekrar deneyin.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _openUrl(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF729875),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            // Profile header
            _buildProfileCard(),
            const SizedBox(height: 16),

            // Quick stats
            _buildStatsRow(),
            const SizedBox(height: 16),

            // Language
            _buildSectionTitle('Dil / Language'),
            const SizedBox(height: 8),
            _buildLanguageSelector(),
            const SizedBox(height: 20),

            // App links
            _buildSectionTitle('Uygulama'),
            const SizedBox(height: 8),
            _buildSettingsTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Gizlilik Politikası',
              onTap: () => _openUrl('https://aramabul.com/gizlilik-politikasi.html'),
            ),
            _buildSettingsTile(
              icon: Icons.description_outlined,
              label: 'Kullanım Koşulları',
              onTap: () => _openUrl('https://aramabul.com/kullanim-kosullari.html'),
            ),
            _buildSettingsTile(
              icon: Icons.help_outline_rounded,
              label: 'Sıkça Sorulan Sorular',
              onTap: () => _openUrl('https://aramabul.com/sss.html'),
            ),
            _buildSettingsTile(
              icon: Icons.info_outline_rounded,
              label: 'Hakkımızda',
              onTap: () => _openUrl('https://aramabul.com/hakkimizda.html'),
            ),
            _buildSettingsTile(
              icon: Icons.email_outlined,
              label: 'İletişim',
              onTap: () => _openUrl('https://aramabul.com/iletisim.html'),
            ),

            // Version
            const SizedBox(height: 20),
            Center(
              child: Text(
                'AramaBul v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),

            // Sign out
            if (_isLoggedIn) ...[
              const SizedBox(height: 20),
              _buildSignOutButton(),
              const SizedBox(height: 12),
              _buildDeleteAccountButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final initial = _userName.isNotEmpty
        ? _userName[0].toUpperCase()
        : 'M';

    return Card(
      color: const Color(0xFFd5e8d3),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF425921),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLoggedIn ? _userName : 'Misafir',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1a1a1a),
                    ),
                  ),
                  if (_isLoggedIn)
                    Text(
                      _userEmail,
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF1a1a1a).withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.favorite_rounded,
            value: '$_favoriteCount',
            label: 'Favori',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.language_rounded,
            value: _selectedLang,
            label: 'Dil',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    const langs = ['TR', 'EN', 'DE', 'RU'];

    return Card(
      color: const Color(0xFFd5e8d3),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: langs.map((lang) {
            final isSelected = _selectedLang == lang;
            return Expanded(
              child: GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('app_language', lang.toLowerCase());
                  if (!mounted) return;
                  setState(() => _selectedLang = lang);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF425921) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      lang,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected ? Colors.white : const Color(0xFF1a1a1a),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFFd5e8d3),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF425921), size: 22),
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1a1a1a)),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: const Color(0xFF1a1a1a).withValues(alpha: 0.3),
          size: 20,
        ),
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Çıkış Yap'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _deleteAccount,
        icon: const Icon(Icons.delete_forever_rounded, size: 18),
        label: const Text('Hesabımı Sil'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFe74c3c),
          side: const BorderSide(color: Color(0xFFe74c3c)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFd5e8d3),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF425921), size: 20),
            const SizedBox(width: 8),
            Column(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1a1a1a),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF1a1a1a).withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
