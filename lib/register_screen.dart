import 'package:flutter/material.dart';
import 'api_service.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tcCtrl = TextEditingController();
  final _adCtrl = TextEditingController();
  final _soyadCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();
  final _sifreConfCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final result = await ApiService.register(
        tcNo: _tcCtrl.text.trim(),
        ad: _adCtrl.text.trim(),
        soyad: _soyadCtrl.text.trim(),
        sifre: _sifreCtrl.text,
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        telefon: _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
      );
      if (result['success'] == true && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        _showSnack(result['error'] ?? 'Kayit basarisiz');
      }
    } catch (e) {
      _showSnack('Sunucuya baglanilamadi');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayit Ol')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.person_add, color: Colors.black, size: 30),
                ),
                const SizedBox(height: 24),
                Text('Yeni Hesap Olustur', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('10.000 TRY hosgeldin bakiyesi ile baslayin', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),
                _buildField(_tcCtrl, 'TC Kimlik No', Icons.badge_outlined, maxLen: 11, validator: (v) {
                  if (v == null || v.isEmpty) return 'TC No zorunlu';
                  if (v.length != 11) return 'TC No 11 hane olmali';
                  return null;
                }),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField(_adCtrl, 'Ad', Icons.person_outline, validator: (v) => v!.isEmpty ? 'Zorunlu' : null)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField(_soyadCtrl, 'Soyad', Icons.person_outline, validator: (v) => v!.isEmpty ? 'Zorunlu' : null)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildField(_emailCtrl, 'E-posta (opsiyonel)', Icons.email_outlined),
                const SizedBox(height: 12),
                _buildField(_telCtrl, 'Telefon (opsiyonel)', Icons.phone_outlined),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sifreCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Sifre',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Sifre zorunlu';
                    if (v.length < 6) return 'En az 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sifreConfCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Sifre Tekrar',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) {
                    if (v != _sifreCtrl.text) return 'Sifreler eslesmiyor';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('Hesap Olustur'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {int? maxLen, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      maxLength: maxLen,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), counterText: ''),
      validator: validator,
    );
  }
}
