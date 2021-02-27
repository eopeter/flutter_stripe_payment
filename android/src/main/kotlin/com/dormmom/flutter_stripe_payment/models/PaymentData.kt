package com.dormmom.flutter_stripe_payment.models

class PaymentData(clientSecret: String,  amount: Double?, paymentIntentId: String, paymentMethodId: String)
{
    var paymentMethodId: String
    var clientSecret: String
    var paymentIntentId: String? = null
    var amount: Double? = null

    init {
        this.paymentMethodId = paymentMethodId
        this.clientSecret = clientSecret
        this.paymentIntentId = paymentIntentId
        this.amount = amount
    }
}