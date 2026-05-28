import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account_screen.dart';
import 'password_change_screen.dart';
import 'feedback_screen.dart';
import 'help_screen.dart';
import 'admin_login_screen.dart';
import 'about_screen.dart';

/// Native settings / profile screen.
/// Provides account management including account deletion (Apple 5.1.1v).
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onSignOut;

  const SettingsScreen({super.key, this.onSignOut});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('auth_user_name') ?? '';
    final email = prefs.getString('auth_user_email') ?? '';
    if (!mounted) return;
    setState(() {
      _isLoggedIn = name.isNotEmpty && email.isNotEmpty;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF094174),
      body: SafeArea(
        child: Column(
          children: [
            // Refresh icon
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => setState(() {}),
                    child: Image.asset('assets/welcome/refresh.png', width: 22, height: 22),
                  ),
                ],
              ),
            ),
            // Menu card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _menuRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Hesap',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AccountScreen(onSignOut: widget.onSignOut),
                        ),
                      ),
                    ),
                    _divider(),
                    _menuRow(
                      icon: Icons.lock_outline_rounded,
                      label: 'Şifre Değişikliği',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PasswordChangeScreen(),
                        ),
                      ),
                    ),
                    _divider(),
                    _menuRow(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Geribildirim',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FeedbackScreen(),
                        ),
                      ),
                    ),
                    _divider(),
                    _menuRow(
                      icon: Icons.help_outline_rounded,
                      label: 'Yardım',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpScreen()),
                      ),
                    ),
                    _divider(),
                    _menuRow(
                      icon: Icons.info_outline_rounded,
                      label: 'Hakkında',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      ),
                    ),
                    _divider(),
                    _menuRow(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Admin Girişi',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Çıkış yap button
            if (_isLoggedIn)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _signOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF094174),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Çıkış yap',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF094174)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1a1a1a),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: const Color(0xFF1a1a1a).withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: const Color(0xFF1a1a1a).withValues(alpha: 0.1),
      indent: 52,
    );
  }
}
