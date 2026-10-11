import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/finance_provider.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/shared_widgets.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final f = context.watch<FinanceProvider>();
    final months = f.lastMonths(6);
    final maxVal = max(1, months.fold<int>(0, (m, e) => max(m, max(e.income, e.expense))));
    final byCat = f.byCategory().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = byCat.fold<int>(0, (s, e) => s + e.value);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Reportes', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const MonthSelector(),
          Row(
            children: [
              Expanded(child: _SummaryCard('Ingresos', f.income, AppColors.emerald)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard('Gastos', f.expense, AppColors.expense)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Últimos 6 meses',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Row(children: [
                  _Dot(AppColors.emerald), SizedBox(width: 4),
                  Text('Ingresos', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  SizedBox(width: 12),
                  _Dot(AppColors.expense), SizedBox(width: 4),
                  Text('Gastos', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  height: 170,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final m in months)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _Bar(m.income / maxVal, AppColors.emerald),
                                const SizedBox(width: 3),
                                _Bar(m.expense / maxVal, AppColors.expense),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(shortMonth(m.month),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const ModeToggle(),
          const SizedBox(height: 16),
          if (byCat.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('Sin movimientos en este mes',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            for (final e in byCat)
              _CategoryRow(
                category: categoryById(e.key),
                amount: e.value,
                share: total == 0 ? 0 : e.value / total,
              ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.label, this.amount, this.color);
  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(cop(amount),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
      width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _Bar extends StatelessWidget {
  const _Bar(this.ratio, this.color);
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: ratio),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Container(
        width: 14,
        height: max(3.0, v * 120),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 8)],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.amount, required this.share});
  final Category category;
  final int amount;
  final double share;

  @override
  Widget build(BuildContext context) {
    final c = category;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: c.color.withOpacity(0.16),
                child: Icon(c.icon, color: c.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Text(cop(amount), style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              SizedBox(
                width: 42,
                child: Text('${(share * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: c.color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(end: share),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 7,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(c.color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
