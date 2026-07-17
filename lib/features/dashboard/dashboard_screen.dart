import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import '../../core/utils.dart';
import '../sales/checkout_screen.dart';
import '../expenses/expenses_screen.dart';
import '../debts/debts_screen.dart';
import '../inventory/inventory_screen.dart';

class DashboardScreen extends ConsumerWidget {
  final BusinessData business;
  const DashboardScreen({super.key, required this.business});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return Scaffold(
        appBar: AppBar(title: Text(business.name)),
        body: RefreshIndicator(
            onRefresh: () => Future.delayed(const Duration(milliseconds: 400)),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Text('Today', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              FutureBuilder(
                  future: Future.wait([
                    db.todaySalesTotal(),
                    db.todayProfit(),
                    db.outstandingDebtTotal(),
                    db.inventoryValue()
                  ]),
                  builder: (c, s) {
                    final d = s.data ?? [0.0, 0.0, 0.0, 0.0];
                    return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.45,
                        children: [
                          _Metric('Sales', money(d[0]), Icons.payments),
                          _Metric('Profit', money(d[1]), Icons.trending_up),
                          _Metric('Debts', money(d[2]),
                              Icons.account_balance_wallet),
                          _Metric('Inventory', money(d[3]), Icons.inventory)
                        ]);
                  }),
              const SizedBox(height: 24),
              Text('Quick actions',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.7,
                children: [
                  _Action(
                      'New sale',
                      Icons.add_shopping_cart,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CheckoutScreen()))),
                  _Action(
                      'Stock',
                      Icons.swap_vert,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const InventoryScreen()))),
                  _Action(
                      'Expenses',
                      Icons.receipt_long,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ExpensesScreen()))),
                  _Action(
                      'Debts',
                      Icons.credit_score,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DebtsScreen()))),
                ],
              ),
              const SizedBox(height: 24),
              Consumer(builder: (c, ref, _) {
                final ps = ref.watch(productsProvider).valueOrNull ?? [];
                final low =
                    ps.where((p) => p.quantity <= p.minimumStock).toList();
                return Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Low stock (${low.length})',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              if (low.isEmpty)
                                const Text(
                                    'All products are sufficiently stocked')
                              else
                                ...low.take(5).map((p) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(p.name),
                                    trailing: Text('${p.quantity} ${p.unit}')))
                            ])));
              })
            ])));
  }
}

class _Metric extends StatelessWidget {
  final String t, v;
  final IconData i;
  const _Metric(this.t, this.v, this.i);
  @override
  Widget build(BuildContext c) => Card(
      child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(i),
                const SizedBox(height: 8),
                Text(v,
                    style: Theme.of(c)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(t)
              ])));
}

class _Action extends StatelessWidget {
  final String t;
  final IconData i;
  final VoidCallback f;
  const _Action(this.t, this.i, this.f);
  @override
  Widget build(BuildContext c) {
    final colors = Theme.of(c).colorScheme;
    final (background, iconColor, onIcon, foreground) = switch (t) {
      'Stock' => (
          colors.secondaryContainer,
          colors.secondary,
          colors.onSecondary,
          colors.onSecondaryContainer,
        ),
      'Expenses' => (
          colors.tertiaryContainer,
          colors.tertiary,
          colors.onTertiary,
          colors.onTertiaryContainer,
        ),
      'Debts' => (
          colors.surfaceContainerHighest,
          colors.primary,
          colors.onPrimary,
          colors.onSurface,
        ),
      _ => (
          colors.primaryContainer,
          colors.primary,
          colors.onPrimary,
          colors.onPrimaryContainer,
        ),
    };
    return Card(
      color: background,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: f,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(i, color: onIcon, size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t,
                style: Theme.of(c).textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
