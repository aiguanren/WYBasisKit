platform :ios, '13.0'
use_frameworks!
#use_frameworks! :linkage => :static
use_modular_headers!
inhibit_all_warnings!
install! 'cocoapods', warn_for_unused_master_specs_repo: false

# 使用Cocoapods清华源
#source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'

# 使用Cocoapods官方源
source 'https://github.com/CocoaPods/Specs.git'

# 加载脚本管理器
require_relative 'Scripts/PodFileConfig/Podfile'

# 执行本地验证或者pod命令的时候需要把podspec里面kit_path设置为 ""(空) 才能正确加载代码、资源等文件，然后等pod install/update执行失败或者成功后再还原kit_path
modify_kit_path_in_podspec("./WYBasisKit/WYBasisKit/WYBasisKit/WYBasisKit-Swift.podspec", "", false)
modify_kit_path_in_podspec("./WYBasisKit/WYBasisKit/WYBasisKit/WYBasisKit-ObjC.podspec", "", false)

# 内部之所以要用if else区分，主要是体现出如何判断执行失败和成功
at_exit do
  if $! # $! 不为空说明有异常
    # pod install/update 执行失败
    
    # 执行失败后还原podspec文件中要修改的kit_path的值
    restore_kit_path_in_podspec(false)
  else
    # pod install/update 执行成功
    
    # 执行成功后还原podspec文件中要修改的kit_path的值
    restore_kit_path_in_podspec(false)
  end
end

# 选择设置选项（三选一）
# configure_settings_option(SETTING_OPTIONS[:pods_only])    # 只设置Pods项目
# configure_settings_option(SETTING_OPTIONS[:user_only])    # 只设置用户项目
configure_settings_option(SETTING_OPTIONS[:all_projects])   # 设置所有项目(默认)

# 设置Pods项目版本(仅限从Podfile解析部署版本失败时有效)
#configure_pods_deployment_target('13.0')

# 多个项目时需要指定target对应的xcworkspace文件
workspace 'WYBasisKit.xcworkspace'

KITPATH = 'WYBasisKit/WYBasisKit/WYBasisKit'

target 'WYBasisKit' do
  
  # 多个项目时需要指定target对应的xcodeproj文件
  project 'WYBasisKit/WYBasisKit.xcodeproj'
  
  # 约束
  pod 'SnapKit'
  
  # 图片下载/缓存
  pod 'Kingfisher'
  
  # 网络请求
  pod 'Moya'

  # 根据Xcode版本号指定三方库的版本号
  if xcode_version_less_than_or_equal_to(14, 2)
    # 网络请求
    pod 'Alamofire', '5.9.1'
  end
end

target 'SwiftVerify' do
  project 'SwiftVerify/SwiftVerify.xcodeproj' # 多个项目时需要指定target对应的xcodeproj文件
  pod 'WYBasisKit-Swift', :path => KITPATH
  
  # 图片裁剪库
  #pod 'Mantis'
  
  # 照片选择库
  #pod 'ZLPhotoBrowser'
  
  # UIScrollView刷新header和footer
  #pod 'MJRefresh'
  
  # 根据Xcode版本号指定三方库的版本号
  if xcode_version_less_than_or_equal_to(14, 2)
    # 网络请求
    pod 'Alamofire', '5.9.1'
    
    # 管理键盘弹出时的界面适配
    pod 'IQKeyboardManagerSwift', '7.0.0'
  else
    pod 'IQKeyboardManagerSwift'
  end
  
end

target 'ObjCVerify' do
  project 'ObjCVerify/ObjCVerify.xcodeproj' # 多个项目时需要指定target对应的xcodeproj文件
  pod 'WYBasisKit-ObjC', :path => KITPATH
  
  # 图片裁剪库
  #pod 'Mantis'
  
  # 照片选择库
  #pod 'ZLPhotoBrowser'
  
  # UIScrollView刷新header和footer
  #pod 'MJRefresh'
  
  # 约束
  pod 'Masonry'
  
  # 图片下载/缓存
  pod 'SDWebImage'
  
  # 根据Xcode版本号指定三方库的版本号
  if xcode_version_less_than_or_equal_to(14, 2)
    # 网络请求
    pod 'Alamofire', '5.9.1'
    
    # 管理键盘弹出时的界面适配
    pod 'IQKeyboardManagerSwift', '7.0.0'
  else
    pod 'IQKeyboardManagerSwift'
  end
  
end


# 准备执行pod命令(执行pod命令前的处理)
pre_install do |installer|
  
end

# 结束执行pod命令(执行pod命令后的处理)
post_install do |installer|
  apply_selected_settings(installer)
end
