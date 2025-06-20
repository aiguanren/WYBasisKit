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

SDK = 'WYBasisKit/WYBasisKit/WYBasisKit'
target 'WYBasisKitVerify' do
  project 'WYBasisKitVerify/WYBasisKitVerify.xcodeproj' # 多个项目时需要指定target对应的xcodeproj文件
  #pod 'WYBasisKit-swift', :path => SDK
  pod 'WYBasisKit-swift/Extension', :path => SDK
  pod 'WYBasisKit-swift/Networking', :path => SDK
  pod 'WYBasisKit-swift/Layout', :path => SDK
  pod 'WYBasisKit-swift/MediaPlayer/Full', :path => SDK
  #pod 'WYBasisKit-swift/MediaPlayer/Lite', :path => SDK
  pod 'WYBasisKit-swift/Localizable', :path => SDK
  pod 'WYBasisKit-swift/Activity', :path => SDK
  pod 'WYBasisKit-swift/Storage', :path => SDK
  pod 'WYBasisKit-swift/Codable', :path => SDK
  pod 'WYBasisKit-swift/Authorization', :path => SDK
  pod 'IQKeyboardManagerSwift'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 设置最低部署版本为 iOS 13.0
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      # 在模拟器构建时排除 arm64 架构（M1/M2 模拟器上防止冲突或编译失败）
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
      # 替换 xcconfig 文件中可能存在的 DT_TOOLCHAIN_DIR 引用，解决部分 Xcode 环境的构建警告
      xcconfig_path = config.base_configuration_reference.real_path
      xcconfig = File.read(xcconfig_path)
      xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
      File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
    end
  end
end

