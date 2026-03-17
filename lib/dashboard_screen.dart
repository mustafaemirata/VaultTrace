import 'package:flutter/material.dart';
import 'api_service.dart';
import 'transfer_screen.dart';
import 'transactions_screen.dart';
import 'cards_screen.dart';
import 'loans_screen.dart';
import 'bills_screen.dart';
import 'exchange_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  bool _loading = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _loadDashboard();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await ApiService.getDashboard();
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendSecurityLog() async {
    try {
      final res = await ApiService.addSecurityLog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Log gonderildi'),
            backgroundColor: const Color(0xFF333333),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Log gonderilemedi'),
            backgroundColor: Color(0xFF333333),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('VaultTrace'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.security, color: Colors.white),
            onPressed: _sendSecurityLog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _loading = true);
              _loadDashboard();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())).then((_) => _loadDashboard()),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              color: Colors.white,
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Hos geldin, ${user?['ad'] ?? ''}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  _buildBalanceCard(),
                  const SizedBox(height: 20),
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  const Text('Hizli Islemler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Son Islemler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                      TextButton(
                        onPressed: () {
                          final accounts = _data?['hesaplar'] as List? ?? [];
                          if (accounts.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TransactionsScreen(accountId: accounts[0]['id'])),
                            );
                          }
                        },
                        child: const Text('Tumunu Gor', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildRecentTransactions(),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    final balance = _data?['toplam_bakiye'] ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF333333), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('TRY Hesap', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Toplam Bakiye', style: TextStyle(color: Color(0xFF8A8FA8), fontSize: 14)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'TRY ${_formatMoney(balance)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 12),
          if (_data?['hesaplar'] != null)
            Text(
              '${(_data!['hesaplar'] as List).length} hesap aktif',
              style: const TextStyle(color: Color(0xFF8A8FA8), fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard('Kartlar', '${_data?['kart_sayisi'] ?? 0}', Icons.credit_card, Colors.white),
        const SizedBox(width: 12),
        _buildStatCard('Faturalar', '${_data?['odenmemis_fatura'] ?? 0}', Icons.receipt_long, Colors.white),
        const SizedBox(width: 12),
        _buildStatCard('Krediler', '${_data?['aktif_kredi'] ?? 0}', Icons.monetization_on, Colors.white),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA8))),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.swap_horiz, 'label': 'Transfer', 'color': Colors.white, 'screen': const TransferScreen()},
      {'icon': Icons.credit_card, 'label': 'Kartlar', 'color': Colors.white, 'screen': const CardsScreen()},
      {'icon': Icons.monetization_on, 'label': 'Krediler', 'color': Colors.white, 'screen': const LoansScreen()},
      {'icon': Icons.receipt_long, 'label': 'Faturalar', 'color': Colors.white, 'screen': const BillsScreen()},
      {'icon': Icons.currency_exchange, 'label': 'Doviz', 'color': Colors.white, 'screen': const ExchangeScreen()},
      {'icon': Icons.history, 'label': 'Gecmis', 'color': Colors.white, 'screen': null},
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: actions.map((a) {
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Widget? screen = a['screen'] as Widget?;
            if (screen == null) {
              final accounts = _data?['hesaplar'] as List? ?? [];
              if (accounts.isNotEmpty) {
                screen = TransactionsScreen(accountId: accounts[0]['id']);
              } else {
                return;
              }
            }
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen!)).then((_) => _loadDashboard());
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(a['icon'] as IconData, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 8),
                Text(a['label'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentTransactions() {
    final transactions = _data?['son_islemler'] as List? ?? [];
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long, color: Color(0xFF333333), size: 48),
              SizedBox(height: 8),
              Text('Henuz islem yok', style: TextStyle(color: Color(0xFF8A8FA8))),
            ],
          ),
        ),
      );
    }

    return Column(
      children: transactions.take(5).map<Widget>((tx) {
        final isOutgoing = tx['from_account'] != null;
        final amount = double.tryParse(tx['tutar'].toString()) ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTransactionIcon(tx['islem_tipi']),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['aciklama'] ?? tx['islem_tipi'] ?? 'Islem',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatType(tx['islem_tipi']),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA8)),
                    ),
                  ],
                ),
              ),
              Text(
                '${isOutgoing ? '-' : '+'}TRY ${_formatMoney(amount)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getTransactionIcon(String? type) {
    switch (type) {
      case 'havale':
      case 'eft':
        return Icons.swap_horiz;
      case 'fatura':
        return Icons.receipt_long;
      case 'kart':
        return Icons.credit_card;
      case 'doviz':
        return Icons.currency_exchange;
      case 'kredi':
        return Icons.monetization_on;
      case 'yatirma':
        return Icons.add_circle_outline;
      default:
        return Icons.compare_arrows;
    }
  }

  String _formatType(String? type) {
    switch (type) {
      case 'havale': return 'Havale';
      case 'eft': return 'EFT';
      case 'fatura': return 'Fatura';
      case 'kart': return 'Kart Islemi';
      case 'doviz': return 'Doviz';
      case 'kredi': return 'Kredi';
      case 'yatirma': return 'Para Yatirma';
      default: return 'Islem';
    }
  }

  String _formatMoney(dynamic amount) {
    final num = double.tryParse(amount.toString()) ?? 0;
    final parts = num.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$intPart,${parts[1]}';
  }
}
