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

  static Future<String> addPaymentMethod() async {
    var token = await _channel.invokeMethod('addPaymentMethod');
    return token;
  }

  ///Use to process immediate payments
  static Future<PaymentIntentResponse> confirmPaymentIntent(String clientSecret, double amount, [bool isApplePay]) async
  {
    assert(clientSecret != null);
    assert(amount != null);

    final Map<String, Object> args = <String, dynamic>{
      "clientSecret": clientSecret, "amount" : amount, "isApplePay" : isApplePay?? false
    };
    var response = await _channel.invokeMethod('confirmPaymentIntent', args);
    var paymentIntentReponse = PaymentIntentResponse.fromJson(response);
    return paymentIntentReponse;
  }

  ///Use to setup future payments
  static Future<PaymentIntentResponse> setupPaymentIntent(String clientSecret, String stripePaymentMethodId, [bool isApplePay]) async
  {
    assert(clientSecret != null);
    assert(stripePaymentMethodId != null);
    final Map<String, Object> args = <String, dynamic>{ "clientSecret": clientSecret, "paymentMethodId" : stripePaymentMethodId, "isApplePay" : isApplePay?? false
    };
    var response = await _channel.invokeMethod('setupPaymentIntent', args);
    var paymentIntentReponse = PaymentIntentResponse.fromJson(response);
    return paymentIntentReponse;
  }

}

class PaymentIntentResponse
{
  PaymentIntentResponseStatus status;
  String paymentIntentId;
  String errorMessage;

  PaymentIntentResponse.fromJson(Map json){
    this.paymentIntentId = json["paymentIntentId"] as String;
    this.errorMessage = json["errorMessage"] as String;
    this.status = _$enumDecodeNullable(_$PaymentIntentResponseStatusEnumMap, json['status']);
  }

 T _$enumDecodeNullable<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source);
 }

T _$enumDecode<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }
  return enumValues.entries
      .singleWhere((e) => e.value == source,
          orElse: () => throw ArgumentError(
              '`$source` is not one of the supported values: '
              '${enumValues.values.join(', ')}'))
      .key;
}

 final _$PaymentIntentResponseStatusEnumMap = <PaymentIntentResponseStatus, dynamic>{
  PaymentIntentResponseStatus.succeeded: 'succeeded',
  PaymentIntentResponseStatus.failed: 'failed',
  PaymentIntentResponseStatus.canceled: 'canceled'
 };

}

enum PaymentIntentResponseStatus
{
    succeeded,
    failed,
    canceled
}
