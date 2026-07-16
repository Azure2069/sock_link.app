import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/utils.dart';
import '../../core/database/app_database.dart';
import '../home/home_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});
  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  BusinessData? business;
  bool loading = true;
  bool unlocked = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final b = await ref.read(databaseProvider).getBusiness();
      if (mounted)
        setState(() {
          business = b;
          loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          error = e.toString();
          loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null)
      return Scaffold(
          body: Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Database error:\n$error'))));
    if (business == null)
      return RegistrationScreen(
          onDone: (b) => setState(() {
                business = b;
                unlocked = true;
              }));
    if (!unlocked)
      return LoginScreen(
          business: business!, onDone: () => setState(() => unlocked = true));
    return HomeScreen(
        business: business!, onLock: () => setState(() => unlocked = false));
  }
}

class RegistrationScreen extends ConsumerStatefulWidget {
  final ValueChanged<BusinessData> onDone;
  const RegistrationScreen({super.key, required this.onDone});
  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      owner = TextEditingController(),
      phone = TextEditingController(),
      location = TextEditingController(),
      pin = TextEditingController(),
      confirm = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    for (final c in [name, owner, phone, location, pin, confirm]) c.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    final db = ref.read(databaseProvider);
    final id = await db.into(db.businesses).insert(BusinessesCompanion.insert(
        name: name.text.trim(),
        ownerName: owner.text.trim(),
        phone: phone.text.trim(),
        location: Value(location.text.trim()),
        pinHash: hashPin(pin.text)));
    final b = await (db.select(db.businesses)..where((t) => t.id.equals(id)))
        .getSingle();
    widget.onDone(b);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
          child: Center(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Form(
                          key: form,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Icon(Icons.storefront,
                                    size: 72,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                const SizedBox(height: 12),
                                Text('Set up Market Mate',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 24),
                                TextFormField(
                                    controller: name,
                                    decoration: const InputDecoration(
                                        labelText: 'Business name'),
                                    validator: req),
                                const SizedBox(height: 12),
                                TextFormField(
                                    controller: owner,
                                    decoration: const InputDecoration(
                                        labelText: 'Owner / manager name'),
                                    validator: req),
                                const SizedBox(height: 12),
                                TextFormField(
                                    controller: phone,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                        labelText: 'Phone number'),
                                    validator: req),
                                const SizedBox(height: 12),
                                TextFormField(
                                    controller: location,
                                    decoration: const InputDecoration(
                                        labelText: 'Location (optional)')),
                                const SizedBox(height: 12),
                                TextFormField(
                                    controller: pin,
                                    obscureText: true,
                                    keyboardType: TextInputType.number,
                                    maxLength: 4,
                                    decoration: const InputDecoration(
                                        labelText: 'Create 4-digit PIN'),
                                    validator: (v) =>
                                        RegExp(r'^\d{4}$').hasMatch(v ?? '')
                                            ? null
                                            : 'Enter exactly 4 digits'),
                                const SizedBox(height: 12),
                                TextFormField(
                                    controller: confirm,
                                    obscureText: true,
                                    keyboardType: TextInputType.number,
                                    maxLength: 4,
                                    decoration: const InputDecoration(
                                        labelText: 'Confirm PIN'),
                                    validator: (v) => v == pin.text
                                        ? null
                                        : 'PINs do not match'),
                                const SizedBox(height: 20),
                                FilledButton(
                                    onPressed: busy ? null : save,
                                    child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Text(busy
                                            ? 'Creating...'
                                            : 'Create account'))),
                              ])))))));
}

class LoginScreen extends StatefulWidget {
  final BusinessData business;
  final VoidCallback onDone;
  const LoginScreen({super.key, required this.business, required this.onDone});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final pin = TextEditingController();
  String? error;
  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  void login() {
    if (hashPin(pin.text) == widget.business.pinHash) {
      widget.onDone();
    } else {
      setState(() => error = 'Incorrect PIN');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.lock_outline, size: 68),
                        const SizedBox(height: 16),
                        Text(widget.business.name,
                            style: Theme.of(context).textTheme.headlineMedium,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        const Text('Enter your 4-digit PIN',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        TextField(
                            controller: pin,
                            autofocus: true,
                            obscureText: true,
                            maxLength: 4,
                            keyboardType: TextInputType.number,
                            onSubmitted: (_) => login(),
                            decoration: InputDecoration(
                                labelText: 'PIN', errorText: error)),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: login,
                            child: const Padding(
                                padding: EdgeInsets.all(14),
                                child: Text('Unlock')))
                      ])))));
}

String? req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
