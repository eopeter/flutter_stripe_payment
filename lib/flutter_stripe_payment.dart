import 'dart:async';

import 'package:flutter/services.dart';

class FlutterStripePayment {
  static const MethodChannel _channel =
      const MethodChannel('flutter_stripe_payment');

  FlutterStripePayment() {
    _setupOutputCallbacks();
  }

  ///Called when user cancels the Payment Method form
  void Function() onCancel;

  //Listen for Errors
  Function(int errorCode, [String errorMessage]) onError;

  ///Configure the environment with your Stripe Publishable Keys and optional Apple Pay Identifiers
  Future<void> setStripeSettings(String stripePublishableKey,
      [String applePayMerchantIdentifier]) async {
    final Map<String, dynamic> args = <String, dynamic>{
      "stripePublishableKey": stripePublishableKey
    };
    if (applePayMerchantIdentifier != null) {
      args.addAll(<String, dynamic>{
        "applePayMerchantIdentifier": applePayMerchantIdentifier
      });
    }
    await _channel.invokeMethod('setStripeSettings', args);
  }

  ///Present the Payment Collection Form
  Future<PaymentResponse> addPaymentMethod() async {
    var response = await _channel.invokeMethod('addPaymentMethod');
    var paymentResponse = PaymentResponse.fromJson(response);
    return paymentResponse;
  }

  ///Use to process immediate payments
  Future<PaymentResponse> confirmPaymentIntent(
      String clientSecret, String stripePaymentMethodId, double amount,
      [bool isApplePay=false]) async {
    final Map<String, dynamic> args = <String, dynamic>{
      "clientSecret": clientSecret,
      "paymentMethodId": stripePaymentMethodId,
      "amount": amount,
      "isApplePay": isApplePay ?? false
    };
    var response = await _channel.invokeMethod('confirmPaymentIntent', args);
    var paymentResponse = PaymentResponse.fromJson(response);
    return paymentResponse;
  }

  ///Use to setup future payments
  Future<PaymentResponse> setupPaymentIntent(
      String clientSecret, String stripePaymentMethodId,
      [bool isApplePay=false]) async {
    final Map<String, dynamic> args = <String, dynamic>{
      "clientSecret": clientSecret,
      "paymentMethodId": stripePaymentMethodId,
      "isApplePay": isApplePay ?? false
    };
    var response = await _channel.invokeMethod('setupPaymentIntent', args);
    var paymentResponse = PaymentResponse.fromJson(response);
    return paymentResponse;
  }

  dispose() => _channel.setMethodCallHandler(null);

  /// Sets up the bridge to the native iOS and Android implementations.
  _setupOutputCallbacks() {
    Future<void> platformCallHandler(MethodCall call) async {
      // print('Output Callback: ${call.method}');
      switch (call.method) {
        case 'onCancel':
          onCancel?.call();
          break;
        case 'onError':
          final Map error = call.arguments;
          final int code = error['code'];
          final String message = error['message'];
          onError?.call(code, message);
          break;
        default:
          print('Unknown method ${call.method}');
      }
    }

    _channel.setMethodCallHandler(platformCallHandler);
  }
}

class PaymentResponse {
  PaymentResponseStatus status;
  String paymentIntentId;
  String paymentMethodId;
  String errorMessage;

  PaymentResponse.fromJson(Map json) {
    this.paymentIntentId = json["paymentIntentId"] as String;
    this.paymentMethodId = json["paymentMethodId"] as String;
    this.errorMessage = json["errorMessage"] as String;
    this.status =
        _$enumDecodeNullable(_$PaymentResponseStatusEnumMap, json['status']);
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

  final _$PaymentResponseStatusEnumMap = <PaymentResponseStatus, dynamic>{
    PaymentResponseStatus.succeeded: 'succeeded',
    PaymentResponseStatus.failed: 'failed',
    PaymentResponseStatus.canceled: 'canceled'
  };
}

enum PaymentResponseStatus { succeeded, failed, canceled }
