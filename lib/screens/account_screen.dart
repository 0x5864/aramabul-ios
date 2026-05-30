import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/venue_service.dart';

/// Hesap bilgileri ekranı — profil güncelleme + hesap silme
class AccountScreen extends StatefulWidget {
  final VoidCallback? onSignOut;
  const AccountScreen({super.key, this.onSignOut});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _originalName = '';
  String _originalEmail = '';
  bool _isLoggedIn = false;
  bool _isSaving = false;

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
      _originalName = name;
      _originalEmail = email;
      _nameController.text = name;
      _emailController.text = email;
      _isLoggedIn = name.isNotEmpty && email.isNotEmpty;
    });
  }

  Future<void> _save() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad Soyad boş bırakılamaz.'), backgroundColor: Color(0xFFe74c3c)),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user_name', newName);

    // Save to API
    await VenueService.updateProfile(
      email: _originalEmail,
      name: newName,
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _originalName = newName;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bilgiler kaydedildi.'), backgroundColor: Color(0xFF094174)),
    );
  }

  Future<void> _deleteAccount() async {
    if (_originalEmail.isEmpty || !_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hesabınızı silmek için önce giriş yapmanız gerekmektedir.'),
          backgroundColor: Color(0xFF094174),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabı Sil',
            style: TextStyle(color: Color(0xFFe74c3c), )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bu işlem geri alınamaz. Tüm verileriniz kalıcı olarak silinecektir:', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            const Text('• Hesap bilgileri', style: TextStyle(fontSize: 14)),
            const Text('• Yorumlar', style: TextStyle(fontSize: 14)),
            const Text('• Favoriler', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Text('Hesap: $_originalEmail',
                style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFe74c3c)),
            child: const Text('Kalıcı Olarak Sil', style: TextStyle()),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF094174))),
    );

    final success = await VenueService.deleteAccount(_originalEmail);
    if (!mounted) return;
    Navigator.of(context).pop();

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_user_name');
      await prefs.remove('auth_user_email');
      await prefs.remove('auth_apple_id');
      await prefs.setBool('welcome_seen', false);
      await prefs.remove('aramabul_favorites');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hesabınız başarıyla silindi.'), backgroundColor: Color(0xFF094174)),
      );
      widget.onSignOut?.call();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Hesap silinemedi. Lütfen tekrar deneyin.'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initial = _originalName.isNotEmpty ? _originalName[0].toUpperCase() : 'M';

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            // Profile header card
            Card(
              color: const Color(0xFFbdd8e9),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFc9a84c),
                      child: Text(initial,
                          style: const TextStyle(fontSize: 14, color: Colors.white)),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      _isLoggedIn ? _originalName : 'Misafir',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1a1a1a)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Account info form card
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hesap bilgileri',
                        style: TextStyle(fontSize: 14, color: Color(0xFF1a1a1a))),
                    const SizedBox(height: 4),
                    Text('Adını ve e-postanı burada güncelleyebilirsin.',
                        style: TextStyle(fontSize: 14, color: const Color(0xFF1a1a1a).withValues(alpha: 0.5))),
                    const SizedBox(height: 20),

                    Text('Ad Soyad',
                        style: TextStyle(fontSize: 14, color: const Color(0xFF1a1a1a).withValues(alpha: 0.6))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      decoration: _inputDecoration(),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1a1a1a)),
                    ),

                    const SizedBox(height: 16),

                    Text('E-posta',
                        style: TextStyle(fontSize: 14, color: const Color(0xFF1a1a1a).withValues(alpha: 0.6))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: _inputDecoration(),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1a1a1a)),
                    ),
                    const SizedBox(height: 6),
                    const Text('E-posta adresin doğrulandı.',
                        style: TextStyle(fontSize: 14, color: Color(0xFF2980b9))),

                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF094174),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF094174).withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Kaydet', style: TextStyle(fontSize: 14, )),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Divider(color: const Color(0xFF1a1a1a).withValues(alpha: 0.1)),
                    const SizedBox(height: 16),

                    const Text('Hesabımı Sil',
                        style: TextStyle(fontSize: 14, color: Color(0xFF1a1a1a))),
                    const SizedBox(height: 8),
                    Text(
                      'Hesabını kalıcı olarak silmek istiyorsan aşağıdaki butona bas. Bu işlem geri alınamaz.',
                      style: TextStyle(fontSize: 14, color: const Color(0xFF1a1a1a).withValues(alpha: 0.55), height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _deleteAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF094174),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Hesabımı Sil', style: TextStyle(fontSize: 14, )),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
