import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/venue_service.dart';

/// Admin Girişi ekranı — API ile doğrulama
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun.'), backgroundColor: Color(0xFFe74c3c)),
      );
      return;
    }

    setState(() => _loading = true);

    final result = await VenueService.adminLogin(email: email, password: password);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giriş başarılı! Yönetim paneli açılıyor...'), backgroundColor: Color(0xFF094174)),
      );
      // Open admin panel in browser
      await Future.delayed(const Duration(milliseconds: 500));
      launchUrl(
        Uri.parse('https://aramabul.com/admin'),
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giriş başarısız. E-posta veya şifre hatalı.'), backgroundColor: Color(0xFFe74c3c)),
      );
    }
  }

  void _forgotPassword() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      VenueService.sendPasswordReset(email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şifre sıfırlama bağlantısı $email adresine gönderildi.'),
            backgroundColor: const Color(0xFF094174)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce e-posta adresinizi girin.'), backgroundColor: Color(0xFFe74c3c)),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                  Text('YÖNETİM GİRİŞİ',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF094174),
                        letterSpacing: 1,
                      )),
                  const SizedBox(height: 8),
                  const Text('Admin oturumu aç',
                      style: TextStyle(fontSize: 14, color: Color(0xFF1a1a1a))),
                  const SizedBox(height: 8),
                  Text(
                    'Yalnızca yönetici hesabı ile devam edebilirsin. Şifre sıfırlama bağlantısı e-posta ile gelir.',
                    style: TextStyle(fontSize: 14, color: const Color(0xFF1a1a1a).withValues(alpha: 0.55), height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  const Text('E-posta',
                      style: TextStyle(fontSize: 14, color: Color(0xFF1a1a1a))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF1a1a1a)),
                  ),

                  const SizedBox(height: 20),

                  const Text('Şifre',
                      style: TextStyle(fontSize: 14, color: Color(0xFF1a1a1a))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: _inputDecoration(),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF1a1a1a)),
                          onSubmitted: (_) => _login(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1a1a1a),
                          side: BorderSide(color: const Color(0xFF1a1a1a).withValues(alpha: 0.2)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(_obscurePassword ? 'Göster' : 'Gizle', style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF094174),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF094174).withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Giriş yap', style: TextStyle(fontSize: 14, )),
                    ),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton(
                    onPressed: _forgotPassword,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1a1a1a),
                      side: BorderSide(color: const Color(0xFF1a1a1a).withValues(alpha: 0.2)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Şifremi unuttum', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: const Color(0xFF1a1a1a).withValues(alpha: 0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: const Color(0xFF1a1a1a).withValues(alpha: 0.15)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
