# flutter_stripe_payment_example

Demonstrates how to use the flutter_stripe_payment plugin.


## Setup Stripe Environment

```dart
FlutterStripePayment.setStripeSettings(
        appConfig.values.stripePublishableKey,
        appConfig.values.applePayMerchantId);
```

## Show Payment Form

```dart
var paymentMethodId = await FlutterStripePayment.addPaymentMethod();
```

## Confirm Payment Intent to Kick Off 3D Authentication

```dart
var intentResponse = await FlutterStripePayment.confirmPaymentIntent(
          response.clientSecret, widget.order.cart.total);

      if (intentResponse.status == PaymentIntentResponseStatus.succeeded) {
        widget.order.paymentIntentId = intentResponse.paymentIntentId;
        widget.order.paymentMethodId = paymentMethodId;
        _submitOrder();
      } else if (intentResponse.status == PaymentIntentResponseStatus.failed) {
        setState(() {
          hideBusy();
        });
        globals.Utility.showAlertPopup(
            context, "Error Occurred", intentResponse.errorMessage);
      } else {
        setState(() {
          hideBusy();
        });
      }
```

## Setup Payment Intent For Future Payments

```dart
var intentResponse = await FlutterStripePayment.setupPaymentIntent(
        response.clientSecret, paymentMethodId);

    if (intentResponse.status == PaymentIntentResponseStatus.succeeded) {
      await _addCardToAccount(paymentMethodId);
    } else if (intentResponse.status == PaymentIntentResponseStatus.failed) {
      setState(() {
        hideBusy();
      });
      globals.Utility.showAlertPopup(
          context, "Error Occurred", intentResponse.errorMessage);
    } else {
      setState(() {
        hideBusy();
      });
    }
```
