# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'
inhibit_all_warnings!

target 'DropBit' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for CoinKeeper
  pod 'Mixpanel-swift', '~> 2.5.0'
  pod 'MMDrawerController', '~> 0.5.7'
  pod 'Permission/Camera', git: 'https://github.com/pahmed/Permission.git', commit: '8b47d5f'
  pod 'Permission/Notifications', git: 'https://github.com/pahmed/Permission.git', commit: '8b47d5f'
  pod 'Permission/Contacts', git: 'https://github.com/pahmed/Permission.git', commit: '8b47d5f'
  pod 'Permission/Location', git: 'https://github.com/pahmed/Permission.git', commit: '8b47d5f'
  pod 'SVProgressHUD'
  pod 'Moya', '~> 11.0.2'
  pod 'Result'
  pod 'ReachabilitySwift'
  pod 'PhoneNumberKit', git: 'https://github.com/blwinters/PhoneNumberKit.git', commit: '18b0a34'
  pod 'JKSteppedProgressBar', git: 'https://github.com/MitchellMalleo/JKSteppedProgressBar.git', commit: 'a41db05'
  pod 'RNCryptor', '~> 5.0'
  pod 'DZNEmptyDataSet', '~> 1.8'

  target 'DropBitTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'DropBitUITests' do
    inherit! :search_paths
  end

end
