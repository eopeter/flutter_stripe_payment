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

  @override
  void initState() {
    super.initState();
    FlutterStripePayment.setStripeSettings("{STRIPE_PUBLISHABLE_KEY}","{STRIPE_APPLE_PAY_MERCHANTID}");
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
            _paymentMethodId != null ? Text("Payment Method Returned is $_paymentMethodId", textAlign: TextAlign.center,) : Container(),
            RaisedButton(child: Text("Add Card"), onPressed: () async{
              var paymentResponse = await FlutterStripePayment.addPaymentMethod();
              setState(() {
                _paymentMethodId = paymentResponse.paymentMethodId;
              });
            },)
          ],),
        ),
      ),
    );
  }
}
