#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_stripe_payment'
  s.version          = '0.0.7'
  s.summary          = 'Add Stripe to your Flutter Application to Accept Card Payments for Android and iOS'
  s.description      = <<-DESC
Add Stripe to your Flutter Application to Accept Card Payments for Android and iOS
                       DESC
  s.homepage         = 'https://dormmom.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Dorm Mom, Inc.' => 'eopeter@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'Stripe','18.2.0'
  s.ios.deployment_target = '9.0'
end

