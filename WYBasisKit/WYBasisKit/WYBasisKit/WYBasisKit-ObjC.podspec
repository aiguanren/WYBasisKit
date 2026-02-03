# 定义podspec执行路径(远程验证时路径是从WYBasisKit开始的，所以远程验证时需要填入podspec文件的路径：WYBasisKit/WYBasisKit/WYBasisKit/)
kit_path = "WYBasisKit/WYBasisKit/WYBasisKit/"

Pod::Spec.new do |kit|
  kit.name         = "WYBasisKit-ObjC"
  kit.version      = "2.1.1"
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
  kit.resource_bundles = {"WYBasisKitObjC" => [
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
  kit.module_name  = "WYBasisKitObjC" 
  
  # 指定默认模块，不指定则表示全部模块
  # kit.default_subspecs = [
  #   "Config",
  #   "LogManager",
  #   "Extension",
  #   "Storage",
  #   "EventHandler"
  # ]

  # 主工程设置
  # kit.user_target_xcconfig = {
  #   "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64" # 跟多常见设置可以参照kit.pod_target_xcconfig
  # }

  # Pod工程设置
  # kit.pod_target_xcconfig = {
  #   "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) WYBasisKit_Supports_ObjC=1",  # 用于 Objective-C 的 #if 判断
  #   "SWIFT_ACTIVE_COMPILATION_CONDITIONS" => "$(inherited) WYBasisKit_Supports_ObjC", # 用于 Swift 的 #if 判断（注意不带 =1，就是直接使用宏名即可）    
  # }

  # 排除匹配某个文件夹下面的所有文件和文件夹，如排除匹配aaa文件夹下面的所有文件和文件夹
  # kit.exclude_files = [
  #   "#{kit_path}aaa/**/*"
  # ]  

  kit.subspec "Imports" do |imports|
    imports.source_files = [
      "#{kit_path}ObjC/Imports/**/*.{swift,h,m}"
    ]
    imports.public_header_files = [
      "#{kit_path}ObjC/Imports/**/*.{h,m}"
    ]
    imports.resource_bundles = {"WYBasisKitObjCImports" => [
      "#{kit_path}ObjC/Imports/PrivacyInfo.xcprivacy"
    ]}
    imports.frameworks = "Foundation", "UIKit"
  end

  kit.subspec "Config" do |config|
    config.source_files = [
      "#{kit_path}ObjC/Config/**/*.{swift,h,m}"
    ]
    config.resource_bundles = {"WYBasisKitObjCConfig" => [
      "#{kit_path}ObjC/Config/PrivacyInfo.xcprivacy"
    ]}
    config.frameworks = "Foundation", "UIKit"
    config.dependency "WYBasisKit-swift/Config"
    config.dependency "WYBasisKit-ObjC/Imports"
  end

  kit.subspec "LogManager" do |logManager|
    logManager.source_files = [
      "#{kit_path}ObjC/LogManager/**/*.{swift,h,m}"
    ]
    logManager.resource_bundles = {"WYBasisKitObjCLogManager" => [
      "#{kit_path}ObjC/LogManager/PrivacyInfo.xcprivacy"
    ]}
    logManager.frameworks = "Foundation", "UIKit"
    logManager.dependency "WYBasisKit-swift/LogManager"
    logManager.dependency "WYBasisKit-ObjC/Imports"
  end
  
  kit.subspec "Localizable" do |localizable|
    localizable.source_files = [
      "#{kit_path}ObjC/Localizable/**/*.{swift,h,m}"
    ]
    localizable.resource_bundles = {"WYBasisKitObjCLocalizable" => [
      "#{kit_path}ObjC/Localizable/PrivacyInfo.xcprivacy"
    ]}
    localizable.frameworks = "Foundation", "UIKit"
    localizable.dependency "WYBasisKit-swift/Localizable"
    localizable.dependency "WYBasisKit-ObjC/Config"
    localizable.dependency "WYBasisKit-ObjC/Imports"
  end
  
  kit.subspec "Extension" do |extension|
    extension.source_files = [
      "#{kit_path}ObjC/Extension/**/*.{swift,h,m}"
    ]
    extension.resource_bundles = {"WYBasisKitObjCExtension" => [
      "#{kit_path}ObjC/Extension/PrivacyInfo.xcprivacy"
    ]}
    extension.frameworks = "Foundation", "UIKit"
    extension.dependency "WYBasisKit-swift/Extension"
    extension.dependency "WYBasisKit-ObjC/Localizable"
    extension.dependency "WYBasisKit-ObjC/Config"
    extension.dependency "WYBasisKit-ObjC/LogManager"
    extension.dependency "WYBasisKit-ObjC/Imports"
  end
  
  kit.subspec "Codable" do |codable|
    codable.source_files = [
      "#{kit_path}ObjC/Codable/**/*.{swift,h,m}"
    ]
    codable.resource_bundles = {"WYBasisKitObjCCodable" => [
      "#{kit_path}ObjC/Codable/PrivacyInfo.xcprivacy"
    ]}
    codable.frameworks = "Foundation", "UIKit"
    codable.dependency "WYBasisKit-swift/Codable"
    codable.dependency "WYBasisKit-ObjC/Imports"
  end
  
  kit.subspec "Networking" do |networking|
    networking.source_files = [
      "#{kit_path}ObjC/Networking/**/*.{swift,h,m}"
    ]
    networking.resource_bundles = {"WYBasisKitObjCNetworking" => [
      "#{kit_path}ObjC/Networking/PrivacyInfo.xcprivacy"
    ]}
    networking.frameworks = "Foundation", "UIKit", "Network"
    networking.dependency "WYBasisKit-swift/Networking"
    networking.dependency "WYBasisKit-ObjC/Localizable"
    networking.dependency "WYBasisKit-ObjC/Storage"
    networking.dependency "WYBasisKit-ObjC/Codable"
    networking.dependency "WYBasisKit-ObjC/Imports"
  end
  
  kit.subspec "Activity" do |activity|
    activity.source_files = [
      "#{kit_path}ObjC/Activity/**/*.{swift,h,m}",
      "#{kit_path}ObjC/Extension/UIView/**/*.{swift,h,m}",
      "#{kit_path}ObjC/Extension/UIViewController/**/*.{swift,h,m}",
      "#{kit_path}ObjC/Extension/AttributedString/**/*.{swift,h,m}",
      "#{kit_path}ObjC/Extension/String/**/*.{swift,h,m}",
      "#{kit_path}ObjC/Extension/UIImage/**/*.{swift,h,m}",
      "#{kit_path}ObjC/Extension/UIDevice/**/*.{swift,h,m}",
      "#{kit_path}ObjC/Config/**/*.{swift}"
    ]
    activity.resource_bundles = {"WYBasisKitObjCActivity" => [
      "#{kit_path}ObjC/Activity/PrivacyInfo.xcprivacy"
    ]}
    activity.frameworks = "Foundation", "UIKit"
    activity.dependency "WYBasisKit-swift/Activity"
    activity.dependency "WYBasisKit-ObjC/Localizable"
    activity.dependency "WYBasisKit-ObjC/LogManager"
    activity.dependency "WYBasisKit-ObjC/Imports"
  end
  
  kit.subspec "Storage" do |storage|
    storage.source_files = [
      "#{kit_path}ObjC/Storage/**/*.{swift,h,m}"
    ]
    storage.resource_bundles = {"WYBasisKitObjCStorage" => [
      "#{kit_path}ObjC/Storage/PrivacyInfo.xcprivacy"
    ]}
    storage.frameworks = "Foundation", "UIKit"
    storage.dependency "WYBasisKit-swift/Storage"
    storage.dependency "WYBasisKit-ObjC/Imports"
  end

  kit.subspec "EventHandler" do |eventHandler|
    eventHandler.source_files = [
      "#{kit_path}ObjC/EventHandler/**/*.{swift,h,m}"
    ]
    eventHandler.resource_bundles = {"WYBasisKitObjCEventHandler" => [
      "#{kit_path}ObjC/EventHandler/PrivacyInfo.xcprivacy"
    ]}
    eventHandler.frameworks = "Foundation", "UIKit"
    eventHandler.dependency "WYBasisKit-swift/EventHandler"
    eventHandler.dependency "WYBasisKit-ObjC/Imports"
  end

  kit.subspec "AudioKit" do |audioKit|
    audioKit.source_files = [
      "#{kit_path}ObjC/AudioKit/**/*.{swift,h,m}"
    ] 
    audioKit.resource_bundles = {"WYBasisKitObjCAudioKit" => [
      "#{kit_path}ObjC/AudioKit/PrivacyInfo.xcprivacy"
    ]}
    audioKit.frameworks = "Foundation", "UIKit"
    audioKit.dependency "WYBasisKit-swift/AudioKit"
    audioKit.dependency "WYBasisKit-ObjC/Imports"
  end
  
  kit.subspec "Authorization" do |authorization|
    authorization.resource_bundles = {"WYBasisKitObjCAuthorization" => [
      "#{kit_path}ObjC/Authorization/PrivacyInfo.xcprivacy"
    ]}
    authorization.subspec "Camera" do |camera|
      camera.source_files = [
        "#{kit_path}ObjC/Authorization/Camera/**/*.{swift,h,m}"
      ]
      camera.resource_bundles = {"WYBasisKitObjCAuthorizationCamera" => [
        "#{kit_path}ObjC/Authorization/Camera/PrivacyInfo.xcprivacy"
      ]}
      camera.frameworks = "Foundation", "UIKit"
      camera.dependency "WYBasisKit-swift/Authorization/Camera"
      camera.dependency "WYBasisKit-ObjC/Localizable"
      camera.dependency "WYBasisKit-ObjC/LogManager"
      camera.dependency "WYBasisKit-ObjC/Imports"
    end
    
    authorization.subspec "Biometric" do |biometric|
      biometric.source_files = [
        "#{kit_path}ObjC/Authorization/Biometric/**/*.{swift,h,m}"
      ]
      biometric.resource_bundles = {"WYBasisKitObjCAuthorizationBiometric" => [
        "#{kit_path}ObjC/Authorization/Biometric/PrivacyInfo.xcprivacy"
      ]}
      biometric.frameworks = "Foundation", "UIKit"
      biometric.dependency "WYBasisKit-swift/Authorization/Biometric"
      biometric.dependency "WYBasisKit-ObjC/Localizable"
      biometric.dependency "WYBasisKit-ObjC/LogManager"
      biometric.dependency "WYBasisKit-ObjC/Imports"
    end
    
    authorization.subspec "Contacts" do |contacts|
      contacts.source_files = [
        "#{kit_path}ObjC/Authorization/Contacts/**/*.{swift,h,m}"
      ]
      contacts.resource_bundles = {"WYBasisKitObjCAuthorizationContacts" => [
        "#{kit_path}ObjC/Authorization/Contacts/PrivacyInfo.xcprivacy"
      ]}
      contacts.frameworks = "Contacts", "UIKit"
      contacts.dependency "WYBasisKit-swift/Authorization/Contacts"
      contacts.dependency "WYBasisKit-ObjC/Localizable"
      contacts.dependency "WYBasisKit-ObjC/LogManager"
      contacts.dependency "WYBasisKit-ObjC/Imports"
    end
    
    authorization.subspec "PhotoAlbums" do |photoAlbums|
      photoAlbums.source_files = [
        "#{kit_path}ObjC/Authorization/PhotoAlbums/**/*.{swift,h,m}"
      ]
      photoAlbums.resource_bundles = {"WYBasisKitObjCAuthorizationPhotoAlbums" => [
        "#{kit_path}ObjC/Authorization/PhotoAlbums/PrivacyInfo.xcprivacy"
      ]}
      photoAlbums.frameworks = "Foundation", "UIKit"
      photoAlbums.dependency "WYBasisKit-swift/Authorization/PhotoAlbums"
      photoAlbums.dependency "WYBasisKit-ObjC/Localizable"
      photoAlbums.dependency "WYBasisKit-ObjC/LogManager"
      photoAlbums.dependency "WYBasisKit-ObjC/Imports"
    end
    
    authorization.subspec "Microphone" do |microphone|
      microphone.source_files = [
        "#{kit_path}ObjC/Authorization/Microphone/**/*.{swift,h,m}"
      ]
      microphone.resource_bundles = {"WYBasisKitObjCAuthorizationMicrophone" => [
        "#{kit_path}ObjC/Authorization/Microphone/PrivacyInfo.xcprivacy"
      ]}
      microphone.frameworks = "Foundation", "UIKit"
      microphone.dependency "WYBasisKit-swift/Authorization/Microphone"
      microphone.dependency "WYBasisKit-ObjC/Localizable"
      microphone.dependency "WYBasisKit-ObjC/LogManager"
      microphone.dependency "WYBasisKit-ObjC/Imports"
    end
    
    authorization.subspec "SpeechRecognition" do |speechRecognition|
      speechRecognition.source_files = [
        "#{kit_path}ObjC/Authorization/SpeechRecognition/**/*.{swift,h,m}"
      ]
      speechRecognition.resource_bundles = {"WYBasisKitObjCAuthorizationSpeechRecognition" => [
        "#{kit_path}ObjC/Authorization/SpeechRecognition/PrivacyInfo.xcprivacy"
      ]}
      speechRecognition.frameworks = "Foundation", "UIKit"
      speechRecognition.dependency "WYBasisKit-swift/Authorization/SpeechRecognition"
      speechRecognition.dependency "WYBasisKit-ObjC/Localizable"
      speechRecognition.dependency "WYBasisKit-ObjC/LogManager"
      speechRecognition.dependency "WYBasisKit-ObjC/Imports"
    end
  end
  
  kit.subspec "Layout" do |layout|
    layout.resource_bundles = {"WYBasisKitObjCLayout" => [
      "#{kit_path}ObjC/Layout/PrivacyInfo.xcprivacy"
    ]}
    layout.subspec "ScrollText" do |scrollText|
      scrollText.source_files = [
        "#{kit_path}ObjC/Layout/ScrollText/**/*.{swift,h,m}"
      ]
      scrollText.resource_bundles = {"WYBasisKitObjCLayoutScrollText" => [
        "#{kit_path}ObjC/Layout/ScrollText/PrivacyInfo.xcprivacy"
      ]}
      scrollText.frameworks = "Foundation", "UIKit"
      scrollText.dependency "WYBasisKit-swift/Layout/ScrollText"
      scrollText.dependency "WYBasisKit-ObjC/Localizable"
      scrollText.dependency "WYBasisKit-ObjC/LogManager"
      scrollText.dependency "WYBasisKit-ObjC/Imports"
    end
    
    layout.subspec "PagingView" do |pagingView|
      pagingView.source_files = [
        "#{kit_path}ObjC/Layout/PagingView/**/*.{swift,h,m}",
        "#{kit_path}ObjC/Extension/UIButton/**/*.{swift,h,m}"
      ]
      pagingView.resource_bundles = {"WYBasisKitObjCLayoutPagingView" => [
        "#{kit_path}ObjC/Layout/PagingView/PrivacyInfo.xcprivacy"
      ]}
      pagingView.frameworks = "Foundation", "UIKit"
      pagingView.dependency "WYBasisKit-swift/Layout/PagingView"
      pagingView.dependency "WYBasisKit-ObjC/LogManager"
      pagingView.dependency "WYBasisKit-ObjC/Imports"
    end
    
    layout.subspec "BannerView" do |bannerView|
      bannerView.source_files = [
        "#{kit_path}ObjC/Layout/BannerView/**/*.{swift,h,m}"
      ]
      bannerView.resource_bundles = {"WYBasisKitObjCLayoutBannerView" => [
        "#{kit_path}ObjC/Layout/BannerView/PrivacyInfo.xcprivacy"
      ]}
      bannerView.frameworks = "Foundation", "UIKit"
      bannerView.dependency "WYBasisKit-swift/Layout/BannerView"
      bannerView.dependency "WYBasisKit-ObjC/Localizable"
      bannerView.dependency "WYBasisKit-ObjC/LogManager"
      bannerView.dependency "WYBasisKit-ObjC/Imports"
    end
    
    # layout.subspec "ChatView" do |chatView|
    #   chatView.source_files = [
    #     "#{kit_path}ObjC/Layout/ChatView/**/*.{swift,h,m}"
    #   ]
    #   chatView.resource_bundles = {"WYBasisKitObjCLayoutChatView" => [
    #      "#{kit_path}ObjC/Layout/ChatView/PrivacyInfo.xcprivacy"
    #   ]}
    #   chatView.frameworks = "Foundation", "UIKit"
    #   chatView.dependency "WYBasisKit-swift/Layout/ChatView"
    #   chatView.dependency "WYBasisKit-ObjC/Extension"
    #   chatView.dependency "WYBasisKit-ObjC/Imports"
    # end

    layout.subspec "MediaPlayer" do |mediaPlayer|
      mediaPlayer.source_files = [
        "#{kit_path}ObjC/Layout/MediaPlayer/**/*.{swift,h,m}"
      ]
      mediaPlayer.resource_bundles = {"WYBasisKitObjCMediaPlayerFS" => [
      "#{kit_path}ObjC/Layout/MediaPlayer/PrivacyInfo.xcprivacy"
      ]}
      mediaPlayer.dependency "WYBasisKit-swift/Layout/MediaPlayer"
      mediaPlayer.dependency "WYBasisKit-ObjC/Imports"
    end
  end
end
