import 'dart:math';
import '../models/models.dart';
import 'format.dart';

enum InsightLevel { good, warn, info }

class Insight {
  final InsightLevel level;
  final String text;
  const Insight(this.level, this.text);
}

/// Análisis automático (reglas locales) de la cartera del usuario.
class PortfolioAnalysis {
  PortfolioAnalysis._({
    required this.hasData,
    required this.netWorth,
    required this.accountBalances,
    required this.income,
    required this.expense,
    required this.savingsRate,
    required this.dailyAvg,
    required this.projectedExpense,
    required this.isCurrentMonth,
    required this.expenseDelta,
    required this.topCategories,
    required this.runwayMonths,
    required this.score,
    required this.scoreLabel,
    required this.insights,
  });

  final bool hasData;
  final int netWorth;
  final Map<String, int> accountBalances;
  final int income;
  final int expense;
  final double savingsRate; // puede ser negativa
  final int dailyAvg;
  final int projectedExpense;
  final bool isCurrentMonth;
  final double? expenseDelta; // vs mes anterior, null si no hay base
  final List<MapEntry<Category, int>> topCategories;
  final double? runwayMonths;
  final int score; // 0-100
  final String scoreLabel;
  final List<Insight> insights;

  int get savings => income - expense;

  static bool _in(MoneyTransaction t, DateTime m) =>
      t.date.year == m.year && t.date.month == m.month;

  static int _sum(Iterable<MoneyTransaction> l, TxType type) =>
      l.where((e) => e.type == type).fold(0, (s, e) => s + e.amount);

  static String _pct(double v) => '${(v * 100).round()}%';

  factory PortfolioAnalysis.build(List<MoneyTransaction> all, DateTime month) {
    final now = DateTime.now();
    final isCurrent = month.year == now.year && month.month == now.month;

    // Patrimonio y distribución por cuenta (histórico completo)
    final balances = <String, int>{
      for (final a in kAccounts)
        a.id: all
            .where((t) => t.accountId == a.id)
            .fold(0, (s, t) => s + (t.type == TxType.income ? t.amount : -t.amount)),
    };
    final netWorth = balances.values.fold(0, (s, v) => s + v);

    final cur = all.where((t) => _in(t, month)).toList();
    final income = _sum(cur, TxType.income);
    final expense = _sum(cur, TxType.expense);
    final rate = income > 0 ? (income - expense) / income : (expense > 0 ? -1.0 : 0.0);

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final elapsed = isCurrent ? now.day : daysInMonth;
    final dailyAvg = expense ~/ max(1, elapsed);
    final projected = isCurrent ? dailyAvg * daysInMonth : expense;

    final prevMonth = DateTime(month.year, month.month - 1);
    final prevExpense = _sum(all.where((t) => _in(t, prevMonth)), TxType.expense);
    final delta = prevExpense > 0 ? (expense - prevExpense) / prevExpense : null;

    // Top categorías de gasto
    final byCat = <String, int>{};
    for (final t in cur.where((t) => t.type == TxType.expense)) {
      byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount;
    }
    final top = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topCats = [for (final e in top.take(3)) MapEntry(categoryById(e.key), e.value)];

    // Cobertura: meses que aguanta el patrimonio con el gasto promedio (3 meses)
    var spent = 0;
    var counted = 0;
    for (var i = 0; i < 3; i++) {
      final m = DateTime(month.year, month.month - i);
      final e = _sum(all.where((t) => _in(t, m)), TxType.expense);
      if (e > 0) {
        spent += e;
        counted++;
      }
    }
    final avgMonthly = counted > 0 ? spent / counted : 0.0;
    final double? runway = avgMonthly > 0 ? max(0.0, netWorth / avgMonthly) : null;

    // Puntaje 0-100
    final hasData = cur.isNotEmpty;
    double s = 0;
    if (hasData) {
      s += income == 0 ? (expense == 0 ? 25 : 0) : (rate / 0.2).clamp(0.0, 1.0) * 50;
      s += runway == null ? 15 : (runway / 3).clamp(0.0, 1.0) * 30;
      s += delta == null ? 10 : (delta <= 0 ? 20 : (1 - delta / 0.3).clamp(0.0, 1.0) * 20);
    }
    final score = s.round();
    final label = !hasData
        ? 'Sin datos'
        : score >= 75
            ? 'Excelente'
            : score >= 50
                ? 'Buena'
                : score >= 30
                    ? 'Regular'
                    : 'Atención';

    // Recomendaciones
    final ins = <Insight>[];
    if (!hasData) {
      ins.add(const Insight(InsightLevel.info,
          'Registra tus ingresos y gastos de este mes para generar el análisis.'));
    } else {
      if (income == 0 && expense > 0) {
        ins.add(const Insight(InsightLevel.info,
            'Aún no registras ingresos este mes, por eso el balance se ve negativo.'));
      } else if (income > 0) {
        if (rate >= 0.2) {
          ins.add(Insight(InsightLevel.good,
              'Estás ahorrando el ${_pct(rate)} de tus ingresos. ¡Vas muy bien!'));
        } else if (rate >= 0) {
          ins.add(Insight(InsightLevel.warn,
              'Ahorras el ${_pct(rate)} de tus ingresos. Una meta sana es el 20%.'));
        } else {
          ins.add(Insight(InsightLevel.warn,
              'Gastaste ${cop(-(income - expense))} más de lo que ingresó este mes.'));
        }
      }
      if (delta != null && delta > 0.1) {
        ins.add(Insight(InsightLevel.warn,
            'Tus gastos subieron ${_pct(delta)} frente al mes anterior.'));
      } else if (delta != null && delta < -0.1) {
        ins.add(Insight(InsightLevel.good,
            'Redujiste tus gastos ${_pct(-delta)} frente al mes anterior.'));
      }
      if (topCats.isNotEmpty && expense > 0) {
        final share = topCats.first.value / expense;
        if (share >= 0.4) {
          ins.add(Insight(InsightLevel.warn,
              '${topCats.first.key.name} concentra el ${_pct(share)} de tus gastos. Revisa si puedes recortar ahí.'));
        }
      }
      final negocio = byCat['negocio'] ?? 0;
      if (negocio > 0 && expense > 0) {
        ins.add(Insight(InsightLevel.info,
            'Destinaste ${cop(negocio)} (${_pct(negocio / expense)} de tus gastos) a Inversión Negocio.'));
      }
      if (isCurrent && income > 0 && projected > income && expense < income) {
        ins.add(Insight(InsightLevel.warn,
            'A este ritmo cerrarías el mes gastando ~${cop(projected)}, por encima de tus ingresos.'));
      }
      if (runway != null) {
        if (runway < 1) {
          ins.add(const Insight(InsightLevel.warn,
              'Tu patrimonio cubre menos de 1 mes de gastos. Apunta a un fondo de emergencia de 3 a 6 meses.'));
        } else if (runway >= 3) {
          ins.add(Insight(InsightLevel.good,
              'Tu patrimonio cubre ~${runway.toStringAsFixed(1)} meses de gastos. Buen colchón de emergencia.'));
        } else {
          ins.add(Insight(InsightLevel.info,
              'Tu patrimonio cubre ~${runway.toStringAsFixed(1)} meses de gastos. La meta recomendada es de 3 a 6.'));
        }
      }
    }

    return PortfolioAnalysis._(
      hasData: hasData,
      netWorth: netWorth,
      accountBalances: balances,
      income: income,
      expense: expense,
      savingsRate: rate,
      dailyAvg: dailyAvg,
      projectedExpense: projected,
      isCurrentMonth: isCurrent,
      expenseDelta: delta,
      topCategories: topCats,
      runwayMonths: runway,
      score: score,
      scoreLabel: label,
      insights: ins,
    );
  }
}
