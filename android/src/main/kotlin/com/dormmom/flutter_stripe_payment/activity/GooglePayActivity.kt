package com.dormmom.flutter_stripe_payment.activity

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.dormmom.flutter_stripe_payment.R
import com.dormmom.flutter_stripe_payment.databinding.GooglePayActivityBinding
import com.dormmom.flutter_stripe_payment.models.TempHolder
import com.stripe.android.googlepaylauncher.GooglePayEnvironment
import com.stripe.android.googlepaylauncher.GooglePayPaymentMethodLauncher
import io.flutter.plugin.common.MethodChannel

class GooglePayActivity: AppCompatActivity() {

    private lateinit var flutterResult: MethodChannel.Result;
    private lateinit var googlePayLauncher: GooglePayPaymentMethodLauncher;

    private val viewBinding: GooglePayActivityBinding by lazy {
        GooglePayActivityBinding.inflate(layoutInflater)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(viewBinding.root)

        //viewBinding.progressBar.isVisible = true

        val data = TempHolder.getPaymentData()
        var env = GooglePayEnvironment.Test;
        if (data!!.isProductionEnvironment)
            env = GooglePayEnvironment.Production;
        googlePayLauncher = GooglePayPaymentMethodLauncher(
            activity = this,
            config = GooglePayPaymentMethodLauncher.Config(
                environment = env,
                merchantCountryCode = data.countryCode!!,
                merchantName = data.merchantName!!,
                billingAddressConfig = GooglePayPaymentMethodLauncher.BillingAddressConfig(
                    isRequired = true,
                    format = GooglePayPaymentMethodLauncher.BillingAddressConfig.Format.Full,
                    isPhoneNumberRequired = true
                )
            ),
            readyCallback = ::onGooglePayReady,
            resultCallback = ::onGooglePayResult
        )
    }

    private fun onGooglePayReady(isReady: Boolean) {
        flutterResult = TempHolder.getResult() as MethodChannel.Result
        flutterResult.success(isReady)
        val checkIsAvailable = intent.getBooleanExtra("checkIsAvailable", false)
        if (checkIsAvailable) {
            //finish();
        }
        else{
            if (isReady) {
                presentGooglePay()
            }
        }
    }

    private fun presentGooglePay() {
        val data = TempHolder.getPaymentData()
        googlePayLauncher.present(
            currencyCode = data!!.currencyCode!!,
            amount = data.amount!!.toInt()
        )
    }

    private fun onGooglePayResult(
        result: GooglePayPaymentMethodLauncher.Result
    ) {
        when (result) {
            is GooglePayPaymentMethodLauncher.Result.Completed -> {
                val paymentMethodId = result.paymentMethod.id
                val paymentResponse = mapOf("status" to "succeeded", "paymentMethodId" to (paymentMethodId ?: "") )
                flutterResult.success(paymentResponse)
            }
            GooglePayPaymentMethodLauncher.Result.Canceled -> {
                val paymentResponse = mapOf("status" to "canceled" )
                flutterResult.success(paymentResponse)
                finish()
            }
            is GooglePayPaymentMethodLauncher.Result.Failed -> {
                // Operation failed; inspect `result.error` for the exception
                val paymentResponse = mapOf("status" to "failed", "errorMessage" to result.error.localizedMessage )
                flutterResult.success(paymentResponse)
                finish()
            }
        }
    }
}