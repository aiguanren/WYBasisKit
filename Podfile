platform :ios, '13.0'
inhibit_all_warnings!
use_frameworks!
#use_frameworks! :linkage => :static：
use_modular_headers!

# 使用Cocoapods清华源
source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'

# 使用Cocoapods官方源
#source 'https://github.com/CocoaPods/Specs.git'

# 获取当前 Xcode 版本数组(返回值包含：主版本、次版本以及补丁版本)
def xcode_versions
  # 使用变量缓存避免重复获取
  return @cached_xcode_versions if @cached_xcode_versions
  
  output = `xcodebuild -version 2>&1`
  if output =~ /Xcode\s+(\d+(?:\.\d+){0,2})/
    versions = $1.split('.').map(&:to_i)
    puts "当前Xcode版本: #{versions.join('.')}"
    @cached_xcode_versions = versions
  else
    puts "⚠️ Podfile获取当前Xcode版本号失败 ⚠️"
    @cached_xcode_versions = [0, 0, 0] # 解析失败时返回安全值
  end
end

# 比较两个版本数组
def compare_versions(v1, v2)
  # 确保两个数组都有3个元素（不足的补0）
  v1 = (v1 + [0, 0, 0]).first(3)
  v2 = (v2 + [0, 0, 0]).first(3)
  
  # 依次比较主版本、次版本、补丁版本
  v1.each_with_index do |part, i|
    return -1 if part < v2[i]
    return 1 if part > v2[i]
  end
  0
end

# 检查 Xcode 版本是等于指定版本(参数依次为：主版本、次版本以及补丁版本)
def xcode_version_equal_to(major, minor = 0, patch = 0)
  current_version = xcode_versions
  target_version = [major, minor, patch]
  compare_versions(current_version, target_version) == 0
end

# 检查 Xcode 版本是否小于等于指定版本(参数依次为：主版本、次版本以及补丁版本)
def xcode_version_less_than_or_equal_to(major, minor = 0, patch = 0)
  current_version = xcode_versions
  target_version = [major, minor, patch]
  compare_versions(current_version, target_version) <= 0
end

# 检查 Xcode 版本是否大于等于指定版本(参数依次为：主版本、次版本以及补丁版本)
def xcode_version_greater_than_or_equal_to(major, minor = 0, patch = 0)
  current_version = xcode_versions
  target_version = [major, minor, patch]
  compare_versions(current_version, target_version) >= 0
end

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

