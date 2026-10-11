import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/finance_provider.dart';
import '../theme.dart';
import '../utils/format.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final f = context.watch<FinanceProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => f.changeMonth(-1),
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            monthLabel(f.month),
            key: ValueKey(f.month),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed: f.isCurrentMonth ? null : () => f.changeMonth(1),
          icon: const Icon(Icons.chevron_right_rounded, size: 28),
        ),
      ],
    );
  }
}

class ModeToggle extends StatelessWidget {
  const ModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final f = context.watch<FinanceProvider>();
    Widget item(String label, TxType t, Color color) {
      final sel = f.mode == t;
      return Expanded(
        child: GestureDetector(
          onTap: () => f.setMode(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: sel ? color.withOpacity(0.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sel ? color : Colors.transparent),
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: sel ? color : AppColors.textMuted,
                )),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        item('Gastos', TxType.expense, AppColors.expense),
        item('Ingresos', TxType.income, AppColors.emerald),
      ]),
    );
  }
}
