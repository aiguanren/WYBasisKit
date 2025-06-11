platform :ios, '13.0'
inhibit_all_warnings!
use_frameworks!
#use_frameworks! :linkage => :static：
use_modular_headers!

# 使用Cocoapods清华源
source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'

# 使用Cocoapods官方源
#source 'https://github.com/CocoaPods/Specs.git'

workspace 'WYBasisKit.xcworkspace' # 多个项目时需要指定target对应的xcworkspace文件

target 'WYBasisKit' do
  project 'WYBasisKit/WYBasisKit.xcodeproj' # 多个项目时需要指定target对应的xcodeproj文件
  pod 'SnapKit'
  pod 'Kingfisher'
  pod 'Moya'
end

target 'WYBasisKitVerify' do
  project 'WYBasisKitVerify/WYBasisKitVerify.xcodeproj' # 多个项目时需要指定target对应的xcodeproj文件
  pod 'WYBasisKit-swift', :path => '.'
  pod 'WYBasisKit-swift/Networking', :path => '.'
  pod 'WYBasisKit-swift/Layout', :path => '.'
  pod 'WYBasisKit-swift/MediaPlayer/Full', :path => '.'
  #pod 'WYBasisKit-swift/MediaPlayer/Lite', :path => '.'
  pod 'WYBasisKit-swift/Localizable', :path => '.'
  pod 'WYBasisKit-swift/Activity', :path => '.'
  pod 'WYBasisKit-swift/Storage', :path => '.'
  pod 'WYBasisKit-swift/Codable', :path => '.'
  pod 'WYBasisKit-swift/Authorization', :path => '.'
  pod 'IQKeyboardManagerSwift'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
      xcconfig_path = config.base_configuration_reference.real_path
      xcconfig = File.read(xcconfig_path)
      xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
      File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
    end
  end
end

