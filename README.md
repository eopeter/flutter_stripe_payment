# flutter_stripe_payment

Add Stripe to your Flutter Application to Accept Card Payments using Payment Intents and the Latest SCA Compliance 3DS Requirements 

## Getting Started

Strong Customer Authentication (SCA), a new rule coming into effect on September 14, 2019, as part of PSD2 regulation in Europe, will require changes to how your European customers authenticate online payments. Card payments will require a different user experience, namely 3D Secure, in order to meet SCA requirements. Transactions that don’t follow the new authentication guidelines may be declined by your customers’ banks.

The Payment Intents API is a new way to build dynamic payment flows. It tracks the lifecycle of a customer checkout flow and triggers additional authentication steps when required by regulatory mandates, custom Radar fraud rules, or redirect-based payment methods. 


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

## To Do
- Android Implementation
- STPaymentCardTextField Inline Embedding
