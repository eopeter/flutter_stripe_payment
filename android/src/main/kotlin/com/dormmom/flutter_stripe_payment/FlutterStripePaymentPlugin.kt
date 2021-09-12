package com.dormmom.flutter_stripe_payment

import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull
import androidx.appcompat.app.AppCompatActivity

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.*
import io.flutter.plugin.platform.PlatformViewsController

class FlutterStripePaymentPlugin: FlutterPlugin, ActivityAware {

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        setUpPluginMethods(flutterPluginBinding.applicationContext, flutterPluginBinding.binaryMessenger);
    }

    companion object {

        lateinit var pluginInstance: FlutterStripeFactory
        private lateinit var channel : MethodChannel
        private lateinit var eventChannel: EventChannel
        private var currentActivity: Activity? = null

        @JvmStatic
        var view_name = "com.dormmom.flutter_stripe_payment/stripeView"

        @JvmStatic
        var viewController: PlatformViewsController? = null

        @JvmStatic
        fun registerWith(engine: FlutterEngine) {
            viewController = engine.platformViewsController
            currentActivity?.let { activity ->
                viewController?.registry?.registerViewFactory(
                        view_name, StripeViewFactory(engine.dartExecutor.binaryMessenger, activity))
            }
        }


        @JvmStatic
        fun registerWith(registrar: PluginRegistry.Registrar) {
            currentActivity = registrar.activity()
            setUpPluginMethods(registrar.activity(), registrar.messenger(), currentActivity)

        }

        @JvmStatic
        private fun setUpPluginMethods(context: Context, messenger: BinaryMessenger, activity: Activity? = null ) {

            channel = MethodChannel(messenger, "flutter_stripe_payment")
            eventChannel = EventChannel(messenger, "flutter_stripe_payment_event")

            pluginInstance = FlutterStripeFactory(messenger = messenger , context = context)

            if(activity != null)
                pluginInstance.activity = activity;

            channel.setMethodCallHandler(pluginInstance)
            eventChannel.setStreamHandler(pluginInstance)
        }

    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        currentActivity = null
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onAttachedToActivity(@NonNull activityPluginBinding: ActivityPluginBinding) {
        currentActivity = activityPluginBinding.activity
        pluginInstance.activity = activityPluginBinding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {

    }

    override fun onReattachedToActivityForConfigChanges(activityPluginBinding: ActivityPluginBinding) {
        currentActivity = activityPluginBinding.activity
        pluginInstance.activity = activityPluginBinding.activity
    }

    override fun onDetachedFromActivity() {
        currentActivity = null
        pluginInstance.activity = null
    }



}


