platform :ios, '14.7'
use_frameworks!
inhibit_all_warnings!

target 'Permanent' do
  pod 'Firebase/Analytics', '11.1.0'
  pod 'Firebase/Crashlytics', '11.1.0'
  pod 'Firebase/Messaging', '11.1.0'
  pod 'Firebase/RemoteConfig', '11.1.0'
  pod 'Protobuf', '3.22.3'
  pod 'ObjectMapper', '4.2.0'
  pod 'SDWebImage', '5.10.0'
  pod 'SDWebImageSwiftUI', '2.2.3'
  pod 'Sourcery', '1.4.1'
  pod 'GoogleMaps', '8.4.0'
  pod 'GooglePlaces', '8.5.0'
  pod 'KeychainSwift', '20.0'
  pod 'StripeApplePay', '22.8.1'
  pod 'SkeletonView', '1.30.4'
  pod 'Mixpanel-swift', '4.3.0'

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

  installer.generated_projects.each do |project|
    project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.7'
         end
    end
  end

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['DEVELOPMENT_TEAM'] = 'C8YKZNBVWT'
    end
  end
end
