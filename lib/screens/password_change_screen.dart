import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/venue_service.dart';

/// Şifre değişikliği ekranı — API üzerinden e-posta gönderir
class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({super.key});

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  bool _sending = false;
  bool _sent = false;

  Future<void> _sendResetEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('auth_user_email') ?? '';

    if (email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce giriş yapmanız gerekmektedir.'),
          backgroundColor: Color(0xFF094174),
        ),
      );
      return;
    }

    setState(() => _sending = true);

    final success = await VenueService.sendPasswordReset(email);

    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Şifre değişikliği e-postası $email adresine gönderildi.'
            : 'E-posta gönderilemedi. Lütfen tekrar deneyin.'),
        backgroundColor: success ? const Color(0xFF094174) : const Color(0xFFe74c3c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF094174),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Şifre değişikliği',
                      style: TextStyle(fontSize: 14, color: Color(0xFF1a1a1a))),
                  const SizedBox(height: 6),
                  Text(
                    'Önce e-posta bağlantısı al, bağlantıdan açılan ekranda yeni şifreni belirle.',
                    style: TextStyle(fontSize: 14, color: const Color(0xFF1a1a1a).withValues(alpha: 0.55), height: 1.5),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_sending || _sent) ? null : _sendResetEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF094174),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF094174).withValues(alpha: 0.5),
                        disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: _sending
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              _sent ? 'E-posta gönderildi ✓' : 'Şifre değişikliği e-postası gönder',
                              style: const TextStyle(fontSize: 14, ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Text(
                    'E-posta bağlantısı 20 dakika boyunca geçerlidir.',
                    style: TextStyle(fontSize: 14, color: const Color(0xFF1a1a1a).withValues(alpha: 0.45)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
