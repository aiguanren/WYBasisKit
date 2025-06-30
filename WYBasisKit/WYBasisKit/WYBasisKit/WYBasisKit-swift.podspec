Pod::Spec.new do |kit|
  
  kit.name         = 'WYBasisKit-swift'
  kit.version      = '2.0.0'
  kit.summary      = 'WYBasisKit 不仅可以帮助开发者快速构建一个工程，还有基于常用网络框架和系统API而封装的各种实用方法、扩展，开发者只需简单的调用API就可以快速实现相应功能， 大幅提高开发效率。'
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
  
  kit.homepage     = 'https://github.com/aiguanren/WYBasisKit-swift'
  kit.license      = { :type => 'MIT', :file => 'License.md' }
  kit.author             = { '官人' => 'aiguanren@icloud.com' }
  kit.ios.deployment_target = '13.0'
  kit.source       = { :git => 'https://github.com/aiguanren/WYBasisKit-swift.git', :tag => "#{kit.version}" }
  #kit.source       = { :svn => "http://192.168.xxx.xxx:xxxx/xxx/xxx/WYBasiskit"}
  #kit.source       = { :http => 'http://192.168.xxx.xxx:xxxx/xxx/xxx/WYBasiskit.zip' }
  kit.resource_bundles = {'WYBasisKit' => ['PrivacyInfo.xcprivacy']}
  kit.swift_versions = '5.0'
  kit.requires_arc = true
  kit.module_name  = 'WYBasisKit'  # 手动指定模块名
  #指定默认模块，不指定则表示全部模块
  kit.default_subspecs = [
    'Config',
    'Localizable',
    'Extension',
    'Networking',
    'Activity',
    'Storage',
    'Codable',
    'EventHandler',
  ]
  
  # 下载并解压 WYMediaPlayerFramework，两个路径是分别对应本地验证和远程验证时WYMediaPlayerFramework.sh脚本的路径(远程验证时路径是从WYBasisKit-swift开始的)
  kit.prepare_command = <<-CMD
    bash MediaPlayer/WYMediaPlayerFramework.sh || bash WYBasisKit/WYBasisKit/WYBasisKit/MediaPlayer/WYMediaPlayerFramework.sh  
  CMD
  kit.preserve_paths = [
    'MediaPlayer/WYMediaPlayerFramework.sh',
    'WYBasisKit/WYBasisKit/WYBasisKit/MediaPlayer/WYMediaPlayerFramework.sh'
  ]
  
  kit.subspec 'Config' do |config|
    config.source_files = 'Config/**/*.{swift,h,m}'
    config.resource_bundles = {'WYBasisKitConfig' => ['Config/PrivacyInfo.xcprivacy']}
    config.frameworks = 'Foundation', 'UIKit'
  end
  
  kit.subspec 'Localizable' do |localizable|
    localizable.source_files = 'Localizable/WYLocalizableManager.swift'
    localizable.resource_bundles = {'WYBasisKitLocalizable' => ['Localizable/PrivacyInfo.xcprivacy']}
    localizable.frameworks = 'Foundation', 'UIKit'
    localizable.dependency 'WYBasisKit-swift/Config'
  end
  
  kit.subspec 'Extension' do |extension|
    extension.source_files = 'Extension/**/*.{swift,h,m}'
    extension.resource = 'Localizable/WYLocalizable.bundle'
    extension.resource_bundles = {'WYBasisKitExtension' => ['Extension/PrivacyInfo.xcprivacy']}
    extension.frameworks = 'Foundation', 'UIKit', 'LocalAuthentication', 'Photos', 'CoreFoundation'
    extension.dependency 'WYBasisKit-swift/Localizable'
    extension.dependency 'WYBasisKit-swift/Config'
  end
  
  kit.subspec 'Codable' do |codable|
    codable.source_files = 'Codable/**/*.{swift,h,m}'
    codable.resource_bundles = {'WYBasisKitCodable' => ['Codable/PrivacyInfo.xcprivacy']}
    codable.frameworks = 'Foundation', 'UIKit'
  end
  
  kit.subspec 'Networking' do |networking|
    networking.source_files = 'Networking/**/*.{swift,h,m}', 'Extension/UIAlertController/**/*.{swift,h,m}'
    networking.resource = 'Localizable/WYLocalizable.bundle'
    networking.resource_bundles = {'WYBasisKitNetworking' => ['Networking/PrivacyInfo.xcprivacy']}
    networking.frameworks = 'Foundation', 'UIKit'
    networking.dependency 'WYBasisKit-swift/Localizable'
    networking.dependency 'WYBasisKit-swift/Storage'
    networking.dependency 'WYBasisKit-swift/Codable'
    networking.dependency 'Moya'
  end
  
  kit.subspec 'Activity' do |activity|
    activity.source_files = 'Activity/**/*.{swift,h,m}', 'Extension/UIView/UIView.swift', 'Extension/UIViewController/UIViewController.swift', 'Extension/NSAttributedString/NSAttributedString.swift', 'Extension/String/String.swift', 'Extension/UIImage/UIImage.swift', 'Config/WYBasisKitConfig.swift'
    activity.resource = 'Activity/WYActivity.bundle', 'Localizable/WYLocalizable.bundle'
    activity.resource_bundles = {'WYBasisKitActivity' => ['Activity/PrivacyInfo.xcprivacy']}
    activity.frameworks = 'Foundation', 'UIKit'
    activity.dependency 'WYBasisKit-swift/Localizable'
  end
  
  kit.subspec 'Storage' do |storage|
    storage.source_files = 'Storage/**/*.{swift,h,m}'
    storage.resource_bundles = {'WYBasisKitStorage' => ['Storage/PrivacyInfo.xcprivacy']}
    storage.frameworks = 'Foundation', 'UIKit'
  end

  kit.subspec 'EventHandler' do |eventHandler|
    eventHandler.source_files = 'EventHandler/**/*.{swift,h,m}'
    eventHandler.resource_bundles = {'WYBasisKitEventHandler' => ['EventHandler/PrivacyInfo.xcprivacy']}
    eventHandler.frameworks = 'Foundation'
  end
  
  kit.subspec 'Authorization' do |authorization|
    authorization.resource_bundles = {'WYBasisKitAuthorization' => ['Authorization/PrivacyInfo.xcprivacy']}
    authorization.subspec 'Camera' do |camera|
      camera.source_files = 'Authorization/Camera/**/*.{swift,h,m}', 'Extension/UIAlertController/**/*.{swift,h,m}'
      camera.resource = 'Localizable/WYLocalizable.bundle'
      camera.resource_bundles = {'WYBasisKitAuthorizationCamera' => ['Authorization/Camera/PrivacyInfo.xcprivacy']}
      camera.frameworks = 'AVFoundation', 'UIKit', 'Photos'
      camera.dependency 'WYBasisKit-swift/Localizable'
    end
    
    authorization.subspec 'Biometric' do |biometric|
      biometric.source_files = 'Authorization/Biometric/**/*.{swift,h,m}'
      biometric.resource = 'Localizable/WYLocalizable.bundle'
      biometric.resource_bundles = {'WYBasisKitAuthorizationBiometric' => ['Authorization/Biometric/PrivacyInfo.xcprivacy']}
      biometric.frameworks = 'Foundation', 'LocalAuthentication'
      biometric.dependency 'WYBasisKit-swift/Localizable'
    end
    
    authorization.subspec 'Contacts' do |contacts|
      contacts.source_files = 'Authorization/Contacts/**/*.{swift,h,m}', 'Extension/UIAlertController/**/*.{swift,h,m}'
      contacts.resource = 'Localizable/WYLocalizable.bundle'
      contacts.resource_bundles = {'WYBasisKitAuthorizationContacts' => ['Authorization/Contacts/PrivacyInfo.xcprivacy']}
      contacts.frameworks = 'Contacts', 'UIKit'
      contacts.dependency 'WYBasisKit-swift/Localizable'
    end
    
    authorization.subspec 'PhotoAlbums' do |photoAlbums|
      photoAlbums.source_files = 'Authorization/PhotoAlbums/**/*.{swift,h,m}', 'Extension/UIAlertController/**/*.{swift,h,m}'
      photoAlbums.resource = 'Localizable/WYLocalizable.bundle'
      photoAlbums.resource_bundles = {'WYBasisKitAuthorizationPhotoAlbums' => ['Authorization/PhotoAlbums/PrivacyInfo.xcprivacy']}
      photoAlbums.frameworks = 'Photos', 'UIKit'
      photoAlbums.dependency 'WYBasisKit-swift/Localizable'
    end
    
    authorization.subspec 'Microphone' do |microphone|
      microphone.source_files = 'Authorization/Microphone/**/*.{swift,h,m}', 'Extension/UIAlertController/**/*.{swift,h,m}'
      microphone.resource = 'Localizable/WYLocalizable.bundle'
      microphone.resource_bundles = {'WYBasisKitAuthorizationMicrophone' => ['Authorization/Microphone/PrivacyInfo.xcprivacy']}
      microphone.frameworks = 'Photos', 'UIKit'
      microphone.dependency 'WYBasisKit-swift/Localizable'
    end
    
    authorization.subspec 'SpeechRecognition' do |speechRecognition|
      speechRecognition.source_files = 'Authorization/SpeechRecognition/**/*.{swift,h,m}', 'Extension/UIAlertController/**/*.{swift,h,m}'
      speechRecognition.resource = 'Localizable/WYLocalizable.bundle'
      speechRecognition.resource_bundles = {'WYBasisKitAuthorizationSpeechRecognition' => ['Authorization/SpeechRecognition/PrivacyInfo.xcprivacy']}
      speechRecognition.frameworks = 'Speech', 'UIKit'
      speechRecognition.dependency 'WYBasisKit-swift/Localizable'
    end
  end
  
  kit.subspec 'Layout' do |layout|
    layout.resource_bundles = {'WYBasisKitLayout' => ['Layout/PrivacyInfo.xcprivacy']}
    layout.subspec 'ScrollText' do |scrollText|
      scrollText.source_files = 'Layout/ScrollText/**/*.{swift,h,m}', 'Config/WYBasisKitConfig.swift'
      scrollText.resource = 'Localizable/WYLocalizable.bundle'
      scrollText.resource_bundles = {'WYBasisKitLayoutScrollText' => ['Layout/ScrollText/PrivacyInfo.xcprivacy']}
      scrollText.frameworks = 'Foundation', 'UIKit'
      scrollText.dependency 'WYBasisKit-swift/Localizable'
      scrollText.dependency 'SnapKit'
    end
    
    layout.subspec 'PagingView' do |pagingView|
      pagingView.source_files = 'Layout/PagingView/**/*.{swift,h,m}', 'Extension/UIView/**/*.{swift,h,m}', 'Extension/UIButton/**/*.{swift,h,m}', 'Extension/UIColor/**/*.{swift,h,m}', 'Extension/UIImage/**/*.{swift,h,m}', 'Config/WYBasisKitConfig.swift'
      pagingView.resource_bundles = {'WYBasisKitLayoutPagingView' => ['Layout/PagingView/PrivacyInfo.xcprivacy']}
      pagingView.frameworks = 'Foundation', 'UIKit'
      pagingView.dependency 'SnapKit'
    end
    
    layout.subspec 'BannerView' do |bannerView|
      bannerView.source_files = 'Layout/BannerView/WYBannerView.swift', 'Extension/UIView/**/*.{swift,h,m}', 'Config/WYBasisKitConfig.swift'
      bannerView.resource = 'Layout/BannerView/WYBannerView.bundle', 'Localizable/WYLocalizable.bundle'
      bannerView.resource_bundles = {'WYBasisKitLayoutBannerView' => ['Layout/BannerView/PrivacyInfo.xcprivacy']}
      bannerView.frameworks = 'Foundation', 'UIKit'
      bannerView.dependency 'WYBasisKit-swift/Localizable'
      bannerView.dependency 'Kingfisher'
    end
    
     # layout.subspec 'ChatView' do |chatView|
     #   chatView.source_files = 'Layout/ChatView/AudioManager/**/*.{swift,h,m}', 'Layout/ChatView/Config/**/*.{swift,h,m}', 'Layout/ChatView/Models/**/*.{swift,h,m}', 'Layout/ChatView/RecordAnimation/**/*.{swift,h,m}', 'Layout/ChatView/Views/**/*.{swift,h,m}'
     #   chatView.resource = 'Layout/ChatView/WYChatView.bundle'
     #   chatView.resource_bundles = {'WYBasisKitLayoutChatView' => ['Layout/ChatView/PrivacyInfo.xcprivacy']}
     #   chatView.frameworks = 'Foundation', 'UIKit'
     #   chatView.dependency 'WYBasisKit-swift/Extension'
     #   chatView.dependency 'WYBasisKit-swift/Localizable'
     #   chatView.dependency 'SnapKit'
     #   chatView.dependency 'Kingfisher'
     # end
  end

  kit.subspec 'IJKFrameworkFull' do |framework|  # IJKMediaPlayerFramework (真机+模拟器)
    framework.preserve_paths = 'MediaPlayer/WYMediaPlayerFramework.sh'
    framework.resource_bundles = {'WYBasisKitIJKFrameworkFull' => ['MediaPlayer/PrivacyInfo.xcprivacy']}
    framework.libraries = 'c++', 'z', 'bz2'  # 这里需要忽略前面的lib和后面的tbd，例如libz.tbd直接写为z即可，如果是.a则需要写全，如：'xxx.a'
    framework.frameworks = 'UIKit', 'AudioToolbox', 'CoreGraphics', 'AVFoundation', 'CoreMedia', 'CoreVideo', 'MediaPlayer', 'CoreServices', 'Metal', 'QuartzCore', 'VideoToolbox'
    # framework.vendored_libraries = 'xxx.a'
    framework.vendored_frameworks = 'MediaPlayer/WYMediaPlayerFramework/arm64&x86_64/IJKMediaPlayer.xcframework'
    framework.pod_target_xcconfig = {
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', # 过滤模拟器arm64，解决M系列芯片MAC上模拟器架构问题
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) WYMediaPlayer_SUPPORTS_SIMULATOR=1',
    }
  end

  kit.subspec 'IJKFrameworkLite' do |framework|  # IJKMediaPlayerFramework (仅真机)
    framework.preserve_paths = 'MediaPlayer/WYMediaPlayerFramework.sh'
    framework.resource_bundles = {'WYBasisKitIJKFrameworkLite' => ['MediaPlayer/PrivacyInfo.xcprivacy']}
    framework.libraries = 'c++', 'z', 'bz2'  # 这里需要忽略前面的lib和后面的tbd，例如libz.tbd直接写为z即可，如果是.a则需要写全，如：'xxx.a'
    framework.frameworks = 'UIKit', 'AudioToolbox', 'CoreGraphics', 'AVFoundation', 'CoreMedia', 'CoreVideo', 'MediaPlayer', 'CoreServices', 'Metal', 'QuartzCore', 'VideoToolbox'
    # framework.vendored_libraries = 'xxx.a'
    framework.vendored_frameworks = 'MediaPlayer/WYMediaPlayerFramework/arm64/IJKMediaPlayer.xcframework'
    framework.pod_target_xcconfig = {
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', # 过滤模拟器arm64，解决，解决M系列芯片MAC上模拟器架构问题
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) WYMediaPlayer_SUPPORTS_SIMULATOR=0',
      # 模拟器环境下清空IJKMediaPlayer.xcframework相关的链接，避免链接导致的验证不通过与编译错误
      'OTHER_LDFLAGS[sdk=iphonesimulator*]' => '',
      'LD_RUNPATH_SEARCH_PATHS[sdk=iphonesimulator*]' => '',
      # 模拟器环境下清空IJKMediaPlayer.xcframework相关的链接，避免链接导致的验证不通过与编译错误
    }
  end
  
  kit.subspec 'MediaPlayerFull' do |mediaPlayer|
    mediaPlayer.source_files = 'MediaPlayer/**/*.{swift,h,m}'
    mediaPlayer.exclude_files = 'MediaPlayer/WYMediaPlayerFramework/**/*'  # 排除匹配WYMediaPlayerFramework下面的.{swift,h,m}文件
    mediaPlayer.resource_bundles = {'WYBasisKitMediaPlayerFull' => ['MediaPlayer/PrivacyInfo.xcprivacy']}
    mediaPlayer.dependency 'SnapKit'
    mediaPlayer.dependency 'Kingfisher'
    mediaPlayer.dependency 'WYBasisKit-swift/IJKFrameworkFull'
  end

  kit.subspec 'MediaPlayerLite' do |mediaPlayer|
    mediaPlayer.source_files = 'MediaPlayer/**/*.{swift,h,m}'
    mediaPlayer.exclude_files = 'MediaPlayer/WYMediaPlayerFramework/**/*'  # 排除匹配WYMediaPlayerFramework下面的.{swift,h,m}文件
    mediaPlayer.resource_bundles = {'WYBasisKitMediaPlayerLite' => ['MediaPlayer/PrivacyInfo.xcprivacy']}
    mediaPlayer.dependency 'SnapKit'
    mediaPlayer.dependency 'Kingfisher'
    mediaPlayer.dependency 'WYBasisKit-swift/IJKFrameworkLite'
  end
end
