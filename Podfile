platform :osx, '10.12'
use_frameworks!

# ignore all warnings from all pods
inhibit_all_warnings!

target 'MeteoBar' do
    pod 'SwiftyBeaver'
    pod 'Preferences'
    pod 'Alamofire'
    pod 'SwiftyJSON'
    pod 'Repeat'
    pod 'SwiftyUserDefaults', '4.0.0-alpha.1'
end

=begin
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['CONFIGURATION_BUILD_DIR'] = '$PODS_CONFIGURATION_BUILD_DIR'
        end
    end
end
=end
