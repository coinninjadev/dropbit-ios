# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'
inhibit_all_warnings!

def shared_pods
  pod 'MMDrawerController', '~> 0.6.0'
  pod 'Permission/Camera', git: 'https://github.com/SixFiveSoftware/Permission.git', commit: '659c257'
  pod 'Permission/Notifications', git: 'https://github.com/SixFiveSoftware/Permission.git', commit: '659c257'
  pod 'Permission/Contacts', git: 'https://github.com/SixFiveSoftware/Permission.git', commit: '659c257'
  pod 'Permission/Location', git: 'https://github.com/SixFiveSoftware/Permission.git', commit: '659c257'
  pod 'SVProgressHUD', '~> 2.2.5'
  pod 'Moya', '~> 13.0.1'
  pod 'ReachabilitySwift', '~> 4.3.1'
  pod 'PhoneNumberKit', git: 'https://github.com/blwinters/PhoneNumberKit.git', commit: '4603819'
  pod 'JKSteppedProgressBar', git: 'https://github.com/MitchellMalleo/JKSteppedProgressBar.git', commit: '0519aa3'
  pod 'RNCryptor', '~> 5.1.0'
  pod 'DZNEmptyDataSet', '~> 1.8'
  pod 'Willow', '~> 5.0'
end

target 'DropBit' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for CoinKeeper
  pod 'Mixpanel-swift', '~> 2.6.2'
  shared_pods

  target 'DropBitTests' do
    inherit! :search_paths
    # Pods for testing
  end
end

target 'DropBitUITests' do
  # inherit! :search_paths
  shared_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    unless target.name.include?('DropBit') then
      target.build_configurations.each do |config|
        config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'DWARF'
      end
    end
  end
end
