import 'package:flutter/material.dart';
import 'api_service.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _ibanCtrl = TextEditingController();
  final _tutarCtrl = TextEditingController();
  final _aciklamaCtrl = TextEditingController();
  List<dynamic> _accounts = [];
  int? _selectedAccountId;
  bool _loading = false;
  bool _loadingAccounts = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accs = await ApiService.getAccounts();
      if (mounted) {
        setState(() {
          _accounts = accs;
          if (accs.isNotEmpty) _selectedAccountId = accs[0]['id'];
          _loadingAccounts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingAccounts = false);
    }
  }

  Future<void> _doTransfer() async {
    if (_selectedAccountId == null || _ibanCtrl.text.isEmpty || _tutarCtrl.text.isEmpty) {
      _showSnack('Tum alanlari doldurun');
      return;
    }
    final tutar = double.tryParse(_tutarCtrl.text);
    if (tutar == null || tutar <= 0) {
      _showSnack('Gecerli bir tutar girin');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Transfer Onayi', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _confirmRow('Alici IBAN', _ibanCtrl.text),
            _confirmRow('Tutar', 'TRY ${_tutarCtrl.text}'),
            if (_aciklamaCtrl.text.isNotEmpty) _confirmRow('Aciklama', _aciklamaCtrl.text),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Iptal', style: TextStyle(color: Color(0xFF8A8FA8)))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Onayla')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final result = await ApiService.transfer(
        fromAccountId: _selectedAccountId!,
        toIban: _ibanCtrl.text.trim(),
        tutar: tutar,
        aciklama: _aciklamaCtrl.text.trim().isEmpty ? null : _aciklamaCtrl.text.trim(),
      );
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Transfer basarili!'),
              backgroundColor: const Color(0xFF333333),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        _showSnack(result['error'] ?? 'Transfer basarisiz');
      }
    } catch (e) {
      _showSnack('Sunucuya baglanilamadi');
    }
    if (mounted) setState(() => _loading = false);
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(color: Color(0xFF8A8FA8), fontSize: 14)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF333333), behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Para Transferi')),
      body: _loadingAccounts
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.swap_horiz, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Gonderen Hesap', style: TextStyle(color: Color(0xFF8A8FA8), fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedAccountId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF121212),
                        items: _accounts.map<DropdownMenuItem<int>>((a) {
                          return DropdownMenuItem(
                            value: a['id'],
                            child: Text(
                              '${a['hesap_no']} (${a['doviz_tipi']} - ${a['bakiye']})',
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedAccountId = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _ibanCtrl,
                    decoration: const InputDecoration(labelText: 'Alici IBAN', prefixIcon: Icon(Icons.account_balance)),
                    maxLength: 26,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tutarCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Tutar (TRY)', prefixIcon: Icon(Icons.attach_money)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _aciklamaCtrl,
                    decoration: const InputDecoration(labelText: 'Aciklama (opsiyonel)', prefixIcon: Icon(Icons.note)),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _doTransfer,
                      icon: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.send),
                      label: Text(_loading ? 'Gonderiliyor...' : 'Gonder'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
