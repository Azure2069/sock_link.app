import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_config.dart';

class PaystackCheckout {
  final Uri authorizationUrl;
  final String reference;

  const PaystackCheckout({
    required this.authorizationUrl,
    required this.reference,
  });
}

class PaystackVerification {
  final bool paid;
  final double amount;
  final String reference;
  final String? channel;

  const PaystackVerification({
    required this.paid,
    required this.amount,
    required this.reference,
    this.channel,
  });
}

class PaystackService {
  bool get isConfigured {
    return AppConfig.supabaseUrl.isNotEmpty &&
        AppConfig.supabasePublishableKey.isNotEmpty;
  }

  SupabaseClient get _client {
    if (!isConfigured) {
      throw StateError(
        'Paystack is not configured. Start the app with SUPABASE_URL and '
        'SUPABASE_PUBLISHABLE_KEY dart-defines.',
      );
    }
    return Supabase.instance.client;
  }

  Future<PaystackCheckout> initialize({
    required String phone,
    required double amount,
    required int debtId,
    required int saleId,
  }) async {
    final response = await _client.functions.invoke(
      'paystack',
      body: {
        'action': 'initialize',
        'phone': phone.trim(),
        'amount': amount,
        'debtId': debtId,
        'saleId': saleId,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['ok'] != true) {
      throw StateError(
          data['message']?.toString() ?? 'Could not start payment.');
    }
    return PaystackCheckout(
      authorizationUrl: Uri.parse(data['authorizationUrl'] as String),
      reference: data['reference'] as String,
    );
  }

  Future<PaystackVerification> verify({
    required String reference,
    required double expectedAmount,
  }) async {
    final response = await _client.functions.invoke(
      'paystack',
      body: {
        'action': 'verify',
        'reference': reference,
        'expectedAmount': expectedAmount,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return PaystackVerification(
      paid: data['paid'] == true,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      reference: data['reference']?.toString() ?? reference,
      channel: data['channel']?.toString(),
    );
  }
}
