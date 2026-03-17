import 'package:flutter/material.dart';
import 'api_service.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<dynamic> _cards = [];
  List<dynamic> _accounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final cards = await ApiService.getCards();
      final accs = await ApiService.getAccounts();
      if (mounted) setState(() { _cards = cards; _accounts = accs; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createCard() async {
    if (_accounts.isEmpty) return;

    String selectedType = 'debit';
    int selectedAccId = _accounts[0]['id'];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF121212),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Yeni Kart Olustur', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedAccId,
                isExpanded: true,
                dropdownColor: const Color(0xFF121212),
                decoration: const InputDecoration(labelText: 'Hesap'),
                items: _accounts.map<DropdownMenuItem<int>>((a) => DropdownMenuItem(
                  value: a['id'],
                  child: Text(
                    '${a['doviz_tipi']} - ${a['bakiye']}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
                onChanged: (v) => setDialogState(() => selectedAccId = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                isExpanded: true,
                dropdownColor: const Color(0xFF121212),
                decoration: const InputDecoration(labelText: 'Kart Tipi'),
                items: const [
                  DropdownMenuItem(value: 'debit', child: Text('Banka Karti', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'kredi', child: Text('Kredi Karti', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (v) => setDialogState(() => selectedType = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Iptal', style: TextStyle(color: Color(0xFF8A8FA8)))),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Olustur')),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        await ApiService.createCard(accountId: selectedAccId, kartTipi: selectedType);
        _loadData();
      } catch (e) {}
    }
  }

  Future<void> _toggleCard(int cardId, bool currentActive) async {
    try {
      await ApiService.updateCard(cardId, aktif: !currentActive);
      _loadData();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kartlarim'),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.white), onPressed: _createCard),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _cards.isEmpty
               ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.credit_card_off, size: 64, color: Color(0xFF333333)),
                      const SizedBox(height: 12),
                      const Text('Henuz kartiniz yok', style: TextStyle(color: Color(0xFF8A8FA8))),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(onPressed: _createCard, icon: const Icon(Icons.add, color: Colors.black), label: const Text('Kart Olustur')),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cards.length,
                  itemBuilder: (_, i) => _buildCardWidget(_cards[i]),
                ),
    );
  }

  Widget _buildCardWidget(Map<String, dynamic> card) {
    final isActive = card['aktif'] == 1;
    final isKredi = card['kart_tipi'] == 'kredi';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isKredi ? 'Kredi Karti' : 'Banka Karti', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                        if (!isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                            child: const Text('DONDURULMUS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                    Text(
                      _formatCardNo(card['kart_no'] ?? ''),
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 3),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CVV', style: TextStyle(color: Colors.white54, fontSize: 10)),
                            Text(card['cvv'] ?? '***', style: const TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SKT', style: TextStyle(color: Colors.white54, fontSize: 10)),
                            Text(card['son_kullanma'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                        const Text('VAULTTRACE', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Limit: ${card['kart_limit']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Harcanan: ${card['harcanan']}', style: const TextStyle(color: Color(0xFF8A8FA8), fontSize: 12)),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF333333),
                  onChanged: (_) => _toggleCard(card['id'], isActive),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCardNo(String no) {
    if (no.length < 16) return no;
    return '${no.substring(0, 4)}  ${no.substring(4, 8)}  ${no.substring(8, 12)}  ${no.substring(12)}';
  }
}
