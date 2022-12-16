platform :ios, '12.0'
use_frameworks!
inhibit_all_warnings!

target 'Permanent' do
  pod 'Firebase/Analytics', '6.32.2'
  pod 'Firebase/Crashlytics', '6.32.2'
  pod 'Firebase/Messaging'
  pod 'Firebase/RemoteConfig'
  pod 'Protobuf', '3.21.11'
  pod 'ObjectMapper', '4.2.0'
  pod 'SDWebImage', '5.10.0'
  pod 'Sourcery', '1.4.1'
  pod 'GoogleMaps', '6.1.1.0'
  pod 'GooglePlaces', '6.1.1.0'
  pod 'KeychainSwift', '20.0'
  pod 'StripeApplePay', '22.8.1'
  pod 'SkeletonView', '1.30.4'

  target 'PermanentTests' do
        inherit! :search_paths
        pod 'Firebase'
  end

  target 'ShareExtension' do
        inherit! :search_paths
	pod 'KeychainSwift', '20.0'
  end
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
  end
end
