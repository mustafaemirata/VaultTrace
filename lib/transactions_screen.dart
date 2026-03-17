import 'package:flutter/material.dart';
import 'api_service.dart';

class TransactionsScreen extends StatefulWidget {
  final int accountId;
  const TransactionsScreen({super.key, required this.accountId});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<dynamic> _allTransactions = [];
  List<dynamic> _filteredTransactions = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final txs = await ApiService.getTransactions(widget.accountId);
      if (mounted) {
        setState(() {
          _allTransactions = txs;
          _filteredTransactions = txs;
          _loading = false;
        });
      }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  void _filter(String q) {
    setState(() {
      _searchQuery = q.toLowerCase();
      _filteredTransactions = _allTransactions.where((t) {
        final desc = (t['aciklama'] ?? '').toString().toLowerCase();
        final type = (t['islem_tipi'] ?? '').toString().toLowerCase();
        return desc.contains(_searchQuery) || type.contains(_searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Islem Gecmisi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Islem ara...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _filteredTransactions.isEmpty
                    ? const Center(child: Text('Islem bulunamadi', style: TextStyle(color: Color(0xFF8A8FA8))))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredTransactions.length,
                        itemBuilder: (_, i) => _buildTxItem(_filteredTransactions[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTxItem(Map<String, dynamic> tx) {
    final isOutgoing = tx['from_account'] == widget.accountId;
    final amount = double.tryParse(tx['tutar'].toString()) ?? 0;
    final date = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF333333))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
            child: Icon(isOutgoing ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['aciklama'] ?? tx['islem_tipi'] ?? 'Islem', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text('${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA8))),
              ],
            ),
          ),
          Text(
            '${isOutgoing ? '-' : '+'}TRY ${_formatMoney(amount)}',
            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$intPart,${parts[1]}';
  }
}
