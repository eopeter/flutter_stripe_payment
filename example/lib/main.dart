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
  String _stripeToken;

  @override
  void initState() {
    super.initState();
    FlutterStripePayment.setStripeSettings("pk_test_tnUMOmoHd9fG7SdGAhzn9R8q","merchant.com.dormmom.store");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Stipe App Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
            _stripeToken != null ? Text("Stripe Token Returned is $_stripeToken", textAlign: TextAlign.center,) : Container(),
            RaisedButton(child: Text("Add Card"), onPressed: () async{
              var token = await FlutterStripePayment.addPaymentSource();
              setState(() {
                _stripeToken = token;
              });
            },)
          ],),
        ),
      ),
    );
  }
}
