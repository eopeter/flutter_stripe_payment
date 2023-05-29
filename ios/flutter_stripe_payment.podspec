#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_stripe_payment.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_stripe_payment'
  s.version          = '0.0.13'
  s.summary          = 'Add Stripe to your Flutter Application to Accept Card Payments Using Payment Intents with Strong SCA 3DS Compliance'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Dorm Mom, Inc.' => 'eopeter@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'Stripe','23.8.0'
  s.dependency 'StripePaymentSheet','23.8.0'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end
