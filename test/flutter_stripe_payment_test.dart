import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_stripe_payment/flutter_stripe_payment.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_stripe_payment');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    //expect(await FlutterStripePayment.platformVersion, '42');
  });
}
