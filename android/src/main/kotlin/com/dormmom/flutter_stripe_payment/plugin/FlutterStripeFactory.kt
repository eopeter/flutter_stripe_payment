package com.dormmom.flutter_stripe_payment

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import com.dormmom.flutter_stripe_payment.activity.GooglePayActivity
import com.dormmom.flutter_stripe_payment.activity.PaymentActivity
import com.dormmom.flutter_stripe_payment.models.PaymentData
import com.dormmom.flutter_stripe_payment.models.TempHolder

import com.stripe.android.PaymentAuthConfig
import com.stripe.android.PaymentConfiguration
import com.stripe.android.Stripe
import com.stripe.android.paymentsheet.PaymentSheet
import com.stripe.android.paymentsheet.PaymentSheetResult
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.platform.PlatformView


class FlutterStripeFactory internal constructor(private val context: Context, messenger: BinaryMessenger):
        MethodCallHandler,
        EventChannel.StreamHandler,
        PlatformView{

    var activity: Activity? = null
    //private val methodChannel: MethodChannel = MethodChannel(messenger, "flutter_stripe_payment")
    var eventSink: EventChannel.EventSink? = null

    private lateinit var stripe: Stripe
    private lateinit var paymentSheet: PaymentSheet

    private var customerId: String? = null
    private var ephemeralKeySecret: String? = null
    private var paymentIntentClientSecret: String? = null
    private var merchantName: String? = null
    var stripeSettingsComplete = false;

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {

        val arguments = call.arguments as? Map<*, *>
        when(call.method)
        {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "setStripeSettings" -> {
                val stripePublishableKey = arguments?.get("stripePublishableKey") as? String
                this.setStripeSettings(result, stripePublishableKey as String)
            }
            "addPaymentMethod" -> {
                this.addPaymentMethod(result);
            }
            "confirmPaymentIntent" -> {
                val clientSecret = arguments?.get("clientSecret") as? String
                val paymentMethodId = arguments?.get("paymentMethodId") as? String
                var stripeAccountId = arguments?.get("stripeAccountId") as? String
                val amount = arguments?.get("amount") as? Double
                this.confirmPaymentIntent(paymentMethodId!!, clientSecret!!, amount!!, result)
            }
            "setupPaymentIntent" -> {
                val clientSecret = arguments?.get("clientSecret") as? String
                val paymentMethodId = arguments?.get("paymentMethodId") as? String
                if (paymentMethodId != null && clientSecret != null) {
                    this.setupPaymentIntent(paymentMethodId, clientSecret, result)
                }
            }
            "getPaymentMethodFromNativePay" -> {
                this.showGooglePaySheet(arguments, result)
            }
            "preparePaymentSheet" -> {
                preparePaymentSheet(arguments, result)
            }
            "showPaymentSheet" -> {
                presentPaymentSheet(result)
            }
            else -> result.notImplemented()
        }
    }

    init {
        //methodChannel.setMethodCallHandler(this)

        val uiCustomization = PaymentAuthConfig.Stripe3ds2UiCustomization.Builder()
                .build()
        PaymentAuthConfig.init(PaymentAuthConfig.Builder()
                .set3ds2Config(PaymentAuthConfig.Stripe3ds2Config.Builder()
                        // set a 5 minute timeout for challenge flow
                        .setTimeout(5)
                        // customize the UI of the challenge flow
                        .setUiCustomization(uiCustomization)
                        .build())
                .build())
        
    }

    private fun setStripeSettings(result: MethodChannel.Result, stripePublishableKey: String)
    {
        PaymentConfiguration.init(context, stripePublishableKey)
        stripe = Stripe(context, PaymentConfiguration.getInstance(context).publishableKey)
        stripeSettingsComplete = true;
        result.success(true)
    }


    private fun addPaymentMethod(result: MethodChannel.Result)
    {
        TempHolder.setChannelResult(result)
        val intent = Intent(context, PaymentActivity::class.java)
        intent.putExtra("showPaymentForm", true)
        activity?.startActivity(intent)

    }

    private fun confirmPaymentIntent(paymentMethodId: String, clientSecret: String, amount: Double?, result: MethodChannel.Result)
    {
        TempHolder.setChannelResult(result)
        val paymentData = PaymentData()
        paymentData.paymentMethodId = paymentMethodId;
        paymentData.clientSecret = clientSecret;
        TempHolder.setPaymentData(paymentData)
        val intent = Intent(context, PaymentActivity::class.java)
        intent.putExtra("confirmPaymentIntent", true)
        activity?.startActivity(intent)
    }

    private fun setupPaymentIntent(paymentMethodId: String, clientSecret: String, result: MethodChannel.Result)
    {
        TempHolder.setChannelResult(result)
        val paymentData = PaymentData()
        paymentData.paymentMethodId = paymentMethodId;
        paymentData.clientSecret = clientSecret;
        TempHolder.setPaymentData(paymentData)
        val intent = Intent(context, PaymentActivity::class.java)
        intent.putExtra("setupPaymentIntent", true)
        activity?.startActivity(intent)
    }

    private fun showGooglePaySheet(arguments: Map<*, *>?, result: MethodChannel.Result) {
        TempHolder.setChannelResult(result)
        val paymentData = PaymentData()
        val items = arguments?.get("paymentItems") as? ArrayList<Map<String, *>>
        var amount = 0.0
        for (item in items!!){
            amount += (item["amount"] as Double)
        }
        paymentData.merchantName = arguments["merchantName"] as? String;
        paymentData.countryCode = arguments["countryCode"] as? String;
        paymentData.currencyCode = arguments["currencyCode"] as? String;
        paymentData.amount = amount;
        TempHolder.setPaymentData(paymentData)
        val intent = Intent(context, GooglePayActivity::class.java)
        activity?.startActivity(intent)
    }

    private fun preparePaymentSheet(arguments: Map<*, *>?, flutterResult: MethodChannel.Result) {
        if (!stripeSettingsComplete) {
            flutterResult.error(
                "400",
                "must call setStripeSettings",
                "you must call the setStripeSettings " +
                        "to set your publishable key before attempting any functions"
            )
            return;
        }
        customerId = arguments?.get("customerId") as? String
        ephemeralKeySecret = arguments?.get("customerEphemeralKeySecret") as? String
        paymentIntentClientSecret = arguments?.get("paymentIntentClientSecret") as? String
        merchantName = arguments?.get("merchantName") as? String

        paymentSheet = PaymentSheet(this.activity!! as AppCompatActivity) { result ->
            onPaymentSheetResult(result, flutterResult)
        }
    }

    private fun presentPaymentSheet(flutterResult: MethodChannel.Result) {
        if (paymentIntentClientSecret == null) {
            flutterResult.error(
                "400",
                "client secret is required",
                "you must request a client secret from stripe " +
                        "using your backend for the current customer"
            )
            return;
        }
        paymentSheet.presentWithPaymentIntent(
            paymentIntentClientSecret!!,
            PaymentSheet.Configuration(
                merchantDisplayName = merchantName!!,
                customer = PaymentSheet.CustomerConfiguration(
                    id = customerId!!,
                    ephemeralKeySecret = ephemeralKeySecret!!
                )
            )
        )
    }

    private fun onPaymentSheetResult(paymentSheetResult: PaymentSheetResult, flutterResult: MethodChannel.Result) {
        when(paymentSheetResult) {
            is PaymentSheetResult.Canceled -> {
                val paymentResponse = mapOf("status" to "canceled" )
                flutterResult.success(paymentResponse)
            }
            is PaymentSheetResult.Failed -> {
                val paymentResponse = mapOf("status" to "failed", "errorMessage" to paymentSheetResult.error)
                flutterResult.success(paymentResponse)
            }
            is PaymentSheetResult.Completed -> {
                val paymentResponse = mapOf("status" to "succeeded")
                flutterResult.success(paymentResponse)
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {

        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        
    }

    override fun getView(): View {
        TODO("Not yet implemented")
    }

    override fun dispose() {
        TODO("Not yet implemented")
    }

}