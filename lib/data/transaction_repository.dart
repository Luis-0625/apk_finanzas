import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Contrato de persistencia. Hoy: almacenamiento local.
/// Mañana: completa [ApiTransactionRepository] contra tu API (PostgreSQL)
/// y pásalo a FinanceProvider(repository: ...) sin tocar la UI.
abstract class TransactionRepository {
  Future<List<MoneyTransaction>> fetchAll();
  Future<void> add(MoneyTransaction tx);
  Future<void> remove(String id);
}

class LocalTransactionRepository implements TransactionRepository {
  static const _key = 'transactions_v1';

  Future<void> _save(List<MoneyTransaction> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  @override
  Future<List<MoneyTransaction>> fetchAll() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => MoneyTransaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> add(MoneyTransaction tx) async {
    final list = await fetchAll();
    list.add(tx);
    await _save(list);
  }

  @override
  Future<void> remove(String id) async {
    final list = await fetchAll();
    list.removeWhere((e) => e.id == id);
    await _save(list);
  }
}

/// Esqueleto para la futura API (PostgreSQL detrás).
/// Agrega `http` o `dio` y completa los endpoints.
class ApiTransactionRepository implements TransactionRepository {
  ApiTransactionRepository(this.baseUrl);
  final String baseUrl;

  @override
  Future<List<MoneyTransaction>> fetchAll() async =>
      throw UnimplementedError('GET $baseUrl/transactions');

  @override
  Future<void> add(MoneyTransaction tx) async =>
      throw UnimplementedError('POST $baseUrl/transactions');

  @override
  Future<void> remove(String id) async =>
      throw UnimplementedError('DELETE $baseUrl/transactions/$id');
}
