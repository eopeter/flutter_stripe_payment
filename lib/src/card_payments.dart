import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'enums/enums.dart';
import 'models/models.dart';

class FlutterStripePayment {
  static const MethodChannel _channel =
      const MethodChannel('flutter_stripe_payment');

  FlutterStripePayment() {
    _setupOutputCallbacks();
  }

  ///Called when user cancels the Payment Method form
  void Function()? onCancel;

  //Listen for Errors
  Function(int errorCode, [String errorMessage])? onError;

  ///Configure the environment with your Stripe Publishable Keys and optional Apple Pay Identifiers
  Future<void> setStripeSettings(String stripePublishableKey,
      [String? applePayMerchantIdentifier]) async {
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
      [bool isApplePay = false]) async {
    final Map<String, dynamic> args = <String, dynamic>{
      "clientSecret": clientSecret,
      "paymentMethodId": stripePaymentMethodId,
      "amount": amount,
      "isApplePay": isApplePay
    };
    var response = await _channel.invokeMethod('confirmPaymentIntent', args);
    var paymentResponse = PaymentResponse.fromJson(response);
    return paymentResponse;
  }

  ///Use to setup future payments
  Future<PaymentResponse> setupPaymentIntent(
      String clientSecret, String stripePaymentMethodId,
      [bool isApplePay = false]) async {
    final Map<String, dynamic> args = <String, dynamic>{
      "clientSecret": clientSecret,
      "paymentMethodId": stripePaymentMethodId,
      "isApplePay": isApplePay
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

  Future<bool> preparePaymentSheet({
    required String merchantDisplayName,
    required String customerId,
    required String customerEphemeralKeySecret,
    required String paymentIntentClientSecret,
  }) async {
    final Map<String, dynamic> args = <String, dynamic>{
      'customerId': customerId,
      'merchantName': merchantDisplayName,
      'customerEphemeralKeySecret': customerEphemeralKeySecret,
      'paymentIntentClientSecret': paymentIntentClientSecret
    };
    var success = await _channel.invokeMethod('preparePaymentSheet', args);
    return (success as String == "true");
  }

  Future<PaymentResponse> showPaymentSheet() async {
    var response = await _channel.invokeMethod('showPaymentSheet', null);
    var paymentResponse = PaymentResponse.fromJson(response);
    return paymentResponse;
  }

  Future<dynamic> getTokenFromApplePay(
      {required String countryCode,
      required String currencyCode,
      required List<PaymentNetwork> paymentNetworks,
      required String merchantName,
      bool isPending = false,
      required List<PaymentItem> paymentItems}) async {
    final Map<String, dynamic> args = <String, dynamic>{
      'paymentNetworks':
          paymentNetworks.map((item) => item.toString().split('.')[1]).toList(),
      'countryCode': countryCode,
      'currencyCode': currencyCode,
      'paymentItems':
          paymentItems.map((PaymentItem item) => item.toMap()).toList(),
      'merchantName': merchantName,
      'isPending': isPending
    };
    if (Platform.isIOS) {
      final dynamic stripeToken =
          await _channel.invokeMethod('getTokenFromApplePay', args);
      return stripeToken;
    } else {
      throw Exception("Apple Pay Only Available on iOS for Now");
    }
  }

  // closeApplePaySheet closes an open ApplePay sheet
  Future<void> closeApplePaySheet({required bool isSuccess}) async {
    if (Platform.isIOS) {
      if (isSuccess) {
        await _channel.invokeMethod('closeApplePaySheetWithSuccess');
      } else {
        await _channel.invokeMethod('closeApplePaySheetWithError');
      }
    } else {
      throw Exception("Not supported operation system");
    }
  }
}
