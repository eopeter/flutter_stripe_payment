import Flutter
import UIKit
import Stripe

protocol IDelegate {
    func setStripeSettings(arguments: NSDictionary?, result: @escaping FlutterResult)
    func handleAddPaymentOptionButtonTapped(result: @escaping FlutterResult)
}

public class SwiftFlutterStripePaymentPlugin: NSObject, FlutterPlugin {
    
    let delegate: IDelegate
    
    init(registrar: FlutterPluginRegistrar) {
        delegate = StripePaymentDelegate(registrar: registrar)

    }
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_stripe_payment", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterStripePaymentPlugin(registrar: registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    
    let arguments = call.arguments as? NSDictionary
    
    if(call.method == "setStripeSettings")
    {
        delegate.setStripeSettings(arguments: arguments, result: result)
    }
    else if(call.method == "addPaymentSource")
    {
        delegate.handleAddPaymentOptionButtonTapped(result: result)
    }

  }
    
}

public class StripePaymentDelegate : NSObject, IDelegate, STPAddCardViewControllerDelegate
{
    var flutterResult: FlutterResult?
    var flutterRegistrar: FlutterPluginRegistrar
    
    init(registrar: FlutterPluginRegistrar) {
        flutterRegistrar = registrar
    }
 
    func setStripeSettings(arguments: NSDictionary?, result: @escaping FlutterResult)
    {
        guard let stripePublishableKey = arguments?["stripePublishableKey"] as? String else {return}
        let applePayMerchantIdentifier = arguments?["applePayMerchantIdentifier"] as? String
        STPPaymentConfiguration.shared().publishableKey = stripePublishableKey
        if(applePayMerchantIdentifier != nil)
        {
            STPPaymentConfiguration.shared().appleMerchantIdentifier = applePayMerchantIdentifier
        }
    }
    
    func handleAddPaymentOptionButtonTapped(result: @escaping FlutterResult) {
        flutterResult = result
        // Setup add card view controller
        let addCardViewController = STPAddCardViewController()
        addCardViewController.delegate = self
        
        // Present add card view controller
        let navigationController = UINavigationController(rootViewController: addCardViewController)
        let flutterViewController = UIApplication.shared.delegate?.window?!.rootViewController as! FlutterViewController
        flutterViewController.present(navigationController, animated: true)
    }
    
    // MARK: STPAddCardViewControllerDelegate
    
    public func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {
        // Dismiss add card view controller
        
        let flutterViewController = UIApplication.shared.delegate?.window?!.rootViewController as! FlutterViewController
        flutterViewController.dismiss(animated: true)
    }
    
    public func addCardViewController(_ addCardViewController: STPAddCardViewController, didCreatePaymentMethod paymentMethod: STPPaymentMethod, completion: @escaping STPErrorBlock)
    {
        flutterResult!(paymentMethod.stripeId)
        
        let flutterViewController = UIApplication.shared.delegate?.window?!.rootViewController as! FlutterViewController
        
        flutterViewController.dismiss(animated: true)
        
    }
}
