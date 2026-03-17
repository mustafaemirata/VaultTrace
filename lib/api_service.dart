import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  static String? _token;
  static Map<String, dynamic>? currentUser;

  static void setToken(String token) => _token = token;
  static String? getToken() => _token;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Future<Map<String, dynamic>> register({
    required String tcNo,
    required String ad,
    required String soyad,
    required String sifre,
    String? email,
    String? telefon,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'tc_no': tcNo,
        'ad': ad,
        'soyad': soyad,
        'sifre': sifre,
        'email': email,
        'telefon': telefon,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      _token = data['token'];
      currentUser = data['user'];
    }
    return data;
  }

  static Future<Map<String, dynamic>> login({
    required String tcNo,
    required String sifre,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'tc_no': tcNo, 'sifre': sifre}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      _token = data['token'];
      currentUser = data['user'];
    }
    return data;
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await http.get(Uri.parse('$baseUrl/dashboard'), headers: _headers);
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getAccounts() async {
    final res = await http.get(Uri.parse('$baseUrl/accounts'), headers: _headers);
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getTransactions(int accountId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/accounts/$accountId/transactions'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> transfer({
    required int fromAccountId,
    required String toIban,
    required double tutar,
    String? aciklama,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/transfer'),
      headers: _headers,
      body: jsonEncode({
        'from_account_id': fromAccountId,
        'to_iban': toIban,
        'tutar': tutar,
        'aciklama': aciklama ?? 'Havale',
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getCards() async {
    final res = await http.get(Uri.parse('$baseUrl/cards'), headers: _headers);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> createCard({
    required int accountId,
    String kartTipi = 'debit',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/cards'),
      headers: _headers,
      body: jsonEncode({'account_id': accountId, 'kart_tipi': kartTipi}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateCard(int cardId, {bool? aktif, double? limit}) async {
    final body = <String, dynamic>{};
    if (aktif != null) body['aktif'] = aktif;
    if (limit != null) body['kart_limit'] = limit;
    final res = await http.put(
      Uri.parse('$baseUrl/cards/$cardId'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getLoans() async {
    final res = await http.get(Uri.parse('$baseUrl/loans'), headers: _headers);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> applyLoan({
    required double tutar,
    required int vadeAy,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/loans/apply'),
      headers: _headers,
      body: jsonEncode({'tutar': tutar, 'vade_ay': vadeAy}),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getBills() async {
    final res = await http.get(Uri.parse('$baseUrl/bills'), headers: _headers);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> payBill(int billId, int accountId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/bills/$billId/pay'),
      headers: _headers,
      body: jsonEncode({'account_id': accountId}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getExchangeRates() async {
    final res = await http.get(Uri.parse('$baseUrl/exchange-rates'), headers: _headers);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> exchange({
    required int fromAccountId,
    required String toDoviz,
    required double tutar,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/exchange'),
      headers: _headers,
      body: jsonEncode({
        'from_account_id': fromAccountId,
        'to_doviz': toDoviz,
        'tutar': tutar,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> addSecurityLog() async {
    final res = await http.get(Uri.parse('$baseUrl/add-log'), headers: _headers);
    return jsonDecode(res.body);
  }
}
