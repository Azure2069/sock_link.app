import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/app_database.dart';
import 'payments/paystack_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final paystackProvider = Provider<PaystackService>((ref) => PaystackService());

final productsProvider =
    StreamProvider((ref) => ref.watch(databaseProvider).watchProducts());
final categoriesProvider =
    StreamProvider((ref) => ref.watch(databaseProvider).watchCategories());
final customersProvider =
    StreamProvider((ref) => ref.watch(databaseProvider).watchCustomers());
final suppliersProvider =
    StreamProvider((ref) => ref.watch(databaseProvider).watchSuppliers());
final salesProvider =
    StreamProvider((ref) => ref.watch(databaseProvider).watchSales());
final debtsProvider =
    StreamProvider((ref) => ref.watch(databaseProvider).watchDebts());
final paymentRequestsProvider =
    StreamProvider((ref) => ref.watch(databaseProvider).watchPaymentRequests());
final expensesProvider =
    StreamProvider((ref) => ref.watch(databaseProvider).watchExpenses());
