import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import '../../core/utils.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debts = ref.watch(debtsProvider);
    final customers = ref.watch(customersProvider).valueOrNull ?? [];
    final requests = ref.watch(paymentRequestsProvider).valueOrNull ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Outstanding debts')),
      body: debts.when(
        data: (items) {
          final outstanding =
              items.where((item) => item.status != 'paid').toList();
          if (outstanding.isEmpty) {
            return const Center(child: Text('No outstanding debts'));
          }
          final customerById = {for (final item in customers) item.id: item};
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: outstanding.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final debt = outstanding[index];
              final customer = customerById[debt.customerId];
              final pending = requests
                  .where((item) =>
                      item.debtId == debt.id && item.status == 'pending')
                  .firstOrNull;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const CircleAvatar(child: Icon(Icons.person)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer?.name ?? 'Unknown customer',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(customer?.phone.isNotEmpty == true
                                  ? customer!.phone
                                  : 'No mobile number'),
                            ],
                          ),
                        ),
                        Text(
                          money(debt.balance),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                          'Sale #${debt.saleId} • ${shortDate(debt.createdAt)}'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => _pay(context, ref, debt),
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text('Record payment'),
                          ),
                          if (pending == null)
                            OutlinedButton.icon(
                              onPressed: customer?.phone.isNotEmpty == true
                                  ? () =>
                                      _sendPrompt(context, ref, debt, customer!)
                                  : null,
                              icon: const Icon(Icons.send_outlined),
                              label: const Text('Send payment link'),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _checkRequest(context, ref, debt, pending),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Check payment'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}

Future<void> _sendPrompt(BuildContext context, WidgetRef ref, DebtData debt,
    CustomerData customer) async {
  try {
    final checkout = await ref.read(paystackProvider).initialize(
          phone: customer.phone,
          amount: debt.balance,
          debtId: debt.id,
          saleId: debt.saleId,
        );
    await ref.read(databaseProvider).savePaymentRequest(
          debtId: debt.id,
          amount: debt.balance,
          phone: customer.phone,
          reference: checkout.reference,
          authorizationUrl: checkout.authorizationUrl.toString(),
        );
    final message = 'Hello ${customer.name}, your outstanding balance is '
        '${money(debt.balance)}. Pay securely here: ${checkout.authorizationUrl}';
    final sms = Uri(
      scheme: 'sms',
      path: customer.phone,
      queryParameters: {'body': message},
    );
    final opened = await launchUrl(sms, mode: LaunchMode.externalApplication);
    if (!opened) {
      await Clipboard.setData(
          ClipboardData(text: checkout.authorizationUrl.toString()));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Payment link copied. Send it to the customer.')));
      }
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

Future<void> _checkRequest(BuildContext context, WidgetRef ref, DebtData debt,
    PaymentRequestData request) async {
  try {
    final result = await ref.read(paystackProvider).verify(
          reference: request.reference,
          expectedAmount: request.amount,
        );
    if (!result.paid) throw StateError('Payment has not been completed yet.');
    final db = ref.read(databaseProvider);
    await db.recordDebtPayment(
      debt,
      result.amount,
      'paystack:${result.channel ?? 'online'}',
      reference: result.reference,
    );
    await db.markPaymentRequestPaid(request.reference);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Payment confirmed')));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

Future<void> _pay(BuildContext context, WidgetRef ref, DebtData debt) async {
  final amountController = TextEditingController();
  final phoneController = TextEditingController();
  var method = 'cash';
  String? paystackReference;
  var busy = false;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Record debt payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Balance: ${money(debt.balance)}'),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: method,
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'momo', child: Text('MoMo')),
                DropdownMenuItem(
                    value: 'paystack', child: Text('Paystack online')),
              ],
              onChanged: busy
                  ? null
                  : (value) => setState(() {
                        method = value!;
                        paystackReference = null;
                      }),
            ),
            if (method == 'paystack') ...[
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Customer mobile number',
                  hintText: 'e.g. 024 123 4567',
                ),
              ),
              if (paystackReference != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Checkout opened. Complete payment, then verify it here.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    try {
                      final amount =
                          double.tryParse(amountController.text) ?? 0;
                      if (method == 'paystack') {
                        setState(() => busy = true);
                        final service = ref.read(paystackProvider);
                        if (paystackReference == null) {
                          if (phoneController.text
                                  .replaceAll(RegExp(r'\D'), '')
                                  .length <
                              9) {
                            throw StateError(
                                'Enter a valid customer mobile number.');
                          }
                          if (amount <= 0 || amount > debt.balance + 0.005) {
                            throw StateError('Enter a valid amount.');
                          }
                          final checkout = await service.initialize(
                            phone: phoneController.text,
                            amount: amount,
                            debtId: debt.id,
                            saleId: debt.saleId,
                          );
                          paystackReference = checkout.reference;
                          final opened = await launchUrl(
                            checkout.authorizationUrl,
                            mode: LaunchMode.externalApplication,
                          );
                          if (!opened) {
                            throw StateError(
                                'Could not open Paystack Checkout.');
                          }
                          setState(() => busy = false);
                          return;
                        }
                        final result = await service.verify(
                          reference: paystackReference!,
                          expectedAmount: amount,
                        );
                        if (!result.paid) {
                          throw StateError('Payment is not successful yet.');
                        }
                        await ref.read(databaseProvider).recordDebtPayment(
                              debt,
                              result.amount,
                              'paystack${result.channel == null ? '' : ':${result.channel}'}',
                              reference: result.reference,
                            );
                      } else {
                        await ref.read(databaseProvider).recordDebtPayment(
                              debt,
                              amount,
                              method,
                            );
                      }
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    } catch (error) {
                      if (dialogContext.mounted) setState(() => busy = false);
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext)
                            .showSnackBar(SnackBar(content: Text('$error')));
                      }
                    }
                  },
            child: Text(busy
                ? 'Please wait...'
                : method == 'paystack'
                    ? paystackReference == null
                        ? 'Open checkout'
                        : 'Verify payment'
                    : 'Save'),
          ),
        ],
      ),
    ),
  );
  amountController.dispose();
  phoneController.dispose();
}
