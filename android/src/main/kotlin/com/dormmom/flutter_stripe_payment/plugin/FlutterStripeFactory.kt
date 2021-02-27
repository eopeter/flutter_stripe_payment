package com.dormmom.flutter_stripe_payment

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.view.View
import com.dormmom.flutter_stripe_payment.models.PaymentData
import com.dormmom.flutter_stripe_payment.models.TempHolder
import com.stripe.android.PaymentAuthConfig
import com.stripe.android.PaymentConfiguration
import com.stripe.android.Stripe
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.flutter.plugin.platform.PlatformView


class FlutterStripeFactory internal constructor(private val context: Context, messenger: BinaryMessenger):
        MethodCallHandler,
        EventChannel.StreamHandler,
        PlatformView{

    var activity: Activity? = null
    //private val methodChannel: MethodChannel = MethodChannel(messenger, "flutter_stripe_payment")
    var eventSink: EventChannel.EventSink? = null

    private lateinit var stripe: Stripe

       override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {

        var arguments = call.arguments as? Map<*, *>
        when(call.method)
        {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "setStripeSettings" -> {
                var stripePublishableKey = arguments?.get("stripePublishableKey") as? String
                this.setStripeSettings(result, stripePublishableKey as String)
            }
            "addPaymentMethod" -> {
                this.addPaymentMethod(result);
            }
            "confirmPaymentIntent" -> {
                var clientSecret = arguments?.get("clientSecret") as? String
                var paymentMethodId = arguments?.get("paymentMethodId") as? String
                var stripeAccountId = arguments?.get("stripeAccountId") as? String
                var amount = arguments?.get("amount") as? Double
                this.confirmPaymentIntent(paymentMethodId!!, clientSecret!!, amount!!, result)
            }
            "setupPaymentIntent" -> {
                var clientSecret = arguments?.get("clientSecret") as? String
                var paymentMethodId = arguments?.get("paymentMethodId") as? String
                if (paymentMethodId != null && clientSecret != null) {
                    this.setupPaymentIntent(paymentMethodId, clientSecret, result)
                }
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

    fun setStripeSettings(result: MethodChannel.Result, stripePublishableKey: String)
    {
        PaymentConfiguration.init(context, stripePublishableKey)
        stripe = Stripe(context, PaymentConfiguration.getInstance(context).publishableKey)
        result.success(true)
    }


    fun addPaymentMethod(result: MethodChannel.Result)
    {
        TempHolder.setData(result)
        val intent = Intent(context, PaymentActivity::class.java)
        intent.putExtra("showPaymentForm", true)
        activity?.startActivity(intent)

    }

    fun confirmPaymentIntent(paymentMethodId: String, clientSecret: String, amount: Double?, result: MethodChannel.Result)
    {
        TempHolder.setData(result)
        TempHolder.setPaymentData(PaymentData(clientSecret, amount, "", paymentMethodId))
        val intent = Intent(context, PaymentActivity::class.java)
        intent.putExtra("confirmPaymentIntent", true)
        activity?.startActivity(intent)
    }

    fun setupPaymentIntent(paymentMethodId: String, clientSecret: String, result: MethodChannel.Result)
    {
        TempHolder.setData(result)
        TempHolder.setPaymentData(PaymentData(clientSecret, null, "", paymentMethodId))
        val intent = Intent(context, PaymentActivity::class.java)
        intent.putExtra("setupPaymentIntent", true)
        activity?.startActivity(intent)
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