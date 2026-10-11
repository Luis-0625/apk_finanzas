import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/finance_provider.dart';
import '../theme.dart';
import '../utils/analysis.dart';
import '../utils/format.dart';
import '../widgets/shared_widgets.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  Color _scoreColor(int s, bool hasData) {
    if (!hasData) return AppColors.textMuted;
    if (s >= 75) return AppColors.emerald;
    if (s >= 50) return AppColors.purple;
    if (s >= 30) return const Color(0xFFFFD166);
    return AppColors.expense;
  }

  @override
  Widget build(BuildContext context) {
    final f = context.watch<FinanceProvider>();
    final a = PortfolioAnalysis.build(f.all, f.month);
    final color = _scoreColor(a.score, a.hasData);
    final positiveTotal =
        max(1, a.accountBalances.values.where((v) => v > 0).fold(0, (s, v) => s + v));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Análisis de cartera',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const MonthSelector(),

          // Salud financiera
          _Card(
            borderColor: color.withOpacity(0.3),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('${a.score}-${f.month}'),
                    tween: Tween(begin: 0, end: a.score / 100),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: v,
                            strokeWidth: 10,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                        Text(a.hasData ? '${(v * 100).round()}' : '--',
                            style: TextStyle(
                                fontSize: 32, fontWeight: FontWeight.w800, color: color)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Salud financiera',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(a.scoreLabel,
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800, color: color)),
                      const SizedBox(height: 6),
                      const Text('Según ahorro, cobertura y tendencia de gastos.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Patrimonio
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Patrimonio total',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: a.netWorth.toDouble()),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text(cop(v),
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: a.netWorth >= 0 ? AppColors.emerald : AppColors.expense)),
                ),
                const SizedBox(height: 14),
                for (final acc in kAccounts)
                  _AccountBar(
                    account: acc,
                    balance: a.accountBalances[acc.id] ?? 0,
                    share: max(0, a.accountBalances[acc.id] ?? 0) / positiveTotal,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Métricas
          Row(children: [
            Expanded(
              child: _Metric(
                label: 'Tasa de ahorro',
                value: a.income == 0 ? '--' : '${(a.savingsRate * 100).round()}%',
                sub: a.income == 0 ? 'Sin ingresos' : 'Ahorro: ${cop(a.savings)}',
                color: a.savingsRate >= 0.2
                    ? AppColors.emerald
                    : (a.savingsRate >= 0 ? const Color(0xFFFFD166) : AppColors.expense),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Metric(
                label: 'Gasto diario',
                value: cop(a.dailyAvg),
                sub: 'Promedio del mes',
                color: AppColors.purple,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _Metric(
                label: a.isCurrentMonth ? 'Proyección de gasto' : 'Gasto del mes',
                value: copCompact(a.projectedExpense),
                sub: a.isCurrentMonth ? 'A fin de mes' : 'Total',
                color: AppColors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Metric(
                label: 'Vs mes anterior',
                value: a.expenseDelta == null
                    ? '--'
                    : '${a.expenseDelta! > 0 ? '+' : ''}${(a.expenseDelta! * 100).round()}%',
                sub: 'En gastos',
                color: a.expenseDelta == null
                    ? AppColors.textMuted
                    : (a.expenseDelta! > 0 ? AppColors.expense : AppColors.emerald),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // Top categorías
          if (a.topCategories.isNotEmpty) ...[
            const Text('Donde más gastas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            for (final e in a.topCategories)
              _TopCategory(category: e.key, amount: e.value, share: e.value / max(1, a.expense)),
            const SizedBox(height: 10),
          ],

          // Recomendaciones
          const Text('Recomendaciones',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final i in a.insights) _InsightTile(insight: i),
          const SizedBox(height: 14),
          const Text(
            'Análisis automático con tus datos locales. No constituye asesoría financiera.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.borderColor});
  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: borderColor ?? Colors.transparent),
        ),
        child: child,
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.sub, required this.color});
  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            ),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      );
}

class _AccountBar extends StatelessWidget {
  const _AccountBar({required this.account, required this.balance, required this.share});
  final Account account;
  final int balance;
  final double share;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            Row(children: [
              Icon(account.icon, size: 18, color: AppColors.purple),
              const SizedBox(width: 8),
              Expanded(child: Text(account.name, style: const TextStyle(fontSize: 13))),
              Text(cop(balance), style: const TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(
                width: 44,
                child: Text('${(share * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween(end: share),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation(AppColors.purple),
                ),
              ),
            ),
          ],
        ),
      );
}

class _TopCategory extends StatelessWidget {
  const _TopCategory({required this.category, required this.amount, required this.share});
  final Category category;
  final int amount;
  final double share;

  @override
  Widget build(BuildContext context) {
    final c = category;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: c.color.withOpacity(0.16),
          child: Icon(c.icon, color: c.color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600))),
        Text(cop(amount), style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        Text('${(share * 100).round()}%',
            style: TextStyle(color: c.color, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight});
  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (insight.level) {
      InsightLevel.good => (AppColors.emerald, Icons.check_circle_rounded),
      InsightLevel.warn => (const Color(0xFFFFD166), Icons.warning_amber_rounded),
      InsightLevel.info => (AppColors.purple, Icons.info_rounded),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(insight.text, style: const TextStyle(fontSize: 13.5, height: 1.35))),
        ],
      ),
    );
  }
}
