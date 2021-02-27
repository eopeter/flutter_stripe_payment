#import "FlutterStripePaymentPlugin.h"
#if __has_include(<flutter_stripe_payment/flutter_stripe_payment-Swift.h>)
#import <flutter_stripe_payment/flutter_stripe_payment-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_stripe_payment-Swift.h"
#endif

@implementation FlutterStripePaymentPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterStripePaymentPlugin registerWithRegistrar:registrar];
}
@end
