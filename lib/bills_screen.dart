import 'package:flutter/material.dart';
import 'api_service.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  List<dynamic> _bills = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    try {
      final bills = await ApiService.getBills();
      if (mounted) setState(() { _bills = bills; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _payBill(Map<String, dynamic> bill) async {
    final accs = await ApiService.getAccounts();
    if (accs.isEmpty) return;

    int selectedAccId = accs[0]['id'];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
          backgroundColor: const Color(0xFF121212),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('${bill['kurum']} Odeme', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${bill['tutar']} TRY tutarindaki fatura odenecektir.', style: const TextStyle(color: Color(0xFF8A8FA8))),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedAccId,
                isExpanded: true,
                dropdownColor: const Color(0xFF121212),
                decoration: const InputDecoration(labelText: 'Odeme Yapilacak Hesap'),
                items: accs.map<DropdownMenuItem<int>>((a) => DropdownMenuItem(
                  value: a['id'],
                  child: Text(
                    '${a['hesap_no']} (${a['bakiye']} TRY)',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
                onChanged: (v) => setDS(() => selectedAccId = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Iptal', style: TextStyle(color: Color(0xFF8A8FA8)))),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ode')),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final res = await ApiService.payBill(bill['id'], selectedAccId);
        if (res['success'] == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Fatura odendi!'), backgroundColor: const Color(0xFF333333), behavior: SnackBarBehavior.floating),
          );
          _loadBills();
        } else {
          _showError(res['error'] ?? 'Odeme basarisiz');
        }
      } catch (_) {}
    }
  }

  void _showError(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: const Color(0xFF333333), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Faturalar')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bills.length,
              itemBuilder: (_, i) => _buildBillCard(_bills[i]),
            ),
    );
  }

  Widget _buildBillCard(Map<String, dynamic> bill) {
    final paid = bill['odendi'] == 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
            child: Icon(paid ? Icons.check_circle_outline : Icons.receipt_long, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(bill['kurum'] ?? 'Kurum', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
              Text('Abone No: ${bill['abone_no']}', style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA8))),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${bill['tutar']} TRY', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
            const SizedBox(height: 4),
            if (!paid)
              InkWell(
                onTap: () => _payBill(bill),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: const Text('ODE', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              )
            else
              const Text('ODENDI', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ],
      ),
    );
  }
}
