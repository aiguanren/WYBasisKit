# 定义podspec执行路径(远程验证时路径是从WYBasisKit开始的，所以远程验证时需要填入podspec文件的路径：WYBasisKit/WYBasisKit/WYBasisKit/)
kit_path = "WYBasisKit/WYBasisKit/WYBasisKit/"

# 国际化资源需要的Bundle
localizable_bundle = "#{kit_path}Swift/Localizable/WYLocalizable.bundle"

Pod::Spec.new do |kit|
  kit.name         = "WYBasisKit-swift"
  kit.version      = "2.1.2"
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
  kit.resource_bundles = {"WYBasisKitSwift" => [
    "#{kit_path}PrivacyInfo.xcprivacy"
  ]}
  kit.swift_versions = ["5"]
  #kit.swift_version = "5.0"
  kit.requires_arc = true
  #kit.static_framework = true # 开启后OC工程编译会报错找不到swift相关版本链接库
  # 这里需要忽略前面的lib和后面的tbd，例如libz.tbd直接写为z即可，如果是.a则需要写全，如："xxx.a"
  # kit.libraries = "z", "xxx.a"  # 这里的.a是指系统的
  # kit.vendored_libraries = "xxx.a"  # 这里的.a是指第三方或者自己自定义的
  # 手动指定模块名
  kit.module_name  = "WYBasisKitSwift" 
  
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

  kit.subspec "Config" do |config|
    config.source_files = [
      "#{kit_path}Swift/Config/**/*.{swift,h,m}"
    ]
    config.resource_bundles = {"WYBasisKitSwiftConfig" => [
      "#{kit_path}Swift/Config/PrivacyInfo.xcprivacy"
    ]}
    config.frameworks = "Foundation", "UIKit"
  end

  kit.subspec "LogManager" do |logManager|
    logManager.source_files = [
      "#{kit_path}Swift/LogManager/**/*.{swift,h,m}",
      "#{kit_path}Swift/Extension/UIApplication/**/*.{swift,h,m}"
    ]
    logManager.resource_bundles = {"WYBasisKitSwiftLogManager" => [
      "#{kit_path}Swift/LogManager/PrivacyInfo.xcprivacy"
    ]}
    logManager.frameworks = "Foundation", "UIKit"
  end
  
  kit.subspec "Localizable" do |localizable|
    localizable.source_files = [
      "#{kit_path}Swift/Localizable/**/*.{swift,h,m}"
    ]
    localizable.resource_bundles = {"WYBasisKitSwiftLocalizable" => [
      "#{kit_path}Swift/Localizable/PrivacyInfo.xcprivacy"
    ]}
    localizable.frameworks = "Foundation", "UIKit"
    localizable.dependency "WYBasisKit-swift/Config"
  end
  
  kit.subspec "Extension" do |extension|
    extension.source_files = [
      "#{kit_path}Swift/Extension/**/*.{swift,h,m}"
    ]
    extension.resources = [localizable_bundle]
    extension.resource_bundles = {"WYBasisKitSwiftExtension" => [
      "#{kit_path}Swift/Extension/PrivacyInfo.xcprivacy"
    ]}
    extension.frameworks = "Foundation", "UIKit", "LocalAuthentication", "Photos", "CoreFoundation", "AudioToolbox", "CoreMotion", "CoreTelephony"
    extension.dependency "WYBasisKit-swift/Localizable"
    extension.dependency "WYBasisKit-swift/Config"
    extension.dependency "WYBasisKit-swift/LogManager"
  end
  
  kit.subspec "Codable" do |codable|
    codable.source_files = [
      "#{kit_path}Swift/Codable/**/*.{swift,h,m}"
    ]
    codable.resource_bundles = {"WYBasisKitSwiftCodable" => [
      "#{kit_path}Swift/Codable/PrivacyInfo.xcprivacy"
    ]}
    codable.frameworks = "Foundation", "UIKit"
  end
  
  kit.subspec "Networking" do |networking|
    networking.source_files = [
      "#{kit_path}Swift/Networking/**/*.{swift,h,m}",
      "#{kit_path}Swift/Extension/UIAlertController/**/*.{swift,h,m}",
      "#{kit_path}Swift/Extension/UIApplication/**/*.{swift,h,m}"
    ]
    networking.resources = [localizable_bundle]
    networking.resource_bundles = {"WYBasisKitSwiftNetworking" => [
      "#{kit_path}Swift/Networking/PrivacyInfo.xcprivacy"
    ]}
    networking.frameworks = "Foundation", "UIKit", "Network"
    networking.dependency "WYBasisKit-swift/Localizable"
    networking.dependency "WYBasisKit-swift/Storage"
    networking.dependency "WYBasisKit-swift/Codable"
    networking.dependency "Moya"
  end
  
  kit.subspec "Activity" do |activity|
    activity.source_files = [
      "#{kit_path}Swift/Activity/**/*.{swift,h,m}",
      "#{kit_path}Swift/Extension/UIView/**/*.{swift,h,m}",
      "#{kit_path}Swift/Extension/UIViewController/**/*.{swift,h,m}",
      "#{kit_path}Swift/Extension/AttributedString/**/*.{swift,h,m}",
      "#{kit_path}Swift/Extension/String/**/*.{swift,h,m}",
      "#{kit_path}Swift/Extension/UIImage/**/*.{swift,h,m}",
      "#{kit_path}Swift/Extension/UIDevice/**/*.{swift,h,m}",
      "#{kit_path}Swift/Config/**/*.{swift}"
    ]
    activity.resources = [
      localizable_bundle,
      "#{kit_path}Swift/Activity/WYActivity.bundle"
    ]
    activity.resource_bundles = {"WYBasisKitSwiftActivity" => [
      "#{kit_path}Swift/Activity/PrivacyInfo.xcprivacy"
    ]}
    activity.frameworks = "Foundation", "UIKit"
    activity.dependency "WYBasisKit-swift/Localizable"
    activity.dependency "WYBasisKit-swift/LogManager"
  end
  
  kit.subspec "Storage" do |storage|
    storage.source_files = [
      "#{kit_path}Swift/Storage/**/*.{swift,h,m}"
    ]
    storage.resource_bundles = {"WYBasisKitSwiftStorage" => [
      "#{kit_path}Swift/Storage/PrivacyInfo.xcprivacy"
    ]}
    storage.frameworks = "Foundation", "UIKit"
  end

  kit.subspec "EventHandler" do |eventHandler|
    eventHandler.source_files = [
      "#{kit_path}Swift/EventHandler/**/*.{swift,h,m}"
    ]
    eventHandler.resource_bundles = {"WYBasisKitSwiftEventHandler" => [
      "#{kit_path}Swift/EventHandler/PrivacyInfo.xcprivacy"
    ]}
    eventHandler.frameworks = "Foundation"
  end

  kit.subspec "AudioKit" do |audioKit|
    audioKit.source_files = [
      "#{kit_path}Swift/AudioKit/**/*.{swift,h,m}"
    ] 
    audioKit.resource_bundles = {"WYBasisKitSwiftAudioKit" => [
      "#{kit_path}Swift/AudioKit/PrivacyInfo.xcprivacy"
    ]}
    audioKit.frameworks = "Foundation", "AVFoundation", "Combine", "QuartzCore"
  end
  
  kit.subspec "Authorization" do |authorization|
    authorization.resource_bundles = {"WYBasisKitSwiftAuthorization" => [
      "#{kit_path}Swift/Authorization/PrivacyInfo.xcprivacy"
    ]}
    authorization.subspec "Camera" do |camera|
      camera.source_files = [
        "#{kit_path}Swift/Authorization/Camera/**/*.{swift,h,m}",
        "#{kit_path}Swift/Extension/UIAlertController/**/*.{swift,h,m}"
      ]
      camera.resources = [localizable_bundle]
      camera.resource_bundles = {"WYBasisKitSwiftAuthorizationCamera" => [
        "#{kit_path}Swift/Authorization/Camera/PrivacyInfo.xcprivacy"
      ]}
      camera.frameworks = "AVFoundation", "UIKit", "Photos"
      camera.dependency "WYBasisKit-swift/Localizable"
      camera.dependency "WYBasisKit-swift/LogManager"
    end
    
    authorization.subspec "Biometric" do |biometric|
      biometric.source_files = [
        "#{kit_path}Swift/Authorization/Biometric/**/*.{swift,h,m}"
      ]
      biometric.resources = [localizable_bundle]
      biometric.resource_bundles = {"WYBasisKitSwiftAuthorizationBiometric" => [
        "#{kit_path}Swift/Authorization/Biometric/PrivacyInfo.xcprivacy"
      ]}
      biometric.frameworks = "Foundation", "LocalAuthentication"
      biometric.dependency "WYBasisKit-swift/Localizable"
      biometric.dependency "WYBasisKit-swift/LogManager"
    end
    
    authorization.subspec "Contacts" do |contacts|
      contacts.source_files = [
        "#{kit_path}Swift/Authorization/Contacts/**/*.{swift,h,m}",
        "#{kit_path}Swift/Extension/UIAlertController/**/*.{swift,h,m}"
      ]
      contacts.resources = [localizable_bundle]
      contacts.resource_bundles = {"WYBasisKitSwiftAuthorizationContacts" => [
        "#{kit_path}Swift/Authorization/Contacts/PrivacyInfo.xcprivacy"
      ]}
      contacts.frameworks = "Contacts", "UIKit"
      contacts.dependency "WYBasisKit-swift/Localizable"
      contacts.dependency "WYBasisKit-swift/LogManager"
    end
    
    authorization.subspec "PhotoAlbums" do |photoAlbums|
      photoAlbums.source_files = [
        "#{kit_path}Swift/Authorization/PhotoAlbums/**/*.{swift,h,m}",
        "#{kit_path}Swift/Extension/UIAlertController/**/*.{swift,h,m}"
      ]
      photoAlbums.resources = [localizable_bundle]
      photoAlbums.resource_bundles = {"WYBasisKitSwiftAuthorizationPhotoAlbums" => [
        "#{kit_path}Swift/Authorization/PhotoAlbums/PrivacyInfo.xcprivacy"
      ]}
      photoAlbums.frameworks = "Photos", "UIKit"
      photoAlbums.dependency "WYBasisKit-swift/Localizable"
      photoAlbums.dependency "WYBasisKit-swift/LogManager"
    end
    
    authorization.subspec "Microphone" do |microphone|
      microphone.source_files = [
        "#{kit_path}Swift/Authorization/Microphone/**/*.{swift,h,m}",
        "#{kit_path}Swift/Extension/UIAlertController/**/*.{swift,h,m}"
      ]
      microphone.resources = [localizable_bundle]
      microphone.resource_bundles = {"WYBasisKitSwiftAuthorizationMicrophone" => [
        "#{kit_path}Swift/Authorization/Microphone/PrivacyInfo.xcprivacy"
      ]}
      microphone.frameworks = "Photos", "UIKit"
      microphone.dependency "WYBasisKit-swift/Localizable"
      microphone.dependency "WYBasisKit-swift/LogManager"
    end
    
    authorization.subspec "SpeechRecognition" do |speechRecognition|
      speechRecognition.source_files = [
        "#{kit_path}Swift/Authorization/SpeechRecognition/**/*.{swift,h,m}",
        "#{kit_path}Swift/Extension/UIAlertController/**/*.{swift,h,m}"
      ]
      speechRecognition.resources = [localizable_bundle]
      speechRecognition.resource_bundles = {"WYBasisKitSwiftAuthorizationSpeechRecognition" => [
        "#{kit_path}Swift/Authorization/SpeechRecognition/PrivacyInfo.xcprivacy"
      ]}
      speechRecognition.frameworks = "Speech", "UIKit"
      speechRecognition.dependency "WYBasisKit-swift/Localizable"
      speechRecognition.dependency "WYBasisKit-swift/LogManager"
    end
  end
  
  kit.subspec "Layout" do |layout|
    layout.resource_bundles = {"WYBasisKitSwiftLayout" => [
      "#{kit_path}Swift/Layout/PrivacyInfo.xcprivacy"
    ]}
    layout.subspec "ScrollText" do |scrollText|
      scrollText.source_files = [
        "#{kit_path}Swift/Layout/ScrollText/**/*.{swift,h,m}",
        "#{kit_path}Swift/Extension/UIFont/**/*.{swift,h,m}",
        "#{kit_path}Swift/Extension/UIDevice/**/*.{swift,h,m}",
        "#{kit_path}Swift/Extension/UIViewController/**/*.{swift,h,m}",
        "#{kit_path}Swift/Config/**/*.{swift}"
      ]
      scrollText.resources = [localizable_bundle]
      scrollText.resource_bundles = {"WYBasisKitSwiftLayoutScrollText" => [
        "#{kit_path}Swift/Layout/ScrollText/PrivacyInfo.xcprivacy"
      ]}
      scrollText.frameworks = "Foundation", "UIKit"
      scrollText.dependency "WYBasisKit-swift/Localizable"
      scrollText.dependency "WYBasisKit-swift/LogManager"
    end
    
    layout.subspec "PagingView" do |pagingView|
      pagingView.source_files = [
        "#{kit_path}Swift/Layout/PagingView/**/*.{swift,h,m}",
        "#{kit_path}Swift/Extension/UIView/**/*.{swift,h,m}",
        "#{kit_path}Swift/Extension/UIButton/**/*.{swift,h,m}",
        "#{kit_path}Swift/Extension/UIColor/**/*.{swift,h,m}",
        "#{kit_path}Swift/Extension/UIImage/**/*.{swift,h,m}",
        "#{kit_path}Swift/Extension/UIDevice/**/*.{swift,h,m}",
        "#{kit_path}Swift/Extension/UIFont/**/*.{swift,h,m}",
        "#{kit_path}Swift/Extension/UIViewController/**/*.{swift,h,m}",
        "#{kit_path}Swift/Config/**/*.{swift,h,m}"
      ]
      pagingView.resource_bundles = {"WYBasisKitSwiftLayoutPagingView" => [
        "#{kit_path}Swift/Layout/PagingView/PrivacyInfo.xcprivacy"
      ]}
      pagingView.frameworks = "Foundation", "UIKit"
      pagingView.dependency "WYBasisKit-swift/LogManager"
    end
    
    layout.subspec "BannerView" do |bannerView|
      bannerView.source_files = [
        "#{kit_path}Swift/Layout/BannerView/**/*.{swift,h,m}",
        "#{kit_path}Swift/Extension/UIView/**/*.{swift,h,m}",
        "#{kit_path}Swift/Extension/UIDevice/**/*.{swift,h,m}",
        "#{kit_path}Swift/Extension/UIViewController/**/*.{swift,h,m}",
        "#{kit_path}Swift/Extension/UIApplication/**/*.{swift,h,m}",
        "#{kit_path}Swift/Config/**/*.{swift,h,m}"
      ]
      bannerView.resources = [
        localizable_bundle,
        "#{kit_path}Swift/Layout/BannerView/WYBannerView.bundle"
      ]
      bannerView.resource_bundles = {"WYBasisKitSwiftLayoutBannerView" => [
        "#{kit_path}Swift/Layout/BannerView/PrivacyInfo.xcprivacy"
      ]}
      bannerView.frameworks = "Foundation", "UIKit"
      bannerView.dependency "WYBasisKit-swift/Localizable"
      bannerView.dependency "WYBasisKit-swift/LogManager"
    end
    
    layout.subspec "ChatView" do |chatView|
      chatView.source_files = [
        "#{kit_path}Swift/Layout/ChatView/**/*.{swift,h,m}",
      ]
      chatView.resources = [
        "#{kit_path}Swift/Layout/ChatView/WYChatView.bundle"
      ]
      chatView.resource_bundles = {"WYBasisKitSwiftLayoutChatView" => [
         "#{kit_path}Swift/Layout/ChatView/PrivacyInfo.xcprivacy"
      ]}
      chatView.frameworks = "Foundation", "UIKit"
      chatView.dependency "WYBasisKit-swift/Extension"
      chatView.dependency "WYBasisKit-swift/Localizable"
      chatView.dependency "WYBasisKit-swift/Authorization/Microphone"
      chatView.dependency "WYBasisKit-swift/Storage"
      chatView.dependency "WYBasisKit-swift/LogManager"
      chatView.dependency "SnapKit"
      chatView.dependency "Kingfisher"
    end

    layout.subspec "MediaPlayer" do |mediaPlayer|
      mediaPlayer.source_files = [
        "#{kit_path}Swift/Layout/MediaPlayer/**/*.{swift,h,m}"
      ]
      mediaPlayer.resource_bundles = {"WYBasisKitSwiftMediaPlayerFS" => [
      "#{kit_path}Swift/Layout/MediaPlayer/PrivacyInfo.xcprivacy"
      ]}
      mediaPlayer.dependency "IJKPlayerKit"
    end
  end
end
