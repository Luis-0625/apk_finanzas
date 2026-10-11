import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/finance_provider.dart';
import '../theme.dart';
import '../utils/format.dart';

Future<void> showExpressSheet(BuildContext context, Category category) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black87,
    builder: (_) => ExpressKeypadSheet(category: category),
  );
}

class ExpressKeypadSheet extends StatefulWidget {
  const ExpressKeypadSheet({super.key, required this.category});
  final Category category;

  @override
  State<ExpressKeypadSheet> createState() => _ExpressKeypadSheetState();
}

class _ExpressKeypadSheetState extends State<ExpressKeypadSheet> {
  String _digits = '';
  String _accountId = kAccounts.first.id;

  int get _amount => _digits.isEmpty ? 0 : int.parse(_digits);

  void _press(String k) {
    HapticFeedback.selectionClick();
    setState(() {
      if (k == 'del') {
        if (_digits.isNotEmpty) _digits = _digits.substring(0, _digits.length - 1);
        return;
      }
      if (_digits.isEmpty && (k == '0' || k == '000')) return;
      if (_digits.length + k.length > 10) return;
      _digits += k;
    });
  }

  Future<void> _save() async {
    if (_amount <= 0) return;
    HapticFeedback.mediumImpact();
    final f = context.read<FinanceProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final c = widget.category;
    final amount = _amount;
    Navigator.of(context).pop();
    await f.addTransaction(amount: amount, category: c, accountId: _accountId);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${c.name}: ${cop(amount)} guardado')));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44, height: 5,
              decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: c.color.withOpacity(0.18),
                  child: Icon(c.icon, color: c.color),
                ),
                const SizedBox(width: 12),
                Text(c.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: _amount == 0 ? Colors.white24 : c.color,
                ),
                child: Text(cop(_amount)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final a in kAccounts)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(a.icon, size: 18,
                            color: _accountId == a.id ? Colors.white : AppColors.textMuted),
                        label: Text(a.name),
                        selected: _accountId == a.id,
                        selectedColor: AppColors.purple,
                        backgroundColor: AppColors.surfaceHigh,
                        showCheckmark: false,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onSelected: (_) => setState(() => _accountId = a.id),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['000', '0', 'del'],
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    for (final k in row)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _Key(label: k, onTap: () => _press(k)),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 62,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _amount > 0 ? 1 : 0.4,
                child: FilledButton(
                  onPressed: _amount > 0 ? _save : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: c.type == TxType.income ? AppColors.emerald : AppColors.purple,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  ),
                  child: Text(
                    c.type == TxType.income ? 'Guardar ingreso' : 'Guardar gasto',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: SizedBox(
          height: 70,
          child: Center(
            child: label == 'del'
                ? const Icon(Icons.backspace_rounded, size: 28, color: AppColors.textMuted)
                : Text(label,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}
