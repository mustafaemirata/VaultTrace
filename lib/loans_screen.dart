import 'package:flutter/material.dart';
import 'api_service.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  List<dynamic> _loans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    try {
      final loans = await ApiService.getLoans();
      if (mounted) setState(() { _loans = loans; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyLoan() {
    double tutar = 10000;
    int vade = 12;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) {
          final faiz = 2.49 / 100;
          final taksit = (tutar * faiz * powCustom(1 + faiz, vade)) / (powCustom(1 + faiz, vade) - 1);
          final toplamOdeme = taksit * vade;

          return Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 20),
                const Text('Kredi Basvurusu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 24),

                Text('Kredi Tutari: ${tutar.toInt()} TRY', style: const TextStyle(color: Color(0xFF8A8FA8))),
                Slider(
                  value: tutar,
                  min: 1000,
                  max: 100000,
                  divisions: 99,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white24,
                  onChanged: (v) => setBS(() => tutar = v.roundToDouble()),
                ),
                const SizedBox(height: 16),

                Text('Vade: $vade ay', style: const TextStyle(color: Color(0xFF8A8FA8))),
                Slider(
                  value: vade.toDouble(),
                  min: 3,
                  max: 60,
                  divisions: 57,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white24,
                  onChanged: (v) => setBS(() => vade = v.toInt()),
                ),
                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: Column(
                    children: [
                      _infoRow('Faiz Orani', '%2.49 (aylik)'),
                      _infoRow('Aylik Taksit', '${taksit.toStringAsFixed(2)} TRY'),
                      _infoRow('Toplam Odeme', '${toplamOdeme.toStringAsFixed(2)} TRY'),
                      _infoRow('Toplam Faiz', '${(toplamOdeme - tutar).toStringAsFixed(2)} TRY'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      setState(() => _loading = true);
                      try {
                        final res = await ApiService.applyLoan(tutar: tutar, vadeAy: vade);
                        if (res['success'] == true && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Kredi onaylandi!'), backgroundColor: const Color(0xFF333333),
                              behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          );
                        }
                      } catch (_) {}
                      _loadLoans();
                    },
                    child: const Text('Basvuru Yap'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8A8FA8), fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  double powCustom(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) result *= base;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Krediler')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _applyLoan,
        backgroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Kredi Basvurusu', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _loans.isEmpty
               ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on_outlined, size: 64, color: Color(0xFF333333)),
                      const SizedBox(height: 12),
                      const Text('Aktif krediniz yok', style: TextStyle(color: Color(0xFF8A8FA8))),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(onPressed: _applyLoan, icon: const Icon(Icons.add, color: Colors.black), label: const Text('Kredi Basvurusu Yap')),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _loans.length,
                  itemBuilder: (_, i) => _buildLoanCard(_loans[i]),
                ),
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> loan) {
    final durum = loan['durum'] ?? 'aktif';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${loan['tutar']} TRY', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                child: Text(durum.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow('Aylik Taksit', '${loan['aylik_taksit']} TRY'),
          _infoRow('Kalan Taksit', '${loan['kalan_taksit']} / ${loan['vade_ay']} ay'),
          _infoRow('Faiz Orani', '%${loan['faiz_orani']}'),

          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 1 - (int.tryParse(loan['kalan_taksit'].toString()) ?? 0) / (int.tryParse(loan['vade_ay'].toString()) ?? 1),
              backgroundColor: const Color(0xFF333333),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
