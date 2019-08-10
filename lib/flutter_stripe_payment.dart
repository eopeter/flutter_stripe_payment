import 'dart:async';

import 'package:flutter/services.dart';

class FlutterStripePayment {
  static const MethodChannel _channel =
      const MethodChannel('flutter_stripe_payment');

  static Future<void> setStripeSettings(String stripePublishableKey,
      [String applePayMerchantIdentifier]) async {
    assert(stripePublishableKey != null);
    final Map<String, Object> args = <String, dynamic>{
      "stripePublishableKey": stripePublishableKey
    };
    if (applePayMerchantIdentifier != null) {
      args.addAll(<String, dynamic>{
        "applePayMerchantIdentifier": applePayMerchantIdentifier
      });
    }
    await _channel.invokeMethod('setStripeSettings', args);
  }

  static Future<String> addPaymentSource() async {
    var token = await _channel.invokeMethod('addPaymentSource');
    return token;
  }
}
