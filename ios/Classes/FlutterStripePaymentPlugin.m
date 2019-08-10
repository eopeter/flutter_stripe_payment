#import "FlutterStripePaymentPlugin.h"
#import <flutter_stripe_payment/flutter_stripe_payment-Swift.h>

@implementation FlutterStripePaymentPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterStripePaymentPlugin registerWithRegistrar:registrar];
}
@end
