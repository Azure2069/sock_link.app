import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/database/app_database.dart';
import '../../core/payments/paystack_service.dart';
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
  final paymentPhone = TextEditingController();
  final productSearch = TextEditingController();
  int? customer;
  CustomerData? newlyAddedCustomer;
  String searchQuery = '';
  double discount = 0;
  String method = 'cash';
  String? paystackReference;
  bool busy = false;

  @override
  void dispose() {
    paid.dispose();
    paymentPhone.dispose();
    productSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider).valueOrNull ?? [];
    final watchedCustomers = ref.watch(customersProvider).valueOrNull ?? [];
    final customers = [
      ...watchedCustomers,
      if (newlyAddedCustomer != null &&
          !watchedCustomers.any((item) => item.id == newlyAddedCustomer!.id))
        newlyAddedCustomer!,
    ];
    final visibleProducts = products.where((product) {
      final query = searchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      return product.name.toLowerCase().contains(query) ||
          (product.sku?.toLowerCase().contains(query) ?? false);
    }).toList();
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
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: DropdownButtonFormField<int?>(
              key: ValueKey((customer, customers.length)),
              initialValue: customer,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Customer (required for credit)'),
              items: [
                const DropdownMenuItem<int?>(
                    value: null, child: Text('Walk-in customer')),
                ...customers.map((item) => DropdownMenuItem<int?>(
                    value: item.id, child: Text(item.name))),
              ],
              onChanged: (value) => setState(() {
                customer = value;
                if (value != null) {
                  paymentPhone.text =
                      customers.firstWhere((item) => item.id == value).phone;
                }
              }),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Add new customer',
            onPressed: _addCustomer,
            icon: const Icon(Icons.person_add_alt_1),
          ),
        ]),
        const SizedBox(height: 16),
        Text('Products', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        TextField(
          controller: productSearch,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Search products',
            hintText: 'Search by name or SKU',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchQuery.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      productSearch.clear();
                      setState(() => searchQuery = '');
                    },
                    icon: const Icon(Icons.clear),
                  ),
          ),
          onChanged: (value) => setState(() => searchQuery = value),
        ),
        const SizedBox(height: 8),
        if (visibleProducts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No matching products')),
          ),
        ...visibleProducts.map((product) {
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
            DropdownMenuItem(
                value: 'momo', child: Text('Mobile Money / Paystack')),
            DropdownMenuItem(value: 'credit', child: Text('Credit')),
            DropdownMenuItem(value: 'split', child: Text('Split / partial')),
          ],
          onChanged: (value) => setState(() {
            method = value!;
            paystackReference = null;
          }),
        ),
        const SizedBox(height: 12),
        if (method == 'momo') ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mobile Money details',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  TextField(
                    controller: paymentPhone,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    decoration: const InputDecoration(
                      labelText: 'MoMo phone number *',
                      hintText: 'e.g. 024 123 4567',
                      prefixIcon: Icon(Icons.phone_android),
                      helperText: 'Enter the number that will make the payment',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            paystackReference == null
                ? 'Paystack Checkout will open. Select Mobile Money and the customer network there.'
                : 'Complete payment in Paystack Checkout, then return and verify it.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
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
              child: Text(busy
                  ? 'Please wait...'
                  : method == 'momo'
                      ? paystackReference == null
                          ? 'Open Paystack checkout'
                          : 'Verify payment & complete sale'
                      : 'Complete sale')),
        ),
      ]),
    );
  }

  Future<void> _completeSale(List<CartLine> lines, double total) async {
    setState(() => busy = true);
    try {
      PaystackVerification? paystackPayment;
      if (method == 'momo') {
        if (paymentPhone.text.replaceAll(RegExp(r'\D'), '').length < 9) {
          throw StateError('Enter a valid customer mobile number.');
        }
        final service = ref.read(paystackProvider);
        if (paystackReference == null) {
          final checkout = await service.initialize(
            phone: paymentPhone.text,
            amount: total,
            debtId: 0,
            saleId: 0,
          );
          paystackReference = checkout.reference;
          var opened = await launchUrl(
            checkout.authorizationUrl,
            mode: LaunchMode.inAppBrowserView,
          );
          if (!opened) {
            opened = await launchUrl(
              checkout.authorizationUrl,
              mode: LaunchMode.externalApplication,
            );
          }
          if (!opened) throw StateError('Could not open Paystack Checkout.');
          if (mounted) setState(() => busy = false);
          return;
        }
        paystackPayment = await service.verify(
          reference: paystackReference!,
          expectedAmount: total,
        );
        if (!paystackPayment.paid) {
          throw StateError('Payment is not successful yet.');
        }
      }
      final amount = method == 'credit'
          ? 0.0
          : method == 'split'
              ? double.tryParse(paid.text) ?? 0
              : total;
      final payments = amount > 0
          ? [
              PaymentInput(
                  method: paystackPayment == null
                      ? method == 'split'
                          ? 'cash'
                          : method
                      : 'paystack:${paystackPayment.channel ?? 'online'}',
                  amount: amount,
                  network: paystackPayment?.channel,
                  phone: method == 'momo' ? paymentPhone.text.trim() : null,
                  reference: paystackPayment?.reference)
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

  Future<void> _addCustomer() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final address = TextEditingController();
    var busy = false;
    String? error;

    final saved = await showDialog<CustomerData>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add customer'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Customer name *',
                  errorText: error,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: 'e.g. 024 123 4567',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: address,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (name.text.trim().isEmpty) {
                        setDialogState(() => error = 'Enter the customer name');
                        return;
                      }
                      setDialogState(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        final db = ref.read(databaseProvider);
                        final id = await db.into(db.customers).insert(
                              CustomersCompanion.insert(
                                name: name.text.trim(),
                                phone: Value(phone.text.trim()),
                                address: Value(address.text.trim()),
                              ),
                            );
                        final created = await (db.select(db.customers)
                              ..where((row) => row.id.equals(id)))
                            .getSingle();
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, created);
                        }
                      } catch (saveError) {
                        setDialogState(() {
                          busy = false;
                          error = '$saveError';
                        });
                      }
                    },
              child: Text(busy ? 'Saving...' : 'Save customer'),
            ),
          ],
        ),
      ),
    );

    name.dispose();
    phone.dispose();
    address.dispose();
    if (saved == null || !mounted) return;
    setState(() {
      newlyAddedCustomer = saved;
      customer = saved.id;
      paymentPhone.text = saved.phone;
    });
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
