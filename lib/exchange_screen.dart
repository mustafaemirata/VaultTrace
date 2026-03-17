import 'package:flutter/material.dart';
import 'dart:async';
import 'api_service.dart';

class ExchangeScreen extends StatefulWidget {
  const ExchangeScreen({super.key});

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  Map<String, dynamic> _rates = {};
  List<dynamic> _accounts = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _loadRates());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final rates = await ApiService.getExchangeRates();
      final accs = await ApiService.getAccounts();
      if (mounted) setState(() { _rates = rates; _accounts = accs; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _loadRates() async {
    try {
      final rates = await ApiService.getExchangeRates();
      if (mounted) setState(() => _rates = rates);
    } catch (_) {}
  }

  void _showExchangeSheet() {
    if (_accounts.isEmpty) return;

    int selectedAccId = _accounts[0]['id'];
    String targetDoviz = 'USD';
    final amountCtrl = TextEditingController();
    double calculateResult = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setES) {
          final rate = _rates[targetDoviz]?['satis'] ?? 1.0;
          final input = double.tryParse(amountCtrl.text) ?? 0;
          calculateResult = input / (rate as num).toDouble();

          return Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                const Text('Doviz Alim / Satim', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 24),
                DropdownButtonFormField<int>(
                  value: selectedAccId,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF121212),
                  decoration: const InputDecoration(labelText: 'Odeme Yapilacak Hesap'),
                  items: _accounts.map<DropdownMenuItem<int>>((a) => DropdownMenuItem(
                    value: a['id'],
                    child: Text(
                      '${a['hesap_no']} (${a['bakiye']} ${a['doviz_tipi']})',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )).toList(),
                  onChanged: (v) => setES(() => selectedAccId = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: targetDoviz,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF121212),
                  decoration: const InputDecoration(labelText: 'Alinacak Doviz'),
                  items: _rates.keys.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (v) => setES(() => targetDoviz = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setES(() {}),
                  decoration: const InputDecoration(labelText: 'Tutar (TRY Cinsinden)', prefixIcon: Icon(Icons.calculate_outlined)),
                ),
                const SizedBox(height: 20),
                if (input > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF333333))),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Guncel Kur', style: TextStyle(color: Color(0xFF8A8FA8), fontSize: 13)),
                          Text('1 $targetDoviz = $rate TRY', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ]),
                        const Divider(color: Color(0xFF333333), height: 20),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Alacaginiz Tutat', style: TextStyle(color: Color(0xFF8A8FA8), fontSize: 13)),
                          Text('${calculateResult.toStringAsFixed(2)} $targetDoviz', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        ]),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: input <= 0 ? null : () async {
                      Navigator.pop(ctx);
                      try {
                        final res = await ApiService.exchange(fromAccountId: selectedAccId, toDoviz: targetDoviz, tutar: input);
                        if (res['success'] == true && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Islem basarili!'), backgroundColor: const Color(0xFF333333), behavior: SnackBarBehavior.floating));
                          _loadData();
                        } else {
                          _showError(res['error'] ?? 'Islem basarisiz');
                        }
                      } catch (_) {}
                    },
                    child: const Text('Islemi Gercektestir'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showError(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: const Color(0xFF333333), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doviz Islemleri')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showExchangeSheet,
        backgroundColor: Colors.white,
        icon: const Icon(Icons.currency_exchange, color: Colors.black),
        label: const Text('Alim / Satim Yap', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Canli Kurlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Veriler 10 saniyede bir guncellenir', style: TextStyle(fontSize: 12, color: Color(0xFF8A8FA8))),
                const SizedBox(height: 20),
                ..._rates.entries.map((e) => _buildRateRow(e.key, e.value)).toList(),
              ],
            ),
    );
  }

  Widget _buildRateRow(String code, dynamic val) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF333333))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.trending_up, color: Colors.white)),
          const SizedBox(width: 16),
          Expanded(child: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white))),
          _rateCol('Alis', val['alis'].toString()),
          const SizedBox(width: 20),
          _rateCol('Satis', val['satis'].toString()),
        ],
      ),
    );
  }

  Widget _rateCol(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA8))),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
    ]);
  }
}
