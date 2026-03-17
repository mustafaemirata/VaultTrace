import 'package:flutter/material.dart';
import 'api_service.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _tcController = TextEditingController();
  final _sifreController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _tcController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_tcController.text.isEmpty || _sifreController.text.isEmpty) {
      _showSnack('TC No ve sifre zorunludur');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ApiService.login(
        tcNo: _tcController.text.trim(),
        sifre: _sifreController.text,
      );
      if (result['success'] == true) {
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      } else {
        _showSnack(result['error'] ?? 'Giris basarisiz');
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
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.account_balance, color: Colors.black, size: 44),
                ),
                const SizedBox(height: 24),
                Text('VaultTrace', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text('Guvenli Bankacilik', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 48),
                TextField(
                  controller: _tcController,
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  decoration: const InputDecoration(
                    labelText: 'TC Kimlik No',
                    prefixIcon: Icon(Icons.badge_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sifreController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Sifre',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('Giris Yap'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Hesabiniz yok mu? ',
                      style: TextStyle(color: Color(0xFF8A8FA8)),
                      children: [
                        TextSpan(text: 'Kayit Ol', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
