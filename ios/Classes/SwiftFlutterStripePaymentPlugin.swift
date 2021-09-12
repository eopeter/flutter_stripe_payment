import Flutter
import UIKit
import PassKit
import Stripe

typealias AuthorizationCompletion = (_ payment: String) -> Void
typealias AuthorizationViewControllerDidFinish = (_ error : NSDictionary) -> Void
typealias CompletionHandler = (PKPaymentAuthorizationResult) -> Void

protocol IFlutterStripePaymentDelegate {
    func setStripeSettings(arguments: NSDictionary?, result: @escaping FlutterResult)
    func handleAddPaymentOptionButtonTapped(result: @escaping FlutterResult)
    func confirmPaymentIntent(clientSecret: String, paymentMethodId: String, amount: Double, isApplePay: Bool, result: @escaping FlutterResult)
    func setupPaymentIntent(clientSecret: String, paymentMethodId: String, isApplePay: Bool, result: @escaping FlutterResult)
    func showApplePaySheet(arguments: NSDictionary, result: @escaping FlutterResult)
    func preparePaymentSheet(arguments: NSDictionary, result: @escaping FlutterResult)
    func showPaymentSheet(arguments: NSDictionary, result: @escaping FlutterResult)
    func closeApplePaySheetWithSuccess()
    func closeApplePaySheetWithError()
}

public class SwiftFlutterStripePaymentPlugin: NSObject, FlutterPlugin {
    
    let delegate: IFlutterStripePaymentDelegate
    
    init(registrar: FlutterPluginRegistrar, viewController: UIViewController, channel: FlutterMethodChannel) {
        delegate = StripePaymentDelegate(registrar: registrar, viewController: viewController, channel: channel)
        
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_stripe_payment", binaryMessenger: registrar.messenger())
        let flutterViewController = UIApplication.shared.delegate?.window?!.rootViewController as! FlutterViewController
        let instance = SwiftFlutterStripePaymentPlugin(registrar: registrar, viewController: flutterViewController, channel: channel)
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
            guard let paymentMethodId = arguments?["paymentMethodId"] as? String else {return}
            guard let amount = arguments?["amount"] as? Double else {return}
            let isApplePay = arguments?["isApplePay"] as? Bool
            delegate.confirmPaymentIntent(clientSecret: clientSecret, paymentMethodId: paymentMethodId, amount: amount, isApplePay: isApplePay ?? false, result: result)
        }
        else if(call.method == "setupPaymentIntent")//future payments
        {
            guard let clientSecret = arguments?["clientSecret"] as? String else {return}
            guard let paymentMethodId = arguments?["paymentMethodId"] as? String else {return}
            let isApplePay = arguments?["isApplePay"] as? Bool
            
            delegate.setupPaymentIntent(clientSecret: clientSecret, paymentMethodId: paymentMethodId, isApplePay: isApplePay ?? false, result: result)
        }
        else if(call.method == "getPaymentMethodFromNativePay") {
            delegate.showApplePaySheet(arguments: arguments!, result: result)
        }
        else if call.method == "closeApplePaySheetWithSuccess" {
            delegate.closeApplePaySheetWithSuccess()
        }
        else if call.method == "closeApplePaySheetWithError" {
            delegate.closeApplePaySheetWithError()
        }
        else if call.method == "preparePaymentSheet" {
            delegate.preparePaymentSheet(arguments: arguments!, result: result);
        }
        else if call.method == "showPaymentSheet" {
            delegate.showPaymentSheet(arguments: arguments!, result: result);
        }
        else {
            result("Flutter method not implemented on iOS")
        }
    }
    
}

public class StripePaymentDelegate : NSObject, IFlutterStripePaymentDelegate, STPAddCardViewControllerDelegate, STPAuthenticationContext, PKPaymentAuthorizationViewControllerDelegate
{
    var flutterResult: FlutterResult?
    var flutterRegistrar: FlutterPluginRegistrar
    var flutterViewController: UIViewController
    var isPresentingApplePay: Bool = false
    let channel: FlutterMethodChannel;
    
    var authorizationCompletion : AuthorizationCompletion!
    var authorizationViewControllerDidFinish : AuthorizationViewControllerDidFinish!
    var pkrequest = PKPaymentRequest()
    var completionHandler: CompletionHandler!
    var paymentSheet: PaymentSheet?
    
    init(registrar: FlutterPluginRegistrar, viewController: UIViewController, channel: FlutterMethodChannel) {
        self.flutterRegistrar = registrar
        self.flutterViewController = viewController
        self.channel = channel
    }
    
    func setStripeSettings(arguments: NSDictionary?, result: @escaping FlutterResult)
    {
        guard let stripePublishableKey = arguments?["stripePublishableKey"] as? String else {return}
        let applePayMerchantIdentifier = arguments?["applePayMerchantIdentifier"] as? String
        StripeAPI.defaultPublishableKey = stripePublishableKey
        //STPAPIClient.shared().publishableKey = stripePublishableKey
        //STPPaymentConfiguration.shared().publishableKey = stripePublishableKey
        if(applePayMerchantIdentifier != nil)
        {
            STPPaymentConfiguration.shared.appleMerchantIdentifier = applePayMerchantIdentifier
        }
    }
    
    func confirmPaymentIntent(clientSecret: String, paymentMethodId: String, amount: Double, isApplePay: Bool, result: @escaping FlutterResult)
    {
        flutterResult = result
        isPresentingApplePay = isApplePay
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
        paymentIntentParams.paymentMethodId = paymentMethodId
        let paymentManager = STPPaymentHandler.shared()
        paymentManager.confirmPayment(paymentIntentParams, with: self) { (status, paymentIntent, error) in
            
            var intentResponse: [String : Any] = ["status":"\(status)", "paymentIntentId" : paymentIntent?.stripeId ?? ""]
            switch (status) {
            case .failed:
                intentResponse["errorMessage"] = error?.localizedDescription
                intentResponse["status"] = "failed"
            case .canceled:
                intentResponse["status"] = "canceled"
            case .succeeded:
                intentResponse["status"] = "succeeded"
            @unknown default:
                intentResponse["errorMessage"] = error?.localizedDescription
                intentResponse["status"] = "failed"
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
                intentResponse["status"] = "canceled"
            case .succeeded:
                intentResponse["status"] = "succeeded"
            @unknown default:
                intentResponse["errorMessage"] = error?.localizedDescription
                intentResponse["status"] = "failed"
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
    
    func preparePaymentSheet(arguments: NSDictionary, result: @escaping FlutterResult) {
        
        guard let customerId = arguments["customerId"] as? String else {return}
        guard let customerEphemeralKeySecret = arguments["customerEphemeralKeySecret"] as? String else {return}
        guard let paymentIntentClientSecret = arguments["paymentIntentClientSecret"] as? String else {return}
        guard let merchantName = arguments["merchantName"] as? String else {return}
        
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = merchantName
        configuration.customer = .init(id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
        self.paymentSheet = PaymentSheet(paymentIntentClientSecret: paymentIntentClientSecret, configuration: configuration)
        result(true)
    }
    
    func showPaymentSheet(arguments: NSDictionary, result: @escaping FlutterResult) {
        // MARK: Start the checkout process
        guard let currentViewController = UIApplication.shared.keyWindow?.topMostViewController() else {
            return
        }
        paymentSheet?.present(from: currentViewController ) { paymentResult in
            // MARK: Handle the payment result
            var paymentResponse: [String : Any] = ["status":"\(paymentResult)"]
            switch paymentResult {
            case .completed:
                print("Your order is confirmed")
                paymentResponse["status"] = "succeeded"
            case .canceled:
                print("Canceled!")
                paymentResponse["status"] = "cancelled"
            case .failed(let error):
                print("Payment failed: \n\(error.localizedDescription)")
                paymentResponse["status"] = "failed"
                paymentResponse["errorMessage"] = error.localizedDescription
            }
        }
    }
    
    func showApplePaySheet(arguments: NSDictionary, result: @escaping FlutterResult) {
        flutterResult = result;
        let parameters = NSMutableDictionary()
        var payments: [PKPaymentNetwork] = []
        var items = [PKPaymentSummaryItem]()
        var totalPrice:Double = 0.0
        
        guard let paymentNeworks = arguments["paymentNetworks"] as? [String] else {return}
        guard let countryCode = arguments["countryCode"] as? String else {return}
        guard let currencyCode = arguments["currencyCode"] as? String else {return}
        
        guard let paymentItems = arguments["paymentItems"] as? [NSDictionary] else {return}
        guard let merchantName = arguments["merchantName"] as? String else {return}
        guard let isPending = arguments["isPending"] as? Bool else {return}
        
        let type = isPending ? PKPaymentSummaryItemType.pending : PKPaymentSummaryItemType.final;
        
        for dictionary in paymentItems {
            guard let label = dictionary["label"] as? String else {return}
            guard let price = dictionary["amount"] as? Double else {return}
            
            totalPrice += price
            
            items.append(PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(floatLiteral: price), type: type))
        }
        
        let total = PKPaymentSummaryItem(label: merchantName, amount: NSDecimalNumber(floatLiteral:totalPrice), type: type)
        items.append(total)
        
        paymentNeworks.forEach {
            
            guard let paymentType = PaymentSystem(rawValue: $0) else {
                assertionFailure("No payment type found")
                return
            }
            
            payments.append(paymentType.paymentNetwork)
        }
        
        parameters["paymentNetworks"] = payments
        parameters["requiredShippingContactFields"] = [PKContactField.name, PKContactField.postalAddress] as Set
        parameters["merchantCapabilities"] = PKMerchantCapability.capability3DS // optional
        
        parameters["countryCode"] = countryCode
        parameters["currencyCode"] = currencyCode
        
        parameters["paymentSummaryItems"] = items
        
        makePaymentRequest(parameters: parameters,  authCompletion: authorizationCompletion, authControllerCompletion: authorizationViewControllerDidFinish)
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
        channel.invokeMethod("onCancel", arguments: nil)
        flutterViewController.dismiss(animated: true)
    }
    
    public func addCardViewController(_ addCardViewController: STPAddCardViewController, didCreatePaymentMethod paymentMethod: STPPaymentMethod, completion: @escaping STPErrorBlock)
    {
        let paymentResponse: [String : Any] = ["status":"succeeded", "paymentMethodId" : paymentMethod.stripeId ]
        
        flutterResult!(paymentResponse)
        
        let flutterViewController = UIApplication.shared.delegate?.window?!.rootViewController as! FlutterViewController
        
        flutterViewController.dismiss(animated: true)
        
    }
    
    // Apple Pay specific Implementations
    func authorizationCompletion(_ payment: String) {
        // success
        //        var result: [String: Any] = [:]
        //
        //        result["token"] = payment.token.transactionIdentifier
        //        result["billingContact"] = payment.billingContact?.emailAddress
        //        result["shippingContact"] = payment.shippingContact?.emailAddress
        //        result["shippingMethod"] = payment.shippingMethod?.detail
        //
        flutterResult!(payment)
    }
    
    func authorizationViewControllerDidFinish(_ error : NSDictionary) {
        //error
        flutterResult!(error)
    }
    
    enum PaymentSystem: String {
        case visa
        case mastercard
        case amex
        case quicPay
        case chinaUnionPay
        case discover
        case interac
        case privateLabel
        
        var paymentNetwork: PKPaymentNetwork {
            
            switch self {
            case .mastercard: return PKPaymentNetwork.masterCard
            case .visa: return PKPaymentNetwork.visa
            case .amex: return PKPaymentNetwork.amex
            case .quicPay: return PKPaymentNetwork.quicPay
            case .chinaUnionPay: return PKPaymentNetwork.chinaUnionPay
            case .discover: return PKPaymentNetwork.discover
            case .interac: return PKPaymentNetwork.interac
            case .privateLabel: return PKPaymentNetwork.privateLabel
            }
        }
    }
    
    func makePaymentRequest(parameters: NSDictionary, authCompletion: @escaping AuthorizationCompletion, authControllerCompletion: @escaping AuthorizationViewControllerDidFinish) {
        
        if (STPPaymentConfiguration.shared.appleMerchantIdentifier == nil) {
            let error: NSDictionary = ["message": "Apple Merchant Id Not Set", "code": "400"]
            authControllerCompletion(error)
            return
        }
        
        guard let paymentNetworks               = parameters["paymentNetworks"]                 as? [PKPaymentNetwork] else {return}
        guard let requiredShippingContactFields = parameters["requiredShippingContactFields"]   as? Set<PKContactField> else {return}
        let merchantCapabilities : PKMerchantCapability = parameters["merchantCapabilities"]    as? PKMerchantCapability ?? .capability3DS
        
        guard let countryCode                   = parameters["countryCode"]                     as? String else {return}
        guard let currencyCode                  = parameters["currencyCode"]                    as? String else {return}
        
        guard let paymentSummaryItems           = parameters["paymentSummaryItems"]             as? [PKPaymentSummaryItem] else {return}
        
        authorizationCompletion = authCompletion
        authorizationViewControllerDidFinish = authControllerCompletion
        
        // Cards that should be accepted
        if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworks) {
            
            pkrequest.merchantIdentifier = STPPaymentConfiguration.shared.appleMerchantIdentifier!
            pkrequest.countryCode = countryCode
            pkrequest.currencyCode = currencyCode
            pkrequest.supportedNetworks = paymentNetworks
            pkrequest.requiredShippingContactFields = requiredShippingContactFields
            // This is based on using Stripe
            pkrequest.merchantCapabilities = merchantCapabilities
            
            pkrequest.paymentSummaryItems = paymentSummaryItems
            
            let authorizationViewController = PKPaymentAuthorizationViewController(paymentRequest: pkrequest)
            
            if let viewController = authorizationViewController {
                viewController.delegate = self
                guard let currentViewController = UIApplication.shared.keyWindow?.topMostViewController() else {
                    return
                }
                currentViewController.present(viewController, animated: true)
                
            }
        } else {
            let error: NSDictionary = ["message": "Apple Pay Not Supported for App. Does the App have ApplePay Passkit Enabled? Is the User Device Capable of Apple Pay?", "code": "404"]
            authControllerCompletion(error)
        }
        
        return
    }
    
    public func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        
        STPAPIClient.shared.createPaymentMethod(with: payment) { (stripeToken, error) in
            guard error == nil, let pm = stripeToken else {
                print(error!)
                completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
                return
            }
            
            self.authorizationCompletion(pm.stripeId)
            self.completionHandler = completion
        }
        
    }
    
    public func closeApplePaySheetWithSuccess() {
        if (self.completionHandler != nil) {
            self.completionHandler(PKPaymentAuthorizationResult(status: .success, errors: nil))
        }
    }
    
    public func closeApplePaySheetWithError() {
        if (self.completionHandler != nil) {
            self.completionHandler(PKPaymentAuthorizationResult(status: .failure, errors: nil))
        }
    }
    
    public func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        // Dismiss the Apple Pay UI
        guard let currentViewController = UIApplication.shared.keyWindow?.topMostViewController() else {
            return
        }
        currentViewController.dismiss(animated: true, completion: nil)
        let error: NSDictionary = ["message": "User closed apple pay", "code": "400"]
        authorizationViewControllerDidFinish(error)
    }
    
    func makePaymentSummaryItems(itemsParameters: Array<Dictionary <String, Any>>) -> [PKPaymentSummaryItem]? {
        var items = [PKPaymentSummaryItem]()
        var totalPrice:Decimal = 0.0
        
        for dictionary in itemsParameters {
            
            guard let label = dictionary["label"] as? String else {return nil}
            guard let amount = dictionary["amount"] as? NSDecimalNumber else {return nil}
            guard let type = dictionary["type"] as? PKPaymentSummaryItemType else {return nil}
            
            totalPrice += amount.decimalValue
            
            items.append(PKPaymentSummaryItem(label: label, amount: amount, type: type))
        }
        
        let total = PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(decimal:totalPrice), type: .final)
        items.append(total)
        print(items)
        return items
    }
}

extension UIWindow {
    func topMostViewController() -> UIViewController? {
        guard let rootViewController = self.rootViewController else {
            return nil
        }
        return topViewController(for: rootViewController)
    }
    
    func topViewController(for rootViewController: UIViewController?) -> UIViewController? {
        guard let rootViewController = rootViewController else {
            return nil
        }
        guard let presentedViewController = rootViewController.presentedViewController else {
            return rootViewController
        }
        switch presentedViewController {
        case is UINavigationController:
            let navigationController = presentedViewController as! UINavigationController
            return topViewController(for: navigationController.viewControllers.last)
        case is UITabBarController:
            let tabBarController = presentedViewController as! UITabBarController
            return topViewController(for: tabBarController.selectedViewController)
        default:
            return topViewController(for: presentedViewController)
        }
    }
}
