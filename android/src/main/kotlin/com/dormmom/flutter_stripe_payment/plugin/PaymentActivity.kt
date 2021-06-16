package com.dormmom.flutter_stripe_payment

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button

import com.dormmom.flutter_stripe_payment.models.TempHolder
import com.stripe.android.*
import com.stripe.android.model.*
import com.stripe.android.view.CardMultilineWidget

import io.flutter.plugin.common.MethodChannel

class PaymentActivity : Activity()
{
    private lateinit var flutterResult: MethodChannel.Result;
    private lateinit var stripe: Stripe
    private lateinit var createPaymentMethod: Button
    private lateinit var cardInputWidget: CardMultilineWidget

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ///CustomerSession.initCustomerSession(this, StripeEphemeralKeyProvider())
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

        val showPaymentForm = intent.getBooleanExtra("showPaymentForm", false)
        val confirmPaymentIntent = intent.getBooleanExtra("confirmPaymentIntent", false)
        val setupPaymentIntent = intent.getBooleanExtra("setupPaymentIntent", false)

        if(showPaymentForm)
        {
            setContentView(R.layout.card_input_widget)

            cardInputWidget = findViewById(R.id.card_input_widget)
            createPaymentMethod = findViewById(R.id.btn_create_payment_method)
            createPaymentMethod.setOnClickListener {

                val card = cardInputWidget.paymentMethodCreateParams
                if (card != null) {
                    findViewById<View>(R.id.mProgressBar)?.visibility = View.VISIBLE
                    findViewById<View>(R.id.btn_create_payment_method)?.visibility = View.GONE
                    createPaymentMethod(card)
                }
                else
                {
                    flutterResult = TempHolder.getResult() as MethodChannel.Result
                    //flutterResult.error("error with card info", "", false)

                }
            }
        }

        if(confirmPaymentIntent)
        {
            val data = TempHolder.getPaymentData()
            val params = ConfirmPaymentIntentParams.createWithPaymentMethodId(data!!.paymentMethodId, data.clientSecret, "stripe://create_payment_intent_return")
            stripe.confirmPayment(this, params);
        }

        if(setupPaymentIntent)
        {
            val data = TempHolder.getPaymentData()
            val params = ConfirmSetupIntentParams.create(data!!.paymentMethodId, data.clientSecret, "stripe://create_payment_intent_return")
            stripe.confirmSetupIntent(this, params);

        }

    }

    private fun createPaymentMethod(paymentMethodCreateParams: PaymentMethodCreateParams) {

        flutterResult = TempHolder.getResult() as MethodChannel.Result

        stripe.createPaymentMethod(
                paymentMethodCreateParams,
                null,
                null,
                object : ApiResultCallback<PaymentMethod> {

                    override fun onSuccess(result: PaymentMethod) {
                        findViewById<View>(R.id.mProgressBar)?.visibility = View.GONE
                        findViewById<View>(R.id.btn_create_payment_method)?.visibility = View.GONE

                        if (result.id != null) {
                            val paymentResponse = mapOf("status" to "succeeded", "paymentMethodId" to (result.id ?: "") )
                            flutterResult.success(paymentResponse)
                        }
                        finish()
                    }
                    override fun onError(e: Exception) {
                        findViewById<View>(R.id.mProgressBar)?.visibility = View.GONE
                        findViewById<View>(R.id.btn_create_payment_method)?.visibility = View.VISIBLE
                        val paymentResponse = mapOf("status" to "failed", "errorMessage" to e.message)
                        flutterResult.success(paymentResponse)
                        finish()
                    }

                });

    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent) {
        super.onActivityResult(requestCode, resultCode, data)
        flutterResult = TempHolder.getResult() as MethodChannel.Result

        stripe.onPaymentResult(requestCode, data,
                object : ApiResultCallback<PaymentIntentResult> {
                    override fun onSuccess(result: PaymentIntentResult) {
                        // If authentication succeeded, the PaymentIntent will have
                        // user actions resolved; otherwise, handle the PaymentIntent
                        // status as appropriate (e.g. the customer may need to choose
                        // a new payment method)

                        val paymentIntent = result.intent
                        val status = paymentIntent.status
                        if (status == StripeIntent.Status.Succeeded || status == StripeIntent.Status.RequiresCapture) {
                            // show success UI
                            val paymentResponse = mapOf("status" to "succeeded", "paymentIntentId" to (paymentIntent.id ?: "") )
                            flutterResult.success(paymentResponse)
                        }
                        else if (StripeIntent.Status.RequiresPaymentMethod == status) {
                            // attempt authentication again or
                            // ask for a new Payment Method
                            // also id 3d secure fails/declined
                            paymentIntent.lastPaymentError?.let {
                                val paymentResponse = mapOf("status" to "failed", "errorMessage" to it.message)
                                flutterResult.success(paymentResponse)
                            }
                            // FIXME: it should call success anyway or flutter part will wait forever
                        }
                        else if(status == StripeIntent.Status.Canceled)
                        {
                            val paymentResponse = mapOf("status" to "canceled" )
                            flutterResult.success(paymentResponse)
                        }
                        finish()
                    }

                    override fun onError(e: Exception) {
                        // handle error
                        val paymentResponse = mapOf("status" to "failed", "errorMessage" to e.localizedMessage )
                        flutterResult.success(paymentResponse)
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
                            val paymentResponse = mapOf("status" to "succeeded", "paymentIntentId" to (setupIntent.id ?: "") )
                            flutterResult.success(paymentResponse)
                        } else if (setupIntent.requiresConfirmation()) {
                            // handle confirmation
                        }
                        finish()
                    }

                    override fun onError(e: Exception) {
                        // handle error
                        val paymentResponse = mapOf("status" to "failed", "errorMessage" to e.localizedMessage )
                        flutterResult.success(paymentResponse)
                        finish()
                    }
                })
    }

}
