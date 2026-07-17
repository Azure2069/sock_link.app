import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DataClassName('BusinessData')
class Businesses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get ownerName => text()();
  TextColumn get phone => text()();
  TextColumn get location => text().withDefault(const Constant(''))();
  TextColumn get currency => text().withDefault(const Constant('GHS'))();
  RealColumn get taxRate => real().withDefault(const Constant(0))();
  TextColumn get pinHash => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('CategoryData')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

@DataClassName('ProductData')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get sku => text().nullable()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  RealColumn get costPrice => real()();
  RealColumn get sellingPrice => real()();
  RealColumn get quantity => real().withDefault(const Constant(0))();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  RealColumn get minimumStock => real().withDefault(const Constant(0))();
  IntColumn get supplierId => integer().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('CustomerData')
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

@DataClassName('SupplierData')
class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

@DataClassName('SaleData')
class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text().unique()();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  RealColumn get subtotal => real()();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get tax => real().withDefault(const Constant(0))();
  RealColumn get total => real()();
  RealColumn get paid => real().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('paid'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('SaleItemData')
class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId =>
      integer().references(Sales, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get costPrice => real()();
  RealColumn get total => real()();
}

@DataClassName('PaymentData')
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId =>
      integer().references(Sales, #id, onDelete: KeyAction.cascade)();
  TextColumn get method => text()();
  RealColumn get amount => real()();
  TextColumn get network => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get reference => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('DebtData')
class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId =>
      integer().references(Sales, #id, onDelete: KeyAction.cascade)();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  RealColumn get originalAmount => real()();
  RealColumn get balance => real()();
  TextColumn get status => text().withDefault(const Constant('outstanding'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('DebtPaymentData')
class DebtPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get debtId =>
      integer().references(Debts, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real()();
  TextColumn get method => text().withDefault(const Constant('cash'))();
  TextColumn get reference => text().nullable().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('PaymentRequestData')
class PaymentRequests extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get debtId =>
      integer().references(Debts, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real()();
  TextColumn get phone => text()();
  TextColumn get reference => text().unique()();
  TextColumn get authorizationUrl => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ExpenseData')
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()();
  RealColumn get amount => real()();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('StockMovementData')
class StockMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  RealColumn get quantity => real()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [
  Businesses,
  Categories,
  Products,
  Customers,
  Suppliers,
  Sales,
  SaleItems,
  Payments,
  Debts,
  DebtPayments,
  PaymentRequests,
  Expenses,
  StockMovements
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await customStatement(
                'ALTER TABLE debt_payments ADD COLUMN reference TEXT');
            await customStatement(
              'CREATE UNIQUE INDEX debt_payments_reference_unique '
              'ON debt_payments (reference)',
            );
          }
          if (from < 3) await m.createTable(paymentRequests);
        },
        beforeOpen: (_) => _seedGroceryCatalogue(),
      );

  /// Adds presentation-ready stock to a new or otherwise empty shop.
  ///
  /// Existing catalogues are left untouched, so reopening the app never
  /// duplicates products that a shop owner has already added.
  Future<void> _seedGroceryCatalogue() async {
    if ((await select(products).get()).isNotEmpty) return;

    const catalogue = <_SeedProduct>[
      _SeedProduct('Royal Aroma Rice 5kg', 'RICE-ROYAL-5KG', 'Grains & Staples',
          105, 125, 24, 'bags', 5),
      _SeedProduct('Gino Tomato Paste 210g', 'GINO-TP-210G', 'Canned Foods',
          8.50, 11, 48, 'tins', 12),
      _SeedProduct('Frytol Vegetable Oil 1L', 'FRYTOL-OIL-1L',
          'Cooking Essentials', 29, 35, 30, 'bottles', 8),
      _SeedProduct('Lele Tasty Rice 5kg', 'LELE-RICE-5KG', 'Grains & Staples',
          92, 110, 20, 'bags', 5),
      _SeedProduct('Oba Spaghetti 500g', 'OBA-SPAG-500G', 'Grains & Staples',
          10, 13, 40, 'packs', 10),
      _SeedProduct('Tasty Tom Jollof Mix 400g', 'TT-JOLLOF-400G',
          'Canned Foods', 15, 19, 32, 'tins', 8),
      _SeedProduct('Ideal Milk 400g', 'IDEAL-MILK-400G', 'Dairy & Breakfast',
          16, 20, 36, 'tins', 10),
      _SeedProduct('Nido Milk Powder 400g', 'NIDO-400G', 'Dairy & Breakfast',
          55, 65, 18, 'tins', 5),
      _SeedProduct(
          'Milo 400g', 'MILO-400G', 'Dairy & Breakfast', 40, 48, 24, 'tins', 6),
      _SeedProduct('Quaker Oats 500g', 'QUAKER-500G', 'Dairy & Breakfast', 25,
          31, 20, 'packs', 5),
      _SeedProduct('Geisha Bathing Soap 225g', 'GEISHA-225G',
          'Household & Personal Care', 9, 12, 48, 'bars', 12),
      _SeedProduct('Key Soap 200g', 'KEY-SOAP-200G',
          'Household & Personal Care', 7, 9.50, 36, 'bars', 10),
      _SeedProduct('So Klin Washing Powder 900g', 'SOKLIN-900G',
          'Household & Personal Care', 26, 32, 20, 'packs', 5),
      _SeedProduct('Pepsodent Toothpaste 140g', 'PEPS-140G',
          'Household & Personal Care', 16, 20, 25, 'tubes', 6),
      _SeedProduct('Voltic Mineral Water 1.5L', 'VOLTIC-1.5L', 'Drinks', 6, 8,
          60, 'bottles', 15),
      _SeedProduct(
          'Coca-Cola 500ml', 'COKE-500ML', 'Drinks', 7, 9, 48, 'bottles', 12),
      _SeedProduct('Blue Skies Pineapple Juice 1L', 'BS-PINE-1L', 'Drinks', 28,
          35, 16, 'cartons', 4),
      _SeedProduct('Plantain Chips 80g', 'PLANTAIN-CHIPS-80G', 'Snacks', 6, 8,
          35, 'packs', 10),
      _SeedProduct('McVitie\'s Digestive Biscuits 250g', 'MCV-DIG-250G',
          'Snacks', 18, 23, 24, 'packs', 6),
      _SeedProduct('Fresh Eggs (Crate of 30)', 'EGGS-CRATE-30', 'Fresh Foods',
          52, 65, 12, 'crates', 3),
      _SeedProduct(
          'Local Onions 1kg', 'ONION-1KG', 'Fresh Foods', 14, 18, 25, 'kg', 6),
      _SeedProduct('Fresh Tomatoes 1kg', 'TOMATO-1KG', 'Fresh Foods', 18, 24,
          22, 'kg', 5),
    ];

    await transaction(() async {
      final categoryIds = <String, int>{};
      for (final item in catalogue) {
        if (!categoryIds.containsKey(item.category)) {
          await into(categories).insert(
            CategoriesCompanion.insert(name: item.category),
            mode: InsertMode.insertOrIgnore,
          );
          categoryIds[item.category] = await (select(categories)
                ..where((row) => row.name.equals(item.category)))
              .map((row) => row.id)
              .getSingle();
        }

        final productId = await into(products).insert(
          ProductsCompanion.insert(
            name: item.name,
            sku: Value(item.sku),
            categoryId: Value(categoryIds[item.category]),
            costPrice: item.costPrice,
            sellingPrice: item.sellingPrice,
            quantity: Value(item.quantity),
            unit: Value(item.unit),
            minimumStock: Value(item.minimumStock),
            notes: const Value('Demo grocery stock'),
          ),
        );
        await into(stockMovements).insert(
          StockMovementsCompanion.insert(
            productId: productId,
            type: 'opening',
            quantity: item.quantity,
            note: const Value('Demo catalogue opening stock'),
          ),
        );
      }
    });
  }

  Future<BusinessData?> getBusiness() => select(businesses).getSingleOrNull();
  Stream<List<ProductData>> watchProducts() =>
      (select(products)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  Stream<List<CategoryData>> watchCategories() =>
      (select(categories)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  Stream<List<CustomerData>> watchCustomers() =>
      (select(customers)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  Stream<List<SupplierData>> watchSuppliers() =>
      (select(suppliers)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  Stream<List<SaleData>> watchSales() =>
      (select(sales)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  Stream<List<DebtData>> watchDebts() =>
      (select(debts)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  Stream<List<PaymentRequestData>> watchPaymentRequests() =>
      (select(paymentRequests)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();
  Stream<List<ExpenseData>> watchExpenses() =>
      (select(expenses)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<int> createSale({
    required int? customerId,
    required List<CartLine> lines,
    required double discount,
    required double taxRate,
    required List<PaymentInput> paymentInputs,
  }) =>
      transaction(() async {
        if (lines.isEmpty) throw StateError('Add at least one product.');
        for (final line in lines) {
          final product = await (select(products)
                ..where((t) => t.id.equals(line.product.id)))
              .getSingle();
          if (line.quantity <= 0 || line.quantity > product.quantity) {
            throw StateError('Not enough stock for ${product.name}.');
          }
        }
        final subtotal = lines.fold<double>(
            0, (s, l) => s + l.quantity * l.product.sellingPrice);
        final taxable =
            (subtotal - discount).clamp(0, double.infinity).toDouble();
        final tax = taxable * taxRate / 100;
        final total = taxable + tax;
        final paid = paymentInputs
            .fold<double>(0, (s, p) => s + p.amount)
            .clamp(0, total)
            .toDouble();
        final status = paid >= total - 0.005
            ? 'paid'
            : paid > 0
                ? 'partial'
                : 'credit';
        final invoice = 'MM-${DateTime.now().millisecondsSinceEpoch}';
        final saleId = await into(sales).insert(SalesCompanion.insert(
          invoiceNumber: invoice,
          customerId: Value(customerId),
          subtotal: subtotal,
          discount: Value(discount),
          tax: Value(tax),
          total: total,
          paid: Value(paid),
          status: Value(status),
        ));
        for (final line in lines) {
          await into(saleItems).insert(SaleItemsCompanion.insert(
            saleId: saleId,
            productId: line.product.id,
            productName: line.product.name,
            quantity: line.quantity,
            unitPrice: line.product.sellingPrice,
            costPrice: line.product.costPrice,
            total: line.quantity * line.product.sellingPrice,
          ));
          await (update(products)..where((t) => t.id.equals(line.product.id)))
              .write(
            ProductsCompanion(
                quantity: Value(line.product.quantity - line.quantity)),
          );
          await into(stockMovements).insert(StockMovementsCompanion.insert(
            productId: line.product.id,
            type: 'sale',
            quantity: -line.quantity,
            note: Value(invoice),
          ));
        }
        for (final pay in paymentInputs.where((p) => p.amount > 0)) {
          await into(payments).insert(PaymentsCompanion.insert(
            saleId: saleId,
            method: pay.method,
            amount: pay.amount,
            network: Value(pay.network),
            phone: Value(pay.phone),
            reference: Value(pay.reference),
          ));
        }
        if (paid < total - 0.005) {
          if (customerId == null)
            throw StateError('Select a customer for a credit sale.');
          await into(debts).insert(DebtsCompanion.insert(
            saleId: saleId,
            customerId: Value(customerId),
            originalAmount: total - paid,
            balance: total - paid,
          ));
        }
        return saleId;
      });

  Future<void> recordDebtPayment(
    DebtData debt,
    double amount,
    String method, {
    String? reference,
  }) =>
      transaction(() async {
        if (amount <= 0 || amount > debt.balance + 0.005)
          throw StateError('Enter a valid amount.');
        final newBalance =
            (debt.balance - amount).clamp(0, double.infinity).toDouble();
        await into(debtPayments).insert(DebtPaymentsCompanion.insert(
          debtId: debt.id,
          amount: amount,
          method: Value(method),
          reference: Value(reference),
        ));
        await (update(debts)..where((t) => t.id.equals(debt.id)))
            .write(DebtsCompanion(
          balance: Value(newBalance),
          status: Value(newBalance <= 0.005 ? 'paid' : 'outstanding'),
        ));
        final sale = await (select(sales)
              ..where((t) => t.id.equals(debt.saleId)))
            .getSingle();
        await (update(sales)..where((t) => t.id.equals(sale.id)))
            .write(SalesCompanion(
          paid: Value((sale.paid + amount).clamp(0, sale.total).toDouble()),
          status: Value(
              sale.paid + amount >= sale.total - 0.005 ? 'paid' : 'partial'),
        ));
      });

  Future<void> savePaymentRequest({
    required int debtId,
    required double amount,
    required String phone,
    required String reference,
    required String authorizationUrl,
  }) =>
      into(paymentRequests).insert(PaymentRequestsCompanion.insert(
        debtId: debtId,
        amount: amount,
        phone: phone,
        reference: reference,
        authorizationUrl: authorizationUrl,
      ));

  Future<void> markPaymentRequestPaid(String reference) =>
      (update(paymentRequests)..where((t) => t.reference.equals(reference)))
          .write(const PaymentRequestsCompanion(status: Value('paid')));

  Future<double> todaySalesTotal() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final rows = await (select(sales)
          ..where((t) => t.createdAt.isBiggerOrEqualValue(start)))
        .get();
    return rows.fold<double>(0, (s, r) => s + r.total);
  }

  Future<double> todayProfit() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final todaysSales = await (select(sales)
          ..where((t) => t.createdAt.isBiggerOrEqualValue(start)))
        .get();
    double profit = 0;
    for (final sale in todaysSales) {
      final items = await (select(saleItems)
            ..where((t) => t.saleId.equals(sale.id)))
          .get();
      profit += items.fold<double>(
          0, (s, i) => s + (i.unitPrice - i.costPrice) * i.quantity);
      profit -= sale.discount;
    }
    return profit;
  }

  Future<double> outstandingDebtTotal() async {
    final rows = await (select(debts)
          ..where((t) => t.status.equals('outstanding')))
        .get();
    return rows.fold<double>(0, (s, r) => s + r.balance);
  }

  Future<double> inventoryValue() async {
    final rows = await select(products).get();
    return rows.fold<double>(0, (s, r) => s + r.costPrice * r.quantity);
  }

  Future<List<SaleItemData>> saleItemsFor(int saleId) =>
      (select(saleItems)..where((t) => t.saleId.equals(saleId))).get();
  Future<List<PaymentData>> paymentsFor(int saleId) =>
      (select(payments)..where((t) => t.saleId.equals(saleId))).get();
}

class CartLine {
  final ProductData product;
  final double quantity;
  const CartLine(this.product, this.quantity);
}

class PaymentInput {
  final String method;
  final double amount;
  final String? network;
  final String? phone;
  final String? reference;
  const PaymentInput(
      {required this.method,
      required this.amount,
      this.network,
      this.phone,
      this.reference});
}

class _SeedProduct {
  final String name;
  final String sku;
  final String category;
  final double costPrice;
  final double sellingPrice;
  final double quantity;
  final String unit;
  final double minimumStock;

  const _SeedProduct(
    this.name,
    this.sku,
    this.category,
    this.costPrice,
    this.sellingPrice,
    this.quantity,
    this.unit,
    this.minimumStock,
  );
}

LazyDatabase _openConnection() => LazyDatabase(() async {
      final dir = await getApplicationSupportDirectory();
      if (!await dir.exists()) await dir.create(recursive: true);
      return NativeDatabase.createInBackground(
          File(p.join(dir.path, 'sokko_link.sqlite')));
    });
