import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/finance_provider.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/donut_chart.dart';
import '../widgets/express_keypad_sheet.dart';
import '../widgets/shared_widgets.dart';
import 'analysis_screen.dart';
import 'reports_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final f = context.watch<FinanceProvider>();
    final width = MediaQuery.of(context).size.width;
    final donutSize = (width * 0.78).clamp(240.0, 360.0);
    final totals = f.byCategory();
    final segments = [
      for (final e in totals.entries)
        if (e.value > 0) DonutSegment(categoryById(e.key).color, e.value.toDouble()),
    ];
    final recent = f.monthTx.take(8).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Mis finanzas',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    ),
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(backgroundColor: AppColors.surface),
                      onPressed: () => _open(context, const AnalysisScreen()),
                      icon: const Icon(Icons.insights_rounded, color: AppColors.emerald),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(backgroundColor: AppColors.surface),
                      onPressed: () => _open(context, const ReportsScreen()),
                      icon: const Icon(Icons.bar_chart_rounded, color: AppColors.purple),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: MonthSelector()),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 62,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final a in kAccounts)
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(children: [
                          Icon(a.icon, size: 20, color: AppColors.purple),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.name,
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              Text(cop(f.accountBalance(a.id)),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            ],
                          ),
                        ]),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: DonutChart(
                    segments: segments,
                    balance: f.balance,
                    income: f.income,
                    expense: f.expense,
                    size: donutSize,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: ModeToggle(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final c = f.categories[i];
                    return _CategoryTile(category: c, total: totals[c.id] ?? 0);
                  },
                  childCount: f.categories.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text('Movimientos recientes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            if (recent.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('Toca una categoría para registrar tu primer movimiento',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _TxTile(tx: recent[i]),
                  childCount: recent.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatefulWidget {
  const _CategoryTile({required this.category, required this.total});
  final Category category;
  final int total;

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        showExpressSheet(context, c);
      },
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: c.color.withOpacity(0.10), blurRadius: 18, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: c.color.withOpacity(0.16)),
                child: Icon(c.icon, color: c.color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(c.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              if (widget.total > 0)
                Text(copCompact(widget.total),
                    style: TextStyle(fontSize: 11, color: c.color, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx});
  final MoneyTransaction tx;

  @override
  Widget build(BuildContext context) {
    final c = categoryById(tx.categoryId);
    final isIncome = tx.type == TxType.income;
    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.expense.withOpacity(0.25),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.expense),
      ),
      onDismissed: (_) {
        final f = context.read<FinanceProvider>();
        final messenger = ScaffoldMessenger.of(context);
        f.remove(tx.id);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: const Text('Movimiento eliminado'),
            action: SnackBarAction(label: 'Deshacer', onPressed: () => f.restore(tx)),
          ));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: c.color.withOpacity(0.16),
              child: Icon(c.icon, color: c.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${shortDate(tx.date)} · ${accountById(tx.accountId).name}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}${cop(tx.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isIncome ? AppColors.emerald : AppColors.expense,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _open(BuildContext context, Widget page) {
  return Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) => FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  ));
}
