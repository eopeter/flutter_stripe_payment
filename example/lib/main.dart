import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_stripe_payment/flutter_stripe_payment.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _paymentMethodId;
  String _errorMessage = "";
  final _stripePayment = FlutterStripePayment();

  @override
  void initState() {
    super.initState();
    _stripePayment.setStripeSettings(
        "{STRIPE_PUBLISHABLE_KEY}", "{STRIPE_APPLE_PAY_MERCHANTID}");
    _stripePayment.onCancel = () {
      print("the payment form was cancelled");
    };
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
                      child: Text(_errorMessage),
                    ),
              RaisedButton(
                child: Text("Add Card"),
                onPressed: () async {
                  var paymentResponse = await _stripePayment.addPaymentMethod();
                  setState(() {
                    if (paymentResponse.status ==
                        PaymentResponseStatus.succeeded) {
                      _paymentMethodId = paymentResponse.paymentMethodId;
                    } else {
                      _errorMessage = paymentResponse.errorMessage;
                    }
                  });
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
