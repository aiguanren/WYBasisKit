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
  kit.swift_versions = '5.0'
  kit.requires_arc = true
  #kit.module_name  = 'WYBasisKit'  手动指定模块名
  kit.default_subspecs = 'Extension'

  # 下载并解压 WYMediaPlayerFramework
  kit.prepare_command = 'bash SDK/WYBasisKit/MediaPlayer/WYMediaPlayerFramework.sh'

    kit.subspec 'Config' do |config|
       config.source_files = 'WYBasisKit/Config/**/*'
       config.frameworks = 'Foundation', 'UIKit'
    end

    kit.subspec 'Localizable' do |localizable|
       localizable.source_files = 'SDK/WYBasisKit/Localizable/WYLocalizableManager.swift'
       localizable.frameworks = 'Foundation', 'UIKit'
       localizable.dependency 'WYBasisKit-swift/Config'
    end

    kit.subspec 'Extension' do |extension|
       extension.source_files = 'SDK/WYBasisKit/Extension/**/*'
       extension.frameworks = 'Foundation', 'UIKit', 'LocalAuthentication', 'Photos', 'CoreFoundation'
       extension.resource = 'SDK/WYBasisKit/Localizable/WYLocalizable.bundle'
       extension.dependency 'WYBasisKit-swift/Localizable'
       extension.dependency 'WYBasisKit-swift/Config'
    end

    kit.subspec 'Codable' do |codable|
       codable.source_files = 'SDK/WYBasisKit/Codable/**/*'
       codable.frameworks = 'Foundation', 'UIKit'
    end
    
    kit.subspec 'Networking' do |networking|
       networking.source_files = 'SDK/WYBasisKit/Networking/**/*', 'SDK/WYBasisKit/Extension/UIAlertController/**/*'
       networking.frameworks = 'Foundation', 'UIKit'
       networking.resource = 'SDK/WYBasisKit/Localizable/WYLocalizable.bundle'
       networking.dependency 'WYBasisKit-swift/Localizable'
       networking.dependency 'WYBasisKit-swift/Storage'
       networking.dependency 'WYBasisKit-swift/Codable'
       networking.dependency 'Moya'
    end

    kit.subspec 'Activity' do |activity|
       activity.source_files = 'SDK/WYBasisKit/Activity/WYActivity.swift', 'SDK/WYBasisKit/Extension/UIView/UIView.swift', 'SDK/WYBasisKit/Extension/UIViewController/UIViewController.swift', 'SDK/WYBasisKit/Extension/NSAttributedString/NSAttributedString.swift', 'SDK/WYBasisKit/Extension/String/String.swift', 'SDK/WYBasisKit/Extension/UIImage/UIImage.swift', 'SDK/WYBasisKit/Config/WYBasisKitConfig.swift'
       activity.frameworks = 'Foundation', 'UIKit'
       activity.resource = 'SDK/WYBasisKit/Activity/WYActivity.bundle', 'SDK/WYBasisKit/Localizable/WYLocalizable.bundle'
       activity.dependency 'WYBasisKit-swift/Localizable'
    end

    kit.subspec 'Storage' do |storage|
       storage.source_files = 'SDK/WYBasisKit/Storage/**/*'
       storage.frameworks = 'Foundation', 'UIKit'
    end

    kit.subspec 'Authorization' do |authorization|
       authorization.subspec 'Camera' do |camera|
          camera.source_files = 'SDK/WYBasisKit/Authorization/Camera/**/*', 'SDK/WYBasisKit/Extension/UIAlertController/**/*'
          camera.frameworks = 'AVFoundation', 'UIKit', 'Photos'
          camera.resource = 'SDK/WYBasisKit/Localizable/WYLocalizable.bundle'
          camera.dependency 'WYBasisKit-swift/Localizable'
       end

       authorization.subspec 'Biometric' do |biometric|
          biometric.source_files = 'SDK/WYBasisKit/Authorization/Biometric/**/*'
          biometric.frameworks = 'Foundation', 'LocalAuthentication'
          biometric.resource = 'SDK/WYBasisKit/Localizable/WYLocalizable.bundle'
          biometric.dependency 'WYBasisKit-swift/Localizable'
       end

       authorization.subspec 'Contacts' do |contacts|
          contacts.source_files = 'SDK/WYBasisKit/Authorization/Contacts/**/*', 'SDK/WYBasisKit/Extension/UIAlertController/**/*'
          contacts.frameworks = 'Contacts', 'UIKit'
          contacts.resource = 'SDK/WYBasisKit/Localizable/WYLocalizable.bundle'
          contacts.dependency 'WYBasisKit-swift/Localizable'
       end

       authorization.subspec 'PhotoAlbums' do |photoAlbums|
          photoAlbums.source_files = 'SDK/WYBasisKit/Authorization/PhotoAlbums/**/*', 'SDK/WYBasisKit/Extension/UIAlertController/**/*'
          photoAlbums.frameworks = 'Photos', 'UIKit'
          photoAlbums.resource = 'SDK/WYBasisKit/Localizable/WYLocalizable.bundle'
          photoAlbums.dependency 'WYBasisKit-swift/Localizable'
       end

       authorization.subspec 'Microphone' do |microphone|
          microphone.source_files = 'SDK/WYBasisKit/Authorization/Microphone/**/*', 'SDK/WYBasisKit/Extension/UIAlertController/**/*'
          microphone.frameworks = 'Photos', 'UIKit'
          microphone.resource = 'SDK/WYBasisKit/Localizable/WYLocalizable.bundle'
          microphone.dependency 'WYBasisKit-swift/Localizable'
       end

       authorization.subspec 'SpeechRecognition' do |speechRecognition|
          speechRecognition.source_files = 'SDK/WYBasisKit/Authorization/SpeechRecognition/**/*', 'SDK/WYBasisKit/Extension/UIAlertController/**/*'
          speechRecognition.frameworks = 'Speech', 'UIKit'
          speechRecognition.resource = 'SDK/WYBasisKit/Localizable/WYLocalizable.bundle'
          speechRecognition.dependency 'WYBasisKit-swift/Localizable'
       end
    end

    kit.subspec 'Layout' do |layout|
       layout.subspec 'ScrollText' do |scrollText|
          scrollText.source_files = 'SDK/WYBasisKit/Layout/ScrollText/**/*', 'SDK/WYBasisKit/Config/WYBasisKitConfig.swift'
          scrollText.frameworks = 'Foundation', 'UIKit'
          scrollText.resource = 'SDK/WYBasisKit/Localizable/WYLocalizable.bundle'
          scrollText.dependency 'WYBasisKit-swift/Localizable'
          scrollText.dependency 'SnapKit'
       end

       layout.subspec 'PagingView' do |pagingView|
          pagingView.source_files = 'SDK/WYBasisKit/Layout/PagingView/**/*', 'SDK/WYBasisKit/Extension/UIView/**/*', 'SDK/WYBasisKit/Extension/UIButton/**/*', 'SDK/WYBasisKit/Extension/UIColor/**/*', 'SDK/WYBasisKit/Extension/UIImage/**/*', 'SDK/WYBasisKit/Config/WYBasisKitConfig.swift'
          pagingView.frameworks = 'Foundation', 'UIKit'
          pagingView.dependency 'SnapKit'
       end

       layout.subspec 'BannerView' do |bannerView|
          bannerView.source_files = 'SDK/WYBasisKit/Layout/BannerView/WYBannerView.swift', 'SDK/WYBasisKit/Extension/UIView/**/*', 'SDK/WYBasisKit/Config/WYBasisKitConfig.swift'
          bannerView.frameworks = 'Foundation', 'UIKit'
          bannerView.resource = 'SDK/WYBasisKit/Layout/BannerView/WYBannerView.bundle', 'SDK/WYBasisKit/Localizable/WYLocalizable.bundle'
          bannerView.dependency 'WYBasisKit-swift/Localizable'
          bannerView.dependency 'Kingfisher'
       end

       layout.subspec 'ChatView' do |chatView|
         chatView.source_files = 'SDK/WYBasisKit/Layout/ChatView/AudioManager/**/*', 'SDK/WYBasisKit/Layout/ChatView/Config/**/*', 'SDK/WYBasisKit/Layout/ChatView/Models/**/*', 'SDK/WYBasisKit/Layout/ChatView/RecordAnimation/**/*', 'SDK/WYBasisKit/Layout/ChatView/Views/**/*'
         chatView.frameworks = 'Foundation', 'UIKit'
         chatView.resource = 'SDK/WYBasisKit/Layout/ChatView/WYChatView.bundle'
         chatView.dependency 'WYBasisKit-swift/Extension'
         chatView.dependency 'WYBasisKit-swift/Localizable'
         chatView.dependency 'SnapKit'
         chatView.dependency 'Kingfisher'
       end
    end

    kit.subspec 'MediaPlayer' do |mediaPlayer|
       mediaPlayer.subspec 'Full' do |full|
         full.source_files = 'SDK/WYBasisKit/MediaPlayer/WYMediaPlayer.swift'
         full.vendored_frameworks = 'SDK/WYBasisKit/MediaPlayer/WYMediaPlayerFramework/arm64&x86_64/IJKMediaPlayer.xcframework'
         full.dependency 'SnapKit'
         full.dependency 'Kingfisher'
         full.libraries = 'c++', 'z', 'bz2'  #mediaPlayer.libraries = 'xxx.a'
         full.frameworks = 'UIKit', 'AudioToolbox', 'CoreGraphics', 'AVFoundation', 'CoreMedia', 'CoreVideo', 'MediaPlayer', 'CoreServices', 'Metal', 'QuartzCore', 'VideoToolbox'
         #full.vendored_libraries = 'xxx.a'
       end

       mediaPlayer.subspec 'Lite' do |lite|
         lite.source_files = 'SDK/WYBasisKit/MediaPlayer/WYMediaPlayer.swift'
         lite.vendored_frameworks = 'SDK/WYBasisKit/MediaPlayer/WYMediaPlayerFramework/arm64/IJKMediaPlayer.xcframework'
         lite.dependency 'SnapKit'
         lite.dependency 'Kingfisher'
         lite.libraries = 'c++', 'z', 'bz2'  #mediaPlayer.libraries = 'xxx.a'
         lite.frameworks = 'UIKit', 'AudioToolbox', 'CoreGraphics', 'AVFoundation', 'CoreMedia', 'CoreVideo', 'MediaPlayer', 'CoreServices', 'Metal', 'QuartzCore', 'VideoToolbox'
         #lite.vendored_libraries = 'xxx.a'
       end
    end
end
