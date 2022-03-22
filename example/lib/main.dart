import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_stripe_payment/flutter_stripe_payment.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _paymentMethodId;
  String? _errorMessage = "";
  final _stripePayment = FlutterStripePayment();
  var _isNativePayAvailable = false;

  @override
  void initState() {
    super.initState();
    _stripePayment.setStripeSettings("{STRIPE_PUBLISHABLE_KEY}", "{STRIPE_APPLE_PAY_MERCHANTID}");
    _stripePayment.onCancel = () {
      print("the payment form was cancelled");
    };
    checkIfAppleOrGooglePayIsAvailable();
  }

  void checkIfAppleOrGooglePayIsAvailable() async {
    var available = await _stripePayment.isNativePayAvailable();
    setState(() {
      _isNativePayAvailable = available;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Stripe App Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _paymentMethodId != null
                  ? Text(
                      "Payment Method Returned is $_paymentMethodId",
                      textAlign: TextAlign.center,
                    )
                  : Container(
                      child: Text(_errorMessage!),
                    ),
              ElevatedButton(
                child: Text("Create a Card Payment Method"),
                onPressed: () async {
                  var paymentResponse = await _stripePayment.addPaymentMethod();
                  setState(() {
                    if (paymentResponse.status == PaymentResponseStatus.succeeded) {
                      _paymentMethodId = paymentResponse.paymentMethodId;
                    } else {
                      _errorMessage = paymentResponse.errorMessage;
                    }
                  });
                },
              ),
              ElevatedButton(
                child:
                    Text("Get ${Platform.isIOS ? "Apple" : (Platform.isAndroid ? "Google" : "Native")} Pay Token"),
                onPressed: !_isNativePayAvailable
                    ? null
                    : () async {
                        var paymentItem = PaymentItem(label: 'Air Jordan Kicks', amount: 249.99);
                        var taxItem = PaymentItem(label: 'NY Sales Tax', amount: 21.87);
                        var shippingItem = PaymentItem(label: 'Shipping', amount: 5.99);
                        var stripeToken = await _stripePayment.getPaymentMethodFromNativePay(
                            countryCode: "US",
                            currencyCode: "USD",
                            paymentNetworks: [
                              PaymentNetwork.visa,
                              PaymentNetwork.mastercard,
                              PaymentNetwork.amex,
                              PaymentNetwork.discover
                            ],
                            merchantName: "Nike Inc.",
                            isPending: false,
                            paymentItems: [paymentItem, shippingItem, taxItem]);
                        print("Stripe Payment Token from Apple Pay: $stripeToken");
                      },
              )
            ],
          ),
        ),
      ),
    );
  }
}
