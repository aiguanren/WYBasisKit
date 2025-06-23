platform :ios, '13.0'
inhibit_all_warnings!
use_frameworks!
#use_frameworks! :linkage => :static：
use_modular_headers!

# 使用Cocoapods清华源
source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'

# 使用Cocoapods官方源
#source 'https://github.com/CocoaPods/Specs.git'

# 加载脚本管理器
require_relative 'PodFileScripts/Podfile'

# 选择设置选项（三选一）
# configure_settings_option(SETTING_OPTIONS[:pods_only])    # 只设置Pods项目
# configure_settings_option(SETTING_OPTIONS[:user_only])    # 只设置用户项目
configure_settings_option(SETTING_OPTIONS[:all_projects])   # 设置所有项目(默认)

# 设置Pods项目版本(仅限从Podfile解析部署版本失败时有效)
#set_pods_deployment_target('13.0')

workspace 'WYBasisKit.xcworkspace' # 多个项目时需要指定target对应的xcworkspace文件

target 'WYBasisKit' do
  project 'WYBasisKit/WYBasisKit.xcodeproj' # 多个项目时需要指定target对应的xcodeproj文件
  pod 'SnapKit'
  pod 'Kingfisher'
  pod 'Moya'
  # 根据Xcode版本号指定三方库的版本号
  if xcode_version_less_than_or_equal_to(14, 2)
    pod 'Alamofire', '5.9.1'
  end
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
  # 根据Xcode版本号指定三方库的版本号
  if xcode_version_less_than_or_equal_to(14, 2)
    pod 'Alamofire', '5.9.1'
    pod 'IQKeyboardManagerSwift', '7.0.0'
  else
    pod 'IQKeyboardManagerSwift'
  end
end

post_install do |installer|
  apply_selected_settings(installer)
end
