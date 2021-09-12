package com.dormmom.flutter_stripe_payment.models

class PaymentData()
{
    var merchantName: String? = null
    var currencyCode: String? = null
    var countryCode: String? = null
    var isProductionEnvironment: Boolean = false
    var paymentMethodId: String? = null
    var clientSecret: String? = null
    var paymentIntentId: String? = null
    var amount: Double? = null
}