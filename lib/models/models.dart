import 'package:flutter/material.dart';

enum TxType { expense, income }

/// Iconos const (evita problemas de tree-shaking en release).
const Map<String, IconData> kIcons = {
  'comida': Icons.restaurant_rounded,
  'transporte': Icons.directions_bus_rounded,
  'entretenimiento': Icons.movie_rounded,
  'hogar': Icons.home_rounded,
  'salud': Icons.favorite_rounded,
  'educacion': Icons.school_rounded,
  'ropa': Icons.checkroom_rounded,
  'negocio': Icons.storefront_rounded,
  'servicios': Icons.bolt_rounded,
  'otros': Icons.more_horiz_rounded,
  'salario': Icons.payments_rounded,
  'ventas': Icons.shopping_bag_rounded,
  'inversion': Icons.trending_up_rounded,
  'regalo': Icons.card_giftcard_rounded,
  'cuenta': Icons.account_balance_rounded,
  'efectivo': Icons.account_balance_wallet_rounded,
  'movil': Icons.phone_android_rounded,
};

class Category {
  final String id;
  final String name;
  final String iconKey;
  final Color color;
  final TxType type;
  const Category(this.id, this.name, this.iconKey, this.color, this.type);
  IconData get icon => kIcons[iconKey] ?? Icons.category_rounded;
}

class Account {
  final String id;
  final String name;
  final String iconKey;
  const Account(this.id, this.name, this.iconKey);
  IconData get icon => kIcons[iconKey] ?? Icons.account_balance_wallet_rounded;
}

class MoneyTransaction {
  final String id;
  final int amount; // COP enteros, siempre positivo
  final TxType type;
  final String categoryId;
  final String accountId;
  final DateTime date;

  const MoneyTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type.name,
        'categoryId': categoryId,
        'accountId': accountId,
        'date': date.toIso8601String(),
      };

  factory MoneyTransaction.fromJson(Map<String, dynamic> j) => MoneyTransaction(
        id: j['id'] as String,
        amount: j['amount'] as int,
        type: TxType.values.byName(j['type'] as String),
        categoryId: j['categoryId'] as String,
        accountId: j['accountId'] as String,
        date: DateTime.parse(j['date'] as String),
      );
}

class MonthTotal {
  final DateTime month;
  final int income;
  final int expense;
  const MonthTotal(this.month, this.income, this.expense);
}

const List<Account> kAccounts = [
  Account('efectivo', 'Efectivo', 'efectivo'),
  Account('banco', 'Cuenta bancaria', 'cuenta'),
  Account('nequi', 'Nequi / Daviplata', 'movil'),
];

const List<Category> kCategories = [
  // Gastos
  Category('comida', 'Comida', 'comida', Color(0xFFFF8A4C), TxType.expense),
  Category('transporte', 'Transporte', 'transporte', Color(0xFF4CC9F0), TxType.expense),
  Category('entretenimiento', 'Entretenimiento', 'entretenimiento', Color(0xFFB66DFF), TxType.expense),
  Category('hogar', 'Hogar', 'hogar', Color(0xFF22E3A1), TxType.expense),
  Category('salud', 'Salud', 'salud', Color(0xFFFF5D7A), TxType.expense),
  Category('educacion', 'Educación', 'educacion', Color(0xFFFFD166), TxType.expense),
  Category('ropa', 'Ropa', 'ropa', Color(0xFFF72585), TxType.expense),
  Category('negocio', 'Inversión Negocio', 'negocio', Color(0xFF7B61FF), TxType.expense),
  Category('servicios', 'Servicios', 'servicios', Color(0xFF3A86FF), TxType.expense),
  Category('otros', 'Otros', 'otros', Color(0xFF8E8EA3), TxType.expense),
  // Ingresos
  Category('salario', 'Salario', 'salario', Color(0xFF22E3A1), TxType.income),
  Category('ventas', 'Ventas', 'ventas', Color(0xFF9B5CFF), TxType.income),
  Category('inversion', 'Inversiones', 'inversion', Color(0xFF4CC9F0), TxType.income),
  Category('regalo', 'Regalos', 'regalo', Color(0xFFFFD166), TxType.income),
  Category('otros_ing', 'Otros ingresos', 'otros', Color(0xFF8E8EA3), TxType.income),
];

Category categoryById(String id) =>
    kCategories.firstWhere((c) => c.id == id, orElse: () => kCategories.first);

Account accountById(String id) =>
    kAccounts.firstWhere((a) => a.id == id, orElse: () => kAccounts.first);
