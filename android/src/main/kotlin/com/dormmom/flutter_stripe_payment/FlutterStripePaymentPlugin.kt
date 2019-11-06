package com.dormmom.flutter_stripe_payment

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button

import com.stripe.android.*
import com.stripe.android.model.*
import com.stripe.android.view.CardInputWidget
import com.stripe.android.view.CardMultilineWidget

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar


class FlutterStripePaymentPlugin: MethodCallHandler {

    private lateinit var stripe: Stripe
    var _activity: Activity
    var _context: Context

    constructor(context: Context, activity: Activity)
    {
        this._context = context
        this._activity = activity

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

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "flutter_stripe_payment")
            channel.setMethodCallHandler(FlutterStripePaymentPlugin(registrar.context(), registrar.activity()))
            /*
            messageChannel = BasicMessageChannel(flutterView, CHANNEL, StringCodec.INSTANCE)
            messageChannel.setMessageHandler(object : MessageHandler<String>() {
              fun onMessage(s: String, reply: Reply<String>) {
                onFlutterIncrement()
                reply.reply(EMPTY_MESSAGE)
              }
            })
            */

        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {

        var arguments = call.arguments as? Map<String, Object>

        if (call.method == "getPlatformVersion")
        {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        }
        else if (call.method == "setStripeSettings")
        {
            var stripePublishableKey = arguments?.get("stripePublishableKey") as? String
            this.setStripeSettings(result, stripePublishableKey as String)
        }
        else if (call.method == "addPaymentMethod")
        {
            this.addPaymentMethod(result);
        }
        else if (call.method == "confirmPaymentIntent")
        {
            var clientSecret = arguments?.get("clientSecret") as? String
            var paymentMethodId = arguments?.get("paymentMethodId") as? String
            var amount = arguments?.get("amount") as? Double
            this.confirmPaymentIntent(paymentMethodId!!, clientSecret!!, amount!!, result)

        }
        else if (call.method == "setupPaymentIntent")
        {
            var clientSecret = arguments?.get("clientSecret") as? String
            var paymentMethodId = arguments?.get("paymentMethodId") as? String

        }
        else {
            result.notImplemented()
        }
    }

    fun setStripeSettings(result: Result, stripePublishableKey: String)
    {
        PaymentConfiguration.init(_context, stripePublishableKey)
        stripe = Stripe(_context, PaymentConfiguration.getInstance(_context).publishableKey)
        result.success(true)
    }


    fun addPaymentMethod(result: Result)
    {
        TempHolder.setData(result)
        val intent = Intent(_context, PaymentActivity::class.java)
        intent.putExtra("showPaymentForm", true)
        _activity.startActivity(intent)

    }

    fun confirmPaymentIntent(paymentMethodId: String, clientSecret: String, amount: Double?, result: Result)
    {
        TempHolder.setData(result)
        TempHolder.setPaymentData(PaymentData(clientSecret, amount, "", paymentMethodId))
        val intent = Intent(_context, PaymentActivity::class.java)
        intent.putExtra("confirmPaymentIntent", true)
        _activity.startActivity(intent)
    }

    fun setupPaymentIntent(paymentMethodId: String, clientSecret: String, result: Result)
    {
        TempHolder.setData(result)
        TempHolder.setPaymentData(PaymentData(clientSecret, null, "", paymentMethodId))
        val intent = Intent(_context, PaymentActivity::class.java)
        intent.putExtra("setupPaymentIntent", true)
        _activity.startActivity(intent)
    }

}

class PaymentActivity : Activity()
{
    private lateinit var flutterResult: Result;
    private lateinit var stripe: Stripe
    private lateinit var createPaymentMethod: Button
    private lateinit var cardInputWidget: CardMultilineWidget

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Optional: customize the payment authentication experience.
        // PaymentAuthConfig.init() must be called before Stripe object
        // is instantiated.
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

        stripe = Stripe(this,
                PaymentConfiguration.getInstance(this).publishableKey)

        var showPaymentForm = intent.getBooleanExtra("showPaymentForm", false)
        var confirmPaymentIntent = intent.getBooleanExtra("confirmPaymentIntent", false)
        var setupPaymentIntent = intent.getBooleanExtra("setupPaymentIntent", false)

        if(showPaymentForm)
        {
            setContentView(R.layout.card_input_widget)

            cardInputWidget = findViewById(R.id.card_input_widget)
            createPaymentMethod = findViewById(R.id.btn_create_payment_method)
            createPaymentMethod.setOnClickListener {

                val card = cardInputWidget.card
                if (card != null) {
                    findViewById<View>(R.id.mProgressBar)?.visibility = View.VISIBLE
                    findViewById<View>(R.id.btn_create_payment_method)?.visibility = View.GONE
                    createPaymentMethod(card)
                }
                else
                {
                    flutterResult = TempHolder.getResult() as Result
                    //flutterResult.error("error with card info", "", false)

                }
            }
        }

        if(confirmPaymentIntent)
        {
            var data = TempHolder.getPaymentData()
            var params = ConfirmPaymentIntentParams.createWithPaymentMethodId(data!!.paymentMethodId, data!!.clientSecret, "stripe://create_payment_intent_return")
            stripe.confirmPayment(this, params);
        }

        if(setupPaymentIntent)
        {
            var data = TempHolder.getPaymentData()
            var params = ConfirmSetupIntentParams.create(data!!.paymentMethodId, data!!.clientSecret, "stripe://create_payment_intent_return")
            stripe.confirmSetupIntent(this, params);

        }

    }

    private fun createPaymentMethod(card: Card) {

        flutterResult = TempHolder.getResult() as Result

        var paymentMethodParamsCard = card.toPaymentMethodParamsCard()
        val paymentMethodCreateParams =
                PaymentMethodCreateParams.create(paymentMethodParamsCard, PaymentMethod.BillingDetails.Builder().build())

        stripe.createPaymentMethod(
                paymentMethodCreateParams,
                object : ApiResultCallback<PaymentMethod> {

                    override fun onSuccess(result: PaymentMethod) {
                        findViewById<View>(R.id.mProgressBar)?.visibility = View.GONE
                        findViewById<View>(R.id.btn_create_payment_method)?.visibility = View.GONE

                        if (result.id != null) {
                            var paymentResponse = mapOf("status" to "succeeded", "paymentMethodId" to (result.id ?: "") )
                            flutterResult?.success(paymentResponse)
                            finish()
                        }
                    }

                    override fun onError(error: Exception) {
                        findViewById<View>(R.id.mProgressBar)?.visibility = View.GONE
                        findViewById<View>(R.id.btn_create_payment_method)?.visibility = View.VISIBLE
                        var paymentResponse = mapOf("status" to "failed", "errorMessage" to error.message)
                        flutterResult?.success(paymentResponse)
                        finish()
                    }

                });

    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent) {
        super.onActivityResult(requestCode, resultCode, data)
        flutterResult = TempHolder.getResult() as Result

        stripe.onPaymentResult(requestCode, data,
                object : ApiResultCallback<PaymentIntentResult> {
                    override fun onSuccess(result: PaymentIntentResult) {
                        // If authentication succeeded, the PaymentIntent will have
                        // user actions resolved; otherwise, handle the PaymentIntent
                        // status as appropriate (e.g. the customer may need to choose
                        // a new payment method)

                        val paymentIntent = result.intent
                        val status = paymentIntent.status
                        if (status == StripeIntent.Status.Succeeded) {
                            // show success UI
                            var paymentResponse = mapOf("status" to "succeeded", "paymentIntentId" to (paymentIntent.id ?: "") )
                            flutterResult?.success(paymentResponse)
                        }
                        else if (StripeIntent.Status.RequiresPaymentMethod == status) {
                            // attempt authentication again or
                            // ask for a new Payment Method
                        }
                        else if(status == StripeIntent.Status.Canceled)
                        {
                            var paymentResponse = mapOf("status" to "canceled" )
                            flutterResult?.success(paymentResponse)
                        }
                        finish()
                    }

                    override fun onError(e: Exception) {
                        // handle error
                        var paymentResponse = mapOf("status" to "failed", "errorMessage" to e.localizedMessage )
                        flutterResult?.success(paymentResponse)
                        finish()
                    }
                })

        stripe.onSetupResult(requestCode, data,
                object : ApiResultCallback<SetupIntentResult> {
                    override fun onSuccess(result: SetupIntentResult) {
                        // If confirmation and authentication succeeded,
                        // the SetupIntent will have user actions resolved;
                        // otherwise, handle the failure as appropriate
                        // (e.g. the customer may need to choose a new payment
                        // method)
                        val setupIntent = result.intent
                        val status = setupIntent.status
                        if (status == StripeIntent.Status.Succeeded) {
                            // show success UI
                            var paymentResponse = mapOf("status" to "succeeded", "paymentIntentId" to (setupIntent.id ?: "") )
                            flutterResult?.success(paymentResponse)
                        } else if (setupIntent.requiresConfirmation()) {
                            // handle confirmation
                        }
                        finish()
                    }

                    override fun onError(e: Exception) {
                        // handle error
                        var paymentResponse = mapOf("status" to "failed", "errorMessage" to e.localizedMessage )
                        flutterResult?.success(paymentResponse)
                        finish()
                    }
                })
    }

}


object TempHolder {
    private var flutterResult: Result? = null
    private var paymentData: PaymentData? = null
    fun getResult(): Result? {
        return flutterResult
    }

    fun setData(result: Result){
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
