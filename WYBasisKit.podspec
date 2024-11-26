Pod::Spec.new do |kit|

  kit.name         = 'WYBasisKit'
  kit.version      = '1.3.4'
  kit.summary      = 'WYBasisKit 不仅可以帮助开发者快速构建一个工程，还有基于常用网络框架和系统API而封装的各种实用方法、扩展，开发者只需简单的调用API就可以快速实现相应功能， 大幅提高开发效率。'
  kit.description  = <<-DESC
                         Localizable: 国际化解决方案
                         Extension: 各种系统扩展
                         Networking: 网络请求解决方案
                         Activity: 活动指示器
                         Storage: 本地存储
                         Layout: 各种自定义控件
                         Codable: 数据解析
                         Authorization: 各种权限请求与判断
                         LivePlayer: 基于IJKPlayer编译封装的直播播放器(也可作为视屏播放器)，支持RTMP/RTMPS/RTMPT/RTMPE/RTSP/HLS/HTTP(S)-FLV/KMP 等直播协议与MP4、FLV等格式， 支持录屏功能, 完整版支持支持arm64与x86_64，轻量版仅支持arm64'
                   DESC

  kit.homepage     = 'https://github.com/gaunren/WYBasisKit-swift'
  kit.license      = { :type => 'MIT', :file => 'License.md' }
  kit.author             = { '官人' => 'mobileAppDvlp@icloud.com' }
  kit.ios.deployment_target = '13.0'
  kit.source       = { :git => 'https://github.com/gaunren/WYBasisKit-swift.git', :tag => "#{kit.version}" }
  #kit.source       = { :svn => "http://192.168.xxx.xxx:xxxx/xxx/xxx/WYBasiskit"}
  kit.swift_versions = '5.0'
  kit.requires_arc = true
  kit.default_subspecs = 'Extension'
  # 自动解压脚本
  kit.prepare_command = <<-SH
    echo "Preparing WYLivePlayer..."
    if [ ! -d "WYBasisKit/LivePlayer/WYLivePlayer/IJKMediaFramework.framework" ]; then
      curl -L -o WYLivePlayer.zip https://github.com/gaunren/WYBasisKit-swift/raw/refs/heads/master/WYBasisKit/LivePlayer/WYLivePlayer.zip
      unzip -o WYLivePlayer.zip -d WYBasisKit/LivePlayer/
      rm WYLivePlayer.zip
    fi
    if [ ! -d "WYBasisKit/LivePlayer/WYLivePlayerLite/IJKMediaFramework.framework" ]; then
      curl -L -o WYLivePlayerLite.zip https://github.com/gaunren/WYBasisKit-swift/raw/refs/heads/master/WYBasisKit/LivePlayer/WYLivePlayerLite.zip
      unzip -o WYLivePlayerLite.zip -d WYBasisKit/LivePlayer/
      rm WYLivePlayerLite.zip
    fi
  SH

    kit.subspec 'Config' do |config|
       config.source_files = 'WYBasisKit/Config/**/*'
       config.frameworks = 'Foundation', 'UIKit'
    end

    kit.subspec 'Localizable' do |localizable|
       localizable.source_files = 'WYBasisKit/Localizable/WYLocalizableManager.swift'
       localizable.frameworks = 'Foundation', 'UIKit'
       localizable.dependency 'WYBasisKit/Config'
    end

    kit.subspec 'Extension' do |extension|
       extension.source_files = 'WYBasisKit/Extension/**/*'
       extension.frameworks = 'Foundation', 'UIKit', 'LocalAuthentication', 'Photos', 'CoreFoundation'
       extension.resource = 'WYBasisKit/Localizable/WYLocalizable.bundle'
       extension.dependency 'WYBasisKit/Localizable'
       extension.dependency 'WYBasisKit/Config'
    end

    kit.subspec 'Codable' do |codable|
       codable.source_files = 'WYBasisKit/Codable/**/*'
       codable.frameworks = 'Foundation', 'UIKit'
    end
    
    kit.subspec 'Networking' do |networking|
       networking.source_files = 'WYBasisKit/Networking/**/*', 'WYBasisKit/Extension/UIAlertController/**/*'
       networking.frameworks = 'Foundation', 'UIKit'
       networking.resource = 'WYBasisKit/Localizable/WYLocalizable.bundle'
       networking.dependency 'WYBasisKit/Localizable'
       networking.dependency 'WYBasisKit/Storage'
       networking.dependency 'WYBasisKit/Codable'
       networking.dependency 'Moya'
    end

    kit.subspec 'Activity' do |activity|
       activity.source_files = 'WYBasisKit/Activity/WYActivity.swift', 'WYBasisKit/Extension/UIView/UIView.swift', 'WYBasisKit/Extension/UIViewController/UIViewController.swift', 'WYBasisKit/Extension/NSAttributedString/NSAttributedString.swift', 'WYBasisKit/Extension/String/String.swift', 'WYBasisKit/Extension/UIImage/UIImage.swift', 'WYBasisKit/Config/WYBasisKitConfig.swift'
       activity.frameworks = 'Foundation', 'UIKit'
       activity.resource = 'WYBasisKit/Activity/WYActivity.bundle', 'WYBasisKit/Localizable/WYLocalizable.bundle'
       activity.dependency 'WYBasisKit/Localizable'
    end

    kit.subspec 'Storage' do |storage|
       storage.source_files = 'WYBasisKit/Storage/**/*'
       storage.frameworks = 'Foundation', 'UIKit'
    end

    kit.subspec 'Authorization' do |authorization|
       authorization.subspec 'Camera' do |camera|
          camera.source_files = 'WYBasisKit/Authorization/Camera/**/*', 'WYBasisKit/Extension/UIAlertController/**/*'
          camera.frameworks = 'AVFoundation', 'UIKit', 'Photos'
          camera.resource = 'WYBasisKit/Localizable/WYLocalizable.bundle'
          camera.dependency 'WYBasisKit/Localizable'
       end

       authorization.subspec 'Biometric' do |biometric|
          biometric.source_files = 'WYBasisKit/Authorization/Biometric/**/*'
          biometric.frameworks = 'Foundation', 'LocalAuthentication'
          biometric.resource = 'WYBasisKit/Localizable/WYLocalizable.bundle'
          biometric.dependency 'WYBasisKit/Localizable'
       end

       authorization.subspec 'Contacts' do |contacts|
          contacts.source_files = 'WYBasisKit/Authorization/Contacts/**/*', 'WYBasisKit/Extension/UIAlertController/**/*'
          contacts.frameworks = 'Contacts', 'UIKit'
          contacts.resource = 'WYBasisKit/Localizable/WYLocalizable.bundle'
          contacts.dependency 'WYBasisKit/Localizable'
       end

       authorization.subspec 'PhotoAlbums' do |photoAlbums|
          photoAlbums.source_files = 'WYBasisKit/Authorization/PhotoAlbums/**/*', 'WYBasisKit/Extension/UIAlertController/**/*'
          photoAlbums.frameworks = 'Photos', 'UIKit'
          photoAlbums.resource = 'WYBasisKit/Localizable/WYLocalizable.bundle'
          photoAlbums.dependency 'WYBasisKit/Localizable'
       end

       authorization.subspec 'Microphone' do |microphone|
          microphone.source_files = 'WYBasisKit/Authorization/Microphone/**/*', 'WYBasisKit/Extension/UIAlertController/**/*'
          microphone.frameworks = 'Photos', 'UIKit'
          microphone.resource = 'WYBasisKit/Localizable/WYLocalizable.bundle'
          microphone.dependency 'WYBasisKit/Localizable'
       end

       authorization.subspec 'SpeechRecognition' do |speechRecognition|
          speechRecognition.source_files = 'WYBasisKit/Authorization/SpeechRecognition/**/*', 'WYBasisKit/Extension/UIAlertController/**/*'
          speechRecognition.frameworks = 'Speech', 'UIKit'
          speechRecognition.resource = 'WYBasisKit/Localizable/WYLocalizable.bundle'
          speechRecognition.dependency 'WYBasisKit/Localizable'
       end
    end

    kit.subspec 'Layout' do |layout|
       layout.subspec 'ScrollText' do |scrollText|
          scrollText.source_files = 'WYBasisKit/Layout/ScrollText/**/*', 'WYBasisKit/Config/WYBasisKitConfig.swift'
          scrollText.frameworks = 'Foundation', 'UIKit'
          scrollText.resource = 'WYBasisKit/Localizable/WYLocalizable.bundle'
          scrollText.dependency 'WYBasisKit/Localizable'
          scrollText.dependency 'SnapKit'
       end

       layout.subspec 'PagingView' do |pagingView|
          pagingView.source_files = 'WYBasisKit/Layout/PagingView/**/*', 'WYBasisKit/Extension/UIView/**/*', 'WYBasisKit/Extension/UIButton/**/*', 'WYBasisKit/Extension/UIColor/**/*', 'WYBasisKit/Extension/UIImage/**/*', 'WYBasisKit/Config/WYBasisKitConfig.swift'
          pagingView.frameworks = 'Foundation', 'UIKit'
          pagingView.dependency 'SnapKit'
       end

       layout.subspec 'BannerView' do |bannerView|
          bannerView.source_files = 'WYBasisKit/Layout/BannerView/WYBannerView.swift', 'WYBasisKit/Extension/UIView/**/*', 'WYBasisKit/Config/WYBasisKitConfig.swift'
          bannerView.frameworks = 'Foundation', 'UIKit'
          bannerView.resource = 'WYBasisKit/Layout/BannerView/WYBannerView.bundle', 'WYBasisKit/Localizable/WYLocalizable.bundle'
          bannerView.dependency 'WYBasisKit/Localizable'
          bannerView.dependency 'Kingfisher'
       end
    end

    kit.subspec 'LivePlayer' do |livePlayer|
       livePlayer.subspec 'Full' do |full|
          full.dependency 'SnapKit'
          full.dependency 'Kingfisher'
          full.vendored_frameworks = 'WYBasisKit/LivePlayer/WYLivePlayer/IJKMediaFramework.framework'
          #full.vendored_libraries = 'xxx.a'
          full.libraries = 'c++', 'z', 'bz2'
          full.frameworks = 'UIKit', 'AudioToolbox', 'CoreGraphics', 'AVFoundation', 'CoreMedia', 'CoreVideo', 'MediaPlayer', 'CoreServices', 'Metal', 'QuartzCore', 'VideoToolbox'
       end

       livePlayer.subspec 'Lite' do |lite|
          lite.dependency 'SnapKit'
          lite.dependency 'Kingfisher'
          lite.vendored_frameworks = 'WYBasisKit/LivePlayer/WYLivePlayerLite/IJKMediaFramework.framework'
          #lite.vendored_libraries = 'xxx.a'
          lite.libraries = 'c++', 'z', 'bz2'
          lite.frameworks = 'UIKit', 'AudioToolbox', 'CoreGraphics', 'AVFoundation', 'CoreMedia', 'CoreVideo', 'MediaPlayer', 'CoreServices', 'Metal', 'QuartzCore', 'VideoToolbox'
       end
    end
end
