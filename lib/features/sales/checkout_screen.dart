import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import '../../core/utils.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final Map<int, double> cart = {};
  final paid = TextEditingController();
  final phone = TextEditingController();
  final reference = TextEditingController();
  int? customer;
  double discount = 0;
  String method = 'cash';
  String network = 'MTN';
  bool busy = false;

  @override
  void dispose() {
    paid.dispose();
    phone.dispose();
    reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider).valueOrNull ?? [];
    final customers = ref.watch(customersProvider).valueOrNull ?? [];
    final lines = cart.entries
        .where((entry) => entry.value > 0)
        .map((entry) => CartLine(
            products.firstWhere((product) => product.id == entry.key),
            entry.value))
        .toList();
    final subtotal = lines.fold<double>(
        0, (sum, line) => sum + line.quantity * line.product.sellingPrice);
    final total = (subtotal - discount).clamp(0, double.infinity).toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<int?>(
          initialValue: customer,
          decoration: const InputDecoration(
              labelText: 'Customer (required for credit)'),
          items: [
            const DropdownMenuItem<int?>(
                value: null, child: Text('Walk-in customer')),
            ...customers.map((item) =>
                DropdownMenuItem<int?>(value: item.id, child: Text(item.name))),
          ],
          onChanged: (value) => setState(() => customer = value),
        ),
        const SizedBox(height: 16),
        Text('Products', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...products.map((product) {
          final count = cart[product.id] ?? 0;
          return Card(
            child: ListTile(
              title: Text(product.name),
              subtitle: Text(
                  '${money(product.sellingPrice)} • Stock ${product.quantity}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  onPressed: count > 0
                      ? () => setState(() => cart[product.id] =
                          (count - 1).clamp(0, double.infinity))
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Text('$count'),
                IconButton(
                  onPressed: count < product.quantity
                      ? () => setState(() => cart[product.id] = count + 1)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ]),
            ),
          );
        }),
        const SizedBox(height: 16),
        TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Discount'),
          onChanged: (value) =>
              setState(() => discount = double.tryParse(value) ?? 0),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: method,
          decoration: const InputDecoration(labelText: 'Payment method'),
          items: const [
            DropdownMenuItem(value: 'cash', child: Text('Cash')),
            DropdownMenuItem(value: 'momo', child: Text('MoMo')),
            DropdownMenuItem(value: 'credit', child: Text('Credit')),
            DropdownMenuItem(value: 'split', child: Text('Split / partial')),
          ],
          onChanged: (value) => setState(() => method = value!),
        ),
        const SizedBox(height: 12),
        if (method == 'momo') ...[
          DropdownButtonFormField<String>(
            initialValue: network,
            decoration: const InputDecoration(labelText: 'Network'),
            items: const [
              DropdownMenuItem(value: 'MTN', child: Text('MTN')),
              DropdownMenuItem(value: 'Telecel', child: Text('Telecel')),
              DropdownMenuItem(value: 'AT', child: Text('AT')),
            ],
            onChanged: (value) => setState(() => network = value!),
          ),
          const SizedBox(height: 10),
          TextField(
              controller: phone,
              decoration:
                  const InputDecoration(labelText: 'MoMo phone number')),
          const SizedBox(height: 10),
          TextField(
              controller: reference,
              decoration: const InputDecoration(labelText: 'Reference')),
        ],
        if (method == 'split')
          TextField(
              controller: paid,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount paid now')),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _row('Subtotal', subtotal),
              _row('Discount', discount),
              const Divider(),
              _row('Total', total, bold: true)
            ]),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed:
              busy || lines.isEmpty ? null : () => _completeSale(lines, total),
          child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(busy ? 'Saving...' : 'Complete sale')),
        ),
      ]),
    );
  }

  Future<void> _completeSale(List<CartLine> lines, double total) async {
    setState(() => busy = true);
    try {
      final amount = method == 'credit'
          ? 0.0
          : method == 'split'
              ? double.tryParse(paid.text) ?? 0
              : total;
      final payments = amount > 0
          ? [
              PaymentInput(
                  method: method == 'split' ? 'cash' : method,
                  amount: amount,
                  network: method == 'momo' ? network : null,
                  phone: method == 'momo' ? phone.text : null,
                  reference: method == 'momo' ? reference.text : null)
            ]
          : <PaymentInput>[];
      await ref.read(databaseProvider).createSale(
          customerId: customer,
          lines: lines,
          discount: discount,
          taxRate: 0,
          paymentInputs: payments);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Sale completed')));
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _row(String label, double value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label),
          Text(money(value),
              style: bold
                  ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                  : null),
        ]),
      );
}
