import 'package:flutter/material.dart';
import 'api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<dynamic> _accounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accs = await ApiService.getAccounts();
      if (mounted) setState(() { _accounts = accs; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  void _logout() {
    ApiService.setToken('');
    ApiService.currentUser = null;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundColor: Color(0xFF121212), child: Icon(Icons.person, size: 60, color: Colors.white)),
            const SizedBox(height: 16),
            Text('${user?['ad'] ?? ''} ${user?['soyad'] ?? ''}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('TC No: ${user?['tc_no'] ?? ''}', style: const TextStyle(color: Color(0xFF8A8FA8))),
            const SizedBox(height: 32),
            _buildInfoTile(Icons.email_outlined, 'E-posta', user?['email'] ?? 'Tanimlanmamis'),
            _buildInfoTile(Icons.phone_outlined, 'Telefon', user?['telefon'] ?? 'Tanimlanmamis'),
            const SizedBox(height: 32),
            const Align(alignment: Alignment.centerLeft, child: Text('Hesaplarim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
            const SizedBox(height: 12),
            if (_loading) const CircularProgressIndicator(color: Colors.white)
            else ..._accounts.map((a) => _buildAccTile(a)).toList(),
            const SizedBox(height: 48),
            SizedBox(width: double.infinity, height: 54, child: OutlinedButton.icon(onPressed: _logout, icon: const Icon(Icons.logout, color: Colors.white), label: const Text('Cikis Yap', style: TextStyle(color: Colors.white)), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)))),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String val) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF333333))),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF8A8FA8), size: 22),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA8))),
          Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ]),
      ]),
    );
  }

  Widget _buildAccTile(Map<String, dynamic> acc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF333333))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(acc['hesap_no'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text(acc['iban'] ?? '', style: const TextStyle(color: Color(0xFF8A8FA8), fontSize: 11)),
        ]),
        Text('${acc['bakiye']} ${acc['doviz_tipi']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
