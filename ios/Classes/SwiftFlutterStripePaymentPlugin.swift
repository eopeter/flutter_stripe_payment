import Flutter
import UIKit
import Stripe

protocol IDelegate {
    func setStripeSettings(arguments: NSDictionary?, result: @escaping FlutterResult)
    func handleAddPaymentOptionButtonTapped(result: @escaping FlutterResult)
    func confirmPaymentIntent(clientSecret: String, amount: Double, isApplePay: Bool, result: @escaping FlutterResult)
    func setupPaymentIntent(clientSecret: String, paymentMethodId: String, isApplePay: Bool, result: @escaping FlutterResult)
}

public class SwiftFlutterStripePaymentPlugin: NSObject, FlutterPlugin {
    
    let delegate: IDelegate
    
    init(registrar: FlutterPluginRegistrar, viewController: UIViewController) {
        delegate = StripePaymentDelegate(registrar: registrar, viewController: viewController)

    }
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_stripe_payment", binaryMessenger: registrar.messenger())
    let flutterViewController = UIApplication.shared.delegate?.window?!.rootViewController as! FlutterViewController
    let instance = SwiftFlutterStripePaymentPlugin(registrar: registrar, viewController: flutterViewController)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    
    let arguments = call.arguments as? NSDictionary
    
    if(call.method == "setStripeSettings")
    {
        delegate.setStripeSettings(arguments: arguments, result: result)
    }
    else if(call.method == "addPaymentMethod")
    {
        delegate.handleAddPaymentOptionButtonTapped(result: result)
    }
    else if(call.method == "confirmPaymentIntent")//immediate payments
    {
        guard let clientSecret = arguments?["clientSecret"] as? String else {return}
        guard let amount = arguments?["amount"] as? Double else {return}
        let isApplePay = arguments?["isApplePay"] as? Bool
        delegate.confirmPaymentIntent(clientSecret: clientSecret, amount: amount, isApplePay: isApplePay ?? false, result: result)
    }
    else if(call.method == "setupPaymentIntent")//future payments
    {
        guard let clientSecret = arguments?["clientSecret"] as? String else {return}
        guard let paymentMethodId = arguments?["paymentMethodId"] as? String else {return}
        let isApplePay = arguments?["isApplePay"] as? Bool
       
        delegate.setupPaymentIntent(clientSecret: clientSecret, paymentMethodId: paymentMethodId, isApplePay: isApplePay ?? false, result: result)
    }

  }
    
}

public class StripePaymentDelegate : NSObject, IDelegate, STPAddCardViewControllerDelegate, STPAuthenticationContext
{
    var flutterResult: FlutterResult?
    var flutterRegistrar: FlutterPluginRegistrar
    var flutterViewController: UIViewController
    var isPresentingApplePay: Bool = false
    
    init(registrar: FlutterPluginRegistrar, viewController: UIViewController) {
        self.flutterRegistrar = registrar
        self.flutterViewController = viewController
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
    
    func confirmPaymentIntent(clientSecret: String, amount: Double, isApplePay: Bool, result: @escaping FlutterResult)
    {
        flutterResult = result
        isPresentingApplePay = isApplePay
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
        let paymentManager = STPPaymentHandler.shared()
        paymentManager.confirmPayment(paymentIntentParams, with: self) { (status, paymentIntent, error) in
            
            var intentResponse: [String : Any] = ["status":"\(status)", "paymentIntentId" : paymentIntent?.stripeId ?? ""]
            switch (status) {
            case .failed:
                intentResponse["errorMessage"] = error?.localizedDescription
                intentResponse["status"] = "failed"
            case .canceled:
                intentResponse["status"] = "cancelled"
            case .succeeded:
                intentResponse["status"] = "succeeded"
            }
            
            result(intentResponse)
        }
        
    }
    
    func setupPaymentIntent(clientSecret: String, paymentMethodId: String, isApplePay: Bool, result: @escaping FlutterResult)
    {
        flutterResult = result
        isPresentingApplePay = isApplePay
        let setupIntentConfirmParams = STPSetupIntentConfirmParams(clientSecret: clientSecret)
        setupIntentConfirmParams.paymentMethodID = paymentMethodId
        let paymentManager = STPPaymentHandler.shared()
        paymentManager.confirmSetupIntent(setupIntentConfirmParams, with: self) { (status, paymentIntent, error) in
          
            var intentResponse: [String : Any] = ["status":"\(status)", "paymentIntentId" : paymentIntent?.stripeID ?? ""]
            switch (status) {
            case .failed:
                intentResponse["errorMessage"] = error?.localizedDescription
                intentResponse["status"] = "failed"
            case .canceled:
                intentResponse["status"] = "cancelled"
            case .succeeded:
                intentResponse["status"] = "succeeded"
            }
            
            result(intentResponse)
        }
        
    }
    
    func handleAddPaymentOptionButtonTapped(result: @escaping FlutterResult) {
        flutterResult = result
        // Setup add card view controller
        let addCardViewController = STPAddCardViewController()
        addCardViewController.delegate = self
    
        // Present add card view controller
        let navigationController = UINavigationController(rootViewController: addCardViewController)
        flutterViewController.present(navigationController, animated: true)
    }
    
    // MARK: STPAuthenticationContext
    public func authenticationPresentingViewController() -> UIViewController {
        return self.flutterViewController
    }
    
    public func prepare(forPresentation completion: @escaping STPVoidBlock) {
        if isPresentingApplePay
        {
            flutterViewController.dismiss(animated: true) {
                completion()
            }
        }
        else{
            completion()
        }
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
