# 定义podspec执行路径(远程验证时路径是从WYBasisKit开始的，所以远程验证时需要填入podspec文件的路径：WYBasisKit/WYBasisKit/WYBasisKit/)
kit_path = "WYBasisKit/WYBasisKit/WYBasisKit/"

Pod::Spec.new do |kit|
  kit.name         = "WYBasisKit-SwiftUI"
  kit.version      = "26.3.0"
  kit.summary      = "WYBasisKit 不仅可以帮助开发者快速构建一个工程，还有基于常用网络框架和系统API而封装的各种实用方法、扩展，开发者只需简单的调用API就可以快速实现相应功能， 大幅提高开发效率。"
  kit.description  = <<-DESC
    Localizable: 国际化解决方案
    Extension: 各种系统扩展
    Networking: 网络请求解决方案
    Activity: 活动指示器
    Storage: 本地存储
    Layout: 各种自定义控件(注意：ChatView尚未开发完毕，敬请期待)
    Codable: 数据解析
    Authorization: 各种权限请求与判断
    LogManager: 日志打印，日志导出等日志管理相关
    AudioKit: 音频录制与播放
  DESC
  
  kit.homepage     = "https://github.com/aiguanren/WYBasisKit"
  kit.license      = { :type => "MIT", :file => "#{kit_path}License.md" }
  kit.author             = { "官人" => "aiguanren@icloud.com" }
  kit.ios.deployment_target = "13.0"
  kit.source       = { :git => "https://github.com/aiguanren/WYBasisKit.git", :tag => "#{kit.version}" }
  #kit.source       = { :svn => "http://192.168.xxx.xxx:xxxx/xxx/xxx/WYBasiskit"}
  #kit.source       = { :http => "http://192.168.xxx.xxx:xxxx/xxx/xxx/WYBasiskit.zip" }
  kit.resource_bundles = {"WYBasisKitSwiftUI" => [
    "#{kit_path}SwiftUI/PrivacyInfo.xcprivacy"
  ]}
  kit.swift_versions = ["5"]
  #kit.swift_version = "5.0"
  kit.requires_arc = true
  
  # 设置框架类型，若设为 true（静态框架），能优化 App 启动速度，避免 +load 方法丢失、分类找不到等问题，代码直接链接进主二进制，无额外动态库加载开销; 若设为 false（动态框架），则可被多个扩展（Extension）共享，减少主二进制体积，但会略微增加启动时间，且可能影响 category 加载; 作为Cocoapods库，我们不建议在这里写死为True或False，而是建议让用户在 Podfile 中通过 use_frameworks! :linkage => :static/:dynamic 自行控制链接方式，因为不同项目对包体积、启动速度、扩展共享的需求不同，由 App 层面统一控制更灵活，避免库作者强制选择带来的局限性。
  #kit.static_framework = true 
  
  # 这里需要忽略前面的lib和后面的tbd，例如libz.tbd直接写为z即可，如果是.a则需要写全，如："xxx.a"
  # kit.libraries = "z", "xxx.a"  # 这里的.a是指系统的
  # kit.vendored_libraries = "xxx.a"  # 这里的.a是指第三方或者自己自定义的
  # 手动指定模块名
  kit.module_name  = "WYBasisKitSwiftUI" 
  
  # 指定默认模块，不指定则表示全部模块
  # kit.default_subspecs = [
  #   "Config",
  #   "LogManager",
  #   "Extension",
  #   "Storage",
  #   "EventHandler"
  # ]

  # 安装时执行配置脚本(如需Push到Cocoapods远程，不可使用此方法，会因为安全原因被Cocoapods拒绝)
  # kit.prepare_command = <<-CMD
  #   bash #{kit_path}WYBasisKit.sh
  #   python3 #{kit_path}WYBasisKit.py
  # CMD

  # 编译时执行配置脚本(该脚本仅针对当前pod库target编译时生效，主工程target编译后不会执行)
  # kit.script_phase = {
  #   :name => "WYBasisKit",
  #   :script => "python3 #{kit_path}WYBasisKit.py",
  #   :execution_position => :before_compile
  # }

  # 主工程设置
  # kit.user_target_xcconfig = {
  #   "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64" # 跟多常见设置可以参照kit.pod_target_xcconfig
  # }

  # Pod工程设置
  # kit.pod_target_xcconfig = {
  #   "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64", # 过滤模拟器arm64，解决M系列芯片MAC上模拟器架构问题
  #   "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) WYBasisKit_SUPPORTS_SIMULATOR_FULL=1",  # 用于 Objective-C 的 #if 判断
  #   "SWIFT_ACTIVE_COMPILATION_CONDITIONS" => "$(inherited) WYBasisKit_SUPPORTS_SIMULATOR_FULL", # 用于 Swift 的 #if 判断（注意不带 =1，就是直接使用宏名即可）
  #   "OTHER_LDFLAGS[sdk=iphonesimulator*]" => "", # 模拟器环境下清空与 aaa.xcframework 相关的链接标记，避免链接导致的验证不通过与编译错误(如果aaa.xcframework仅支持真机又想让模拟器环境编译通过就需要设置)
  #   "LD_RUNPATH_SEARCH_PATHS[sdk=iphonesimulator*]" => "" # 模拟器环境下清空与 aaa.xcframework 相关的运行路径设置，避免链接导致的验证不通过与编译错误(如果aaa.xcframework仅支持真机又想让模拟器环境编译通过就需要设置)
  # }

  # 排除匹配某个文件夹下面的所有文件和文件夹，如排除匹配aaa文件夹下面的所有文件和文件夹
  # kit.exclude_files = [
  #   "#{kit_path}aaa/**/*"
  # ] 

  # 放置Assets.xcassets到pods中方便图片资源加载(与.Bundle互补)
  # kit.resource_bundles = {
  #   'WYBasisKitSwift' => [
  #             'Assets/Assets.xcassets',
  #             ]
  # } 
  
  kit.subspec "Extension" do |extension|
    extension.source_files = [
      "#{kit_path}SwiftUI/Extension/**/*.{swift,h,m}"
    ]
    extension.resource_bundles = {"WYBasisKitSwiftUIExtension" => [
      "#{kit_path}SwiftUI/Extension/PrivacyInfo.xcprivacy"
    ]}
    extension.frameworks = "UIKit", "SwiftUI"
  end

end
