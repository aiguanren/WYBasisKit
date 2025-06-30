SDKPath = "WYBasisKit/WYBasisKit/WYBasisKit/"  # 定义podspec执行路径(远程验证时路径是从WYBasisKit-swift开始的)
Pod::Spec.new do |kit|
  
  kit.name         = "WYBasisKit-swift"
  kit.version      = "2.0.0"
  kit.summary      = "WYBasisKit 不仅可以帮助开发者快速构建一个工程，还有基于常用网络框架和系统API而封装的各种实用方法、扩展，开发者只需简单的调用API就可以快速实现相应功能， 大幅提高开发效率。"
  kit.description  = <<-DESC
    Localizable: 国际化解决方案
    Extension: 各种系统扩展
    Networking: 网络请求解决方案
    Activity: 活动指示器
    Storage: 本地存储
    Layout: 各种自定义控件
    MediaPlayer: 直播、视频播放器
    Codable: 数据解析
    Authorization: 各种权限请求与判断
  DESC
  
  kit.homepage     = "https://github.com/aiguanren/WYBasisKit-swift"
  kit.license      = { :type => "MIT", :file => "License.md" }
  kit.author             = { "官人" => "aiguanren@icloud.com" }
  kit.ios.deployment_target = "13.0"
  kit.source       = { :git => "https://github.com/aiguanren/WYBasisKit-swift.git", :tag => "#{kit.version}" }
  #kit.source       = { :svn => "http://192.168.xxx.xxx:xxxx/xxx/xxx/WYBasiskit"}
  #kit.source       = { :http => "http://192.168.xxx.xxx:xxxx/xxx/xxx/WYBasiskit.zip" }
  kit.resource_bundles = {"WYBasisKit" => ["{"", #{SDKPath}""}PrivacyInfo.xcprivacy"]}
  kit.swift_versions = "5.0"
  kit.requires_arc = true
  kit.module_name  = "WYBasisKit"  # 手动指定模块名
  #指定默认模块，不指定则表示全部模块
  kit.default_subspecs = [
    "Config",
    "Localizable",
    "Extension",
    "Networking",
    "Activity",
    "Storage",
    "Codable",
    "EventHandler",
  ]
  
  # 下载并解压 WYMediaPlayerFramework
  kit.prepare_command = <<-CMD
    # 优先尝试相对路径
    if [ -f "MediaPlayer/WYMediaPlayerFramework.sh" ]; then
      bash MediaPlayer/WYMediaPlayerFramework.sh
    elif [ -f "#{SDKPath}MediaPlayer/WYMediaPlayerFramework.sh" ]; then
      bash #{SDKPath}MediaPlayer/WYMediaPlayerFramework.sh
    else
      echo "⚠️ 未能找到脚本：WYMediaPlayerFramework.sh" >&2
      exit 1
    fi
  CMD
  # 将脚本和podspec关联
  kit.preserve_paths = [
    "MediaPlayer/WYMediaPlayerFramework.sh",
    "#{SDKPath}MediaPlayer/WYMediaPlayerFramework.sh"
  ]

  kit.subspec "Config" do |config|
    config.source_files = ["{Config, #{SDKPath}Config}/**/*.{swift,h,m}"]
    config.resource_bundles = {"WYBasisKitConfig" => ["{Config, #{SDKPath}Config}/PrivacyInfo.xcprivacy"]}
    config.frameworks = "Foundation", "UIKit"
  end
  
  kit.subspec "Localizable" do |localizable|
    localizable.source_files = ["{Localizable, #{SDKPath}Localizable}/WYLocalizableManager.swift"]
    localizable.resource_bundles = {"WYBasisKitLocalizable" => ["{Localizable, #{SDKPath}Localizable}/PrivacyInfo.xcprivacy"]}
    localizable.frameworks = "Foundation", "UIKit"
    localizable.dependency "WYBasisKit-swift/Config"
  end
  
  kit.subspec "Extension" do |extension|
    extension.source_files = ["{Extension, #{SDKPath}Extension}/**/*.{swift,h,m}"]
    extension.resources = ["{Localizable, #{SDKPath}Localizable}/WYLocalizable.bundle"]
    extension.resource_bundles = {"WYBasisKitExtension" => ["{Extension, #{SDKPath}Extension}/PrivacyInfo.xcprivacy"]}
    extension.frameworks = "Foundation", "UIKit", "LocalAuthentication", "Photos", "CoreFoundation"
    extension.dependency "WYBasisKit-swift/Localizable"
    extension.dependency "WYBasisKit-swift/Config"
  end
  
  kit.subspec "Codable" do |codable|
    codable.source_files = ["{Codable, #{SDKPath}Codable}/**/*.{swift,h,m}"]
    codable.resource_bundles = {"WYBasisKitCodable" => ["{Codable, #{SDKPath}Codable}/PrivacyInfo.xcprivacy"]}
    codable.frameworks = "Foundation", "UIKit"
  end
  
  kit.subspec "Networking" do |networking|
    networking.source_files = ["{Networking, #{SDKPath}Networking}/**/*.{swift,h,m}", 
                               "{Extension, #{SDKPath}Extension}/UIAlertController/**/*.{swift,h,m}"]
    networking.resources = ["{Localizable, #{SDKPath}Localizable}/WYLocalizable.bundle"]
    networking.resource_bundles = {"WYBasisKitNetworking" => ["{Networking, #{SDKPath}Networking}/PrivacyInfo.xcprivacy"]}
    networking.frameworks = "Foundation", "UIKit"
    networking.dependency "WYBasisKit-swift/Localizable"
    networking.dependency "WYBasisKit-swift/Storage"
    networking.dependency "WYBasisKit-swift/Codable"
    networking.dependency "Moya"
  end
  
  kit.subspec "Activity" do |activity|
    activity.source_files = ["{Activity, #{SDKPath}Activity}/**/*.{swift,h,m}", 
                             "{Extension, #{SDKPath}Extension}/UIView/UIView.swift", 
                             "{Extension, #{SDKPath}Extension}/UIViewController/UIViewController.swift", 
                             "{Extension, #{SDKPath}Extension}/NSAttributedString/NSAttributedString.swift", 
                             "{Extension, #{SDKPath}Extension}/String/String.swift", 
                             "{Extension, #{SDKPath}Extension}/UIImage/UIImage.swift", 
                             "{Config, #{SDKPath}Config}/WYBasisKitConfig.swift"]
    activity.resources = ["{Activity, #{SDKPath}Activity}/WYActivity.bundle", 
                          "{Localizable, #{SDKPath}Localizable}/WYLocalizable.bundle"]
    activity.resource_bundles = {"WYBasisKitActivity" => ["{Activity, #{SDKPath}Activity}/PrivacyInfo.xcprivacy"]}
    activity.frameworks = "Foundation", "UIKit"
    activity.dependency "WYBasisKit-swift/Localizable"
  end
  
  kit.subspec "Storage" do |storage|
    storage.source_files = ["{Storage, #{SDKPath}Storage}/**/*.{swift,h,m}"]
    storage.resource_bundles = {"WYBasisKitStorage" => ["{Storage, #{SDKPath}Storage}/PrivacyInfo.xcprivacy"]}
    storage.frameworks = "Foundation", "UIKit"
  end

  kit.subspec "EventHandler" do |eventHandler|
    eventHandler.source_files = ["{EventHandler, #{SDKPath}EventHandler}/**/*.{swift,h,m}"]
    eventHandler.resource_bundles = {"WYBasisKitEventHandler" => ["{EventHandler, #{SDKPath}EventHandler}/PrivacyInfo.xcprivacy"]}
    eventHandler.frameworks = "Foundation"
  end
  
  kit.subspec "Authorization" do |authorization|
    authorization.resource_bundles = {"WYBasisKitAuthorization" => ["{Authorization, #{SDKPath}Authorization}/PrivacyInfo.xcprivacy"]}
    authorization.subspec "Camera" do |camera|
      camera.source_files = ["{Authorization, #{SDKPath}Authorization}/Camera/**/*.{swift,h,m}", 
                             "{Extension, #{SDKPath}Extension}/UIAlertController/**/*.{swift,h,m}"]
      camera.resources = ["{Localizable, #{SDKPath}Localizable}/WYLocalizable.bundle"]
      camera.resource_bundles = {"WYBasisKitAuthorizationCamera" => ["{Authorization, #{SDKPath}Authorization}/Camera/PrivacyInfo.xcprivacy"]}
      camera.frameworks = "AVFoundation", "UIKit", "Photos"
      camera.dependency "WYBasisKit-swift/Localizable"
    end
    
    authorization.subspec "Biometric" do |biometric|
      biometric.source_files = ["{Authorization, #{SDKPath}Authorization}/Biometric/**/*.{swift,h,m}"]
      biometric.resources = ["{Localizable, #{SDKPath}Localizable}/WYLocalizable.bundle"]
      biometric.resource_bundles = {"WYBasisKitAuthorizationBiometric" => ["{Authorization, #{SDKPath}Authorization}/Biometric/PrivacyInfo.xcprivacy"]}
      biometric.frameworks = "Foundation", "LocalAuthentication"
      biometric.dependency "WYBasisKit-swift/Localizable"
    end
    
    authorization.subspec "Contacts" do |contacts|
      contacts.source_files = ["{Authorization, #{SDKPath}Authorization}/Contacts/**/*.{swift,h,m}", 
                               "{Extension, #{SDKPath}Extension}/UIAlertController/**/*.{swift,h,m}"]
      contacts.resources = ["{Localizable, #{SDKPath}Localizable}/WYLocalizable.bundle"]
      contacts.resource_bundles = {"WYBasisKitAuthorizationContacts" => ["{Authorization, #{SDKPath}Authorization}/Contacts/PrivacyInfo.xcprivacy"]}
      contacts.frameworks = "Contacts", "UIKit"
      contacts.dependency "WYBasisKit-swift/Localizable"
    end
    
    authorization.subspec "PhotoAlbums" do |photoAlbums|
      photoAlbums.source_files = ["{Authorization, #{SDKPath}Authorization}/PhotoAlbums/**/*.{swift,h,m}", 
                                  "{Extension, #{SDKPath}Extension}/UIAlertController/**/*.{swift,h,m}"]
      photoAlbums.resources = ["{Localizable, #{SDKPath}Localizable}/WYLocalizable.bundle"]
      photoAlbums.resource_bundles = {"WYBasisKitAuthorizationPhotoAlbums" => ["{Authorization, #{SDKPath}Authorization}/PhotoAlbums/PrivacyInfo.xcprivacy"]}
      photoAlbums.frameworks = "Photos", "UIKit"
      photoAlbums.dependency "WYBasisKit-swift/Localizable"
    end
    
    authorization.subspec "Microphone" do |microphone|
      microphone.source_files = ["{Authorization, #{SDKPath}Authorization}/Microphone/**/*.{swift,h,m}", 
                                 "{Extension, #{SDKPath}Extension}/UIAlertController/**/*.{swift,h,m}"]
      microphone.resources = ["{Localizable, #{SDKPath}Localizable}/WYLocalizable.bundle"]
      microphone.resource_bundles = {"WYBasisKitAuthorizationMicrophone" => ["{Authorization, #{SDKPath}Authorization}/Microphone/PrivacyInfo.xcprivacy"]}
      microphone.frameworks = "Photos", "UIKit"
      microphone.dependency "WYBasisKit-swift/Localizable"
    end
    
    authorization.subspec "SpeechRecognition" do |speechRecognition|
      speechRecognition.source_files = ["{Authorization, #{SDKPath}Authorization}/SpeechRecognition/**/*.{swift,h,m}",
                                        "{Extension, #{SDKPath}Extension}/UIAlertController/**/*.{swift,h,m}"]
      speechRecognition.resources = ["{Localizable, #{SDKPath}Localizable}/WYLocalizable.bundle"]
      speechRecognition.resource_bundles = {"WYBasisKitAuthorizationSpeechRecognition" => ["{Authorization, #{SDKPath}Authorization}/SpeechRecognition/PrivacyInfo.xcprivacy"]}
      speechRecognition.frameworks = "Speech", "UIKit"
      speechRecognition.dependency "WYBasisKit-swift/Localizable"
    end
  end
  
  kit.subspec "Layout" do |layout|
    layout.resource_bundles = {"WYBasisKitLayout" => ["{Layout, #{SDKPath}Layout}/PrivacyInfo.xcprivacy"]}
    layout.subspec "ScrollText" do |scrollText|
      scrollText.source_files = ["{Layout, #{SDKPath}Layout}/ScrollText/**/*.{swift,h,m}", 
                                 "{Config, #{SDKPath}Config}/WYBasisKitConfig.swift"]
      scrollText.resources = ["{Localizable, #{SDKPath}Localizable}/WYLocalizable.bundle"]
      scrollText.resource_bundles = {"WYBasisKitLayoutScrollText" => ["{Layout, #{SDKPath}Layout}/ScrollText/PrivacyInfo.xcprivacy"]}
      scrollText.frameworks = "Foundation", "UIKit"
      scrollText.dependency "WYBasisKit-swift/Localizable"
      scrollText.dependency "SnapKit"
    end
    
    layout.subspec "PagingView" do |pagingView|
      pagingView.source_files = ["{Layout, #{SDKPath}Layout}/PagingView/**/*.{swift,h,m}", 
                                 "{Extension, #{SDKPath}Extension}/UIView/**/*.{swift,h,m}", 
                                 "{Extension, #{SDKPath}Extension}/UIButton/**/*.{swift,h,m}", 
                                 "{Extension, #{SDKPath}Extension}/UIColor/**/*.{swift,h,m}", 
                                 "{Extension, #{SDKPath}Extension}/UIImage/**/*.{swift,h,m}", 
                                 "{Config, #{SDKPath}Config}/WYBasisKitConfig.swift"]
      pagingView.resource_bundles = {"WYBasisKitLayoutPagingView" => ["{Layout, #{SDKPath}Layout}/PagingView/PrivacyInfo.xcprivacy"]}
      pagingView.frameworks = "Foundation", "UIKit"
      pagingView.dependency "SnapKit"
    end
    
    layout.subspec "BannerView" do |bannerView|
      bannerView.source_files = ["{Layout, #{SDKPath}Layout}/BannerView/WYBannerView.swift", 
                                 "{Extension, #{SDKPath}Extension}/UIView/**/*.{swift,h,m}", 
                                 "{Config, #{SDKPath}Config}/WYBasisKitConfig.swift"]
      bannerView.resources = ["{Layout, #{SDKPath}Layout}/BannerView/WYBannerView.bundle", 
                              "{Localizable, #{SDKPath}Localizable}/WYLocalizable.bundle"]
      bannerView.resource_bundles = {"WYBasisKitLayoutBannerView" => ["{Layout, #{SDKPath}Layout}/BannerView/PrivacyInfo.xcprivacy"]}
      bannerView.frameworks = "Foundation", "UIKit"
      bannerView.dependency "WYBasisKit-swift/Localizable"
      bannerView.dependency "Kingfisher"
    end
    
     layout.subspec "ChatView" do |chatView|
       chatView.source_files = ["{Layout, #{SDKPath}Layout}/ChatView/AudioManager/**/*.{swift,h,m}", 
                                "{Layout, #{SDKPath}Layout}/ChatView/Config/**/*.{swift,h,m}", 
                                "{Layout, #{SDKPath}Layout}/ChatView/Models/**/*.{swift,h,m}", 
                                "{Layout, #{SDKPath}Layout}/ChatView/RecordAnimation/**/*.{swift,h,m}", 
                                "{Layout, #{SDKPath}Layout}/ChatView/Views/**/*.{swift,h,m}"]
       chatView.resources = ["{Layout, #{SDKPath}Layout}/ChatView/WYChatView.bundle"]
       chatView.resource_bundles = {"WYBasisKitLayoutChatView" => ["{Layout, #{SDKPath}Layout}/ChatView/PrivacyInfo.xcprivacy"]}
       chatView.frameworks = "Foundation", "UIKit"
       chatView.dependency "WYBasisKit-swift/Extension"
       chatView.dependency "WYBasisKit-swift/Localizable"
       chatView.dependency "SnapKit"
       chatView.dependency "Kingfisher"
     end
  end

  kit.subspec "IJKFrameworkFull" do |framework|  # IJKMediaPlayerFramework (真机+模拟器)
    framework.resource_bundles = {"WYBasisKitIJKFrameworkFull" => ["{MediaPlayer, #{SDKPath}MediaPlayer}/PrivacyInfo.xcprivacy"]}
    framework.libraries = "c++", "z", "bz2"  # 这里需要忽略前面的lib和后面的tbd，例如libz.tbd直接写为z即可，如果是.a则需要写全，如："xxx.a"
    framework.frameworks = "UIKit", "AudioToolbox", "CoreGraphics", "AVFoundation", "CoreMedia", "CoreVideo", "MediaPlayer", "CoreServices", "Metal", "QuartzCore", "VideoToolbox"
    # framework.vendored_libraries = "xxx.a"
    framework.vendored_frameworks = "{MediaPlayer,#{SDKPath}MediaPlayer}/WYMediaPlayerFramework/arm64&x86_64/IJKMediaPlayer.xcframework"
    framework.pod_target_xcconfig = {
      "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64", # 过滤模拟器arm64，解决M系列芯片MAC上模拟器架构问题
      "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) WYMediaPlayer_SUPPORTS_SIMULATOR=1",
    }
  end

  kit.subspec "IJKFrameworkLite" do |framework|  # IJKMediaPlayerFramework (仅真机)
    framework.resource_bundles = {"WYBasisKitIJKFrameworkLite" => ["{MediaPlayer, #{SDKPath}MediaPlayer}/PrivacyInfo.xcprivacy"]}
    framework.libraries = "c++", "z", "bz2"  # 这里需要忽略前面的lib和后面的tbd，例如libz.tbd直接写为z即可，如果是.a则需要写全，如："xxx.a"
    framework.frameworks = "UIKit", "AudioToolbox", "CoreGraphics", "AVFoundation", "CoreMedia", "CoreVideo", "MediaPlayer", "CoreServices", "Metal", "QuartzCore", "VideoToolbox"
    # framework.vendored_libraries = "xxx.a"
    framework.vendored_frameworks = "{MediaPlayer,#{SDKPath}MediaPlayer}/WYMediaPlayerFramework/arm64/IJKMediaPlayer.xcframework"
    framework.pod_target_xcconfig = {
      "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64", # 过滤模拟器arm64，解决，解决M系列芯片MAC上模拟器架构问题
      "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) WYMediaPlayer_SUPPORTS_SIMULATOR=0",
      # 模拟器环境下清空IJKMediaPlayer.xcframework相关的链接，避免链接导致的验证不通过与编译错误
      "OTHER_LDFLAGS[sdk=iphonesimulator*]" => "",
      "LD_RUNPATH_SEARCH_PATHS[sdk=iphonesimulator*]" => "",
      # 模拟器环境下清空IJKMediaPlayer.xcframework相关的链接，避免链接导致的验证不通过与编译错误
    }
  end
  
  kit.subspec "MediaPlayerFull" do |mediaPlayer|
    mediaPlayer.source_files = ["{MediaPlayer, #{SDKPath}MediaPlayer}/**/*.{swift,h,m}"]
    mediaPlayer.exclude_files = ["{MediaPlayer, #{SDKPath}MediaPlayer}/WYMediaPlayerFramework/**/*"]  # 排除匹配WYMediaPlayerFramework下面的.{swift,h,m}文件
    mediaPlayer.resource_bundles = {"WYBasisKitMediaPlayerFull" => ["{MediaPlayer, #{SDKPath}MediaPlayer}/PrivacyInfo.xcprivacy"]}
    mediaPlayer.dependency "SnapKit"
    mediaPlayer.dependency "Kingfisher"
    mediaPlayer.dependency "WYBasisKit-swift/IJKFrameworkFull"
  end

  kit.subspec "MediaPlayerLite" do |mediaPlayer|
    mediaPlayer.source_files = ["{MediaPlayer, #{SDKPath}MediaPlayer}/**/*.{swift,h,m}"]
    mediaPlayer.exclude_files = ["{MediaPlayer, #{SDKPath}MediaPlayer}/WYMediaPlayerFramework/**/*"]  # 排除匹配WYMediaPlayerFramework下面的.{swift,h,m}文件
    mediaPlayer.resource_bundles = {"WYBasisKitMediaPlayerLite" => ["{MediaPlayer, #{SDKPath}MediaPlayer}/PrivacyInfo.xcprivacy"]}
    mediaPlayer.dependency "SnapKit"
    mediaPlayer.dependency "Kingfisher"
    mediaPlayer.dependency "WYBasisKit-swift/IJKFrameworkLite"
  end
end
