import 'package:flutter/foundation.dart';
import '../data/transaction_repository.dart';
import '../models/models.dart';

class FinanceProvider extends ChangeNotifier {
  FinanceProvider({TransactionRepository? repository})
      : _repo = repository ?? LocalTransactionRepository();

  final TransactionRepository _repo;
  List<MoneyTransaction> _all = [];
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  TxType _mode = TxType.expense;

  DateTime get month => _month;
  List<MoneyTransaction> get all => List.unmodifiable(_all);
  TxType get mode => _mode;
  bool get isCurrentMonth {
    final n = DateTime.now();
    return _month.year == n.year && _month.month == n.month;
  }

  Future<void> load() async {
    _all = await _repo.fetchAll();
    notifyListeners();
  }

  void setMode(TxType m) {
    if (m == _mode) return;
    _mode = m;
    notifyListeners();
  }

  void changeMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    final n = DateTime.now();
    if (next.isAfter(DateTime(n.year, n.month))) return;
    _month = next;
    notifyListeners();
  }

  List<Category> get categories =>
      kCategories.where((c) => c.type == _mode).toList();

  List<MoneyTransaction> get monthTx => _all
      .where((t) => t.date.year == _month.year && t.date.month == _month.month)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  int _sum(Iterable<MoneyTransaction> l, TxType t) =>
      l.where((e) => e.type == t).fold(0, (s, e) => s + e.amount);

  int get income => _sum(monthTx, TxType.income);
  int get expense => _sum(monthTx, TxType.expense);
  int get balance => income - expense;

  /// Total por categoría del mes para un tipo (por defecto el modo actual).
  Map<String, int> byCategory([TxType? type]) {
    final t = type ?? _mode;
    final map = <String, int>{};
    for (final tx in monthTx.where((e) => e.type == t)) {
      map[tx.categoryId] = (map[tx.categoryId] ?? 0) + tx.amount;
    }
    return map;
  }

  int accountBalance(String accountId) => _all
      .where((t) => t.accountId == accountId)
      .fold(0, (s, t) => s + (t.type == TxType.income ? t.amount : -t.amount));

  List<MonthTotal> lastMonths([int n = 6]) {
    return List.generate(n, (i) {
      final m = DateTime(_month.year, _month.month - (n - 1 - i));
      final list = _all.where((t) => t.date.year == m.year && t.date.month == m.month);
      return MonthTotal(m, _sum(list, TxType.income), _sum(list, TxType.expense));
    });
  }

  Future<void> addTransaction({
    required int amount,
    required Category category,
    required String accountId,
  }) async {
    final now = DateTime.now();
    // Si se navegó a un mes pasado, se registra dentro de ese mes.
    final date = isCurrentMonth
        ? now
        : DateTime(_month.year, _month.month, 15, now.hour, now.minute);
    final tx = MoneyTransaction(
      id: now.microsecondsSinceEpoch.toString(),
      amount: amount,
      type: category.type,
      categoryId: category.id,
      accountId: accountId,
      date: date,
    );
    _all = [..._all, tx];
    notifyListeners();
    await _repo.add(tx);
  }

  Future<void> restore(MoneyTransaction tx) async {
    _all = [..._all, tx];
    notifyListeners();
    await _repo.add(tx);
  }

  Future<void> remove(String id) async {
    _all = _all.where((e) => e.id != id).toList();
    notifyListeners();
    await _repo.remove(id);
  }
}
