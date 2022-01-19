platform :ios, '12.0'
use_frameworks!
inhibit_all_warnings!

target 'Permanent' do
  pod 'Firebase/Analytics', '6.32.2'
  pod 'Firebase/Crashlytics', '6.32.2'
  pod 'Firebase/Messaging'
  pod 'ObjectMapper', '4.2.0'
  pod 'SDWebImage', '5.10.0'
  pod 'Sourcery', '1.4.1'
  pod 'GoogleMaps', '6.0.1'
  pod 'GooglePlaces', '6.0.0'

  target 'PermanentTests' do
        inherit! :search_paths
        pod 'Firebase'
    end
end