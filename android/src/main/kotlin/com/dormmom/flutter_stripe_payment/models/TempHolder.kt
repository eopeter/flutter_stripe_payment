package com.dormmom.flutter_stripe_payment.models

import io.flutter.plugin.common.MethodChannel

object TempHolder {
    private var flutterResult: MethodChannel.Result? = null
    private var paymentData: PaymentData? = null
    fun getResult(): MethodChannel.Result? {
        return flutterResult
    }

    fun setChannelResult(result: MethodChannel.Result){
        flutterResult = result
    }

    fun getPaymentData(): PaymentData?{
        return  paymentData
    }

    fun setPaymentData(data: PaymentData)
    {
        paymentData = data;
    }
}