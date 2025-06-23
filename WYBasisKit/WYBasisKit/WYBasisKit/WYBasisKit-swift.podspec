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
   kit.resource_bundles = {'WYBasisKit-swift' => ['PrivacyInfo.xcprivacy']}
   kit.swift_versions = '5.0'
   kit.requires_arc = true
   #指定默认模块，不指定则表示全部模块
   kit.default_subspecs = [
      'Config',
      'Localizable',
      'Extension',
      'Networking',
      'Activity',
      'Storage',
      'Codable',
   ]
   #kit.module_name  = 'WYBasisKit'  手动指定模块名

   # 下载并解压 WYMediaPlayerFramework
   kit.prepare_command = 'bash MediaPlayer/WYMediaPlayerFramework.sh'

   kit.subspec 'Config' do |config|
      config.source_files = 'Config/**/*'
      config.frameworks = 'Foundation', 'UIKit'
   end

   kit.subspec 'Localizable' do |localizable|
      localizable.source_files = 'Localizable/WYLocalizableManager.swift'
      localizable.frameworks = 'Foundation', 'UIKit'
      localizable.dependency 'WYBasisKit-swift/Config'
   end

   kit.subspec 'Extension' do |extension|
      extension.source_files = 'Extension/**/*'
      extension.frameworks = 'Foundation', 'UIKit', 'LocalAuthentication', 'Photos', 'CoreFoundation'
      extension.resource = 'Localizable/WYLocalizable.bundle'
      extension.dependency 'WYBasisKit-swift/Localizable'
      extension.dependency 'WYBasisKit-swift/Config'
   end

   kit.subspec 'Codable' do |codable|
      codable.source_files = 'Codable/**/*'
      codable.frameworks = 'Foundation', 'UIKit'
   end
    
   kit.subspec 'Networking' do |networking|
      networking.source_files = 'Networking/**/*', 'Networking/Extension/UIAlertController/**/*'
      networking.resource = 'Localizable/WYLocalizable.bundle'
      networking.frameworks = 'Foundation', 'UIKit'
      networking.dependency 'WYBasisKit-swift/Localizable'
      networking.dependency 'WYBasisKit-swift/Storage'
      networking.dependency 'WYBasisKit-swift/Codable'
      networking.dependency 'Moya'
   end

   kit.subspec 'Activity' do |activity|
      activity.source_files = 'Activity/WYActivity.swift', 'Extension/UIView/UIView.swift', 'Extension/UIViewController/UIViewController.swift', 'Extension/NSAttributedString/NSAttributedString.swift', 'Extension/String/String.swift', 'Extension/UIImage/UIImage.swift', 'Config/WYBasisKitConfig.swift'
      activity.resource = 'Activity/WYActivity.bundle', 'Localizable/WYLocalizable.bundle'
      activity.frameworks = 'Foundation', 'UIKit'
      activity.dependency 'WYBasisKit-swift/Localizable'
   end

   kit.subspec 'Storage' do |storage|
      storage.source_files = 'Storage/**/*'
      storage.frameworks = 'Foundation', 'UIKit'
   end

   kit.subspec 'Authorization' do |authorization|
      authorization.subspec 'Camera' do |camera|
         camera.source_files = 'Authorization/Camera/**/*', 'Extension/UIAlertController/**/*'
         camera.resource = 'Localizable/WYLocalizable.bundle'
         camera.frameworks = 'AVFoundation', 'UIKit', 'Photos'
         camera.dependency 'WYBasisKit-swift/Localizable'
      end

      authorization.subspec 'Biometric' do |biometric|
         biometric.source_files = 'Authorization/Biometric/**/*'
         biometric.resource = 'Localizable/WYLocalizable.bundle'
         biometric.frameworks = 'Foundation', 'LocalAuthentication'
         biometric.dependency 'WYBasisKit-swift/Localizable'
      end

      authorization.subspec 'Contacts' do |contacts|
         contacts.source_files = 'Authorization/Contacts/**/*', 'Extension/UIAlertController/**/*'
         contacts.resource = 'Localizable/WYLocalizable.bundle'
         contacts.frameworks = 'Contacts', 'UIKit'
         contacts.dependency 'WYBasisKit-swift/Localizable'
      end

      authorization.subspec 'PhotoAlbums' do |photoAlbums|
         photoAlbums.source_files = 'Authorization/PhotoAlbums/**/*', 'Extension/UIAlertController/**/*'
         photoAlbums.resource = 'Localizable/WYLocalizable.bundle'
         photoAlbums.frameworks = 'Photos', 'UIKit'
         photoAlbums.dependency 'WYBasisKit-swift/Localizable'
      end

      authorization.subspec 'Microphone' do |microphone|
         microphone.source_files = 'Authorization/Microphone/**/*', 'Extension/UIAlertController/**/*'
         microphone.resource = 'Localizable/WYLocalizable.bundle'
         microphone.frameworks = 'Photos', 'UIKit'
         microphone.dependency 'WYBasisKit-swift/Localizable'
      end

      authorization.subspec 'SpeechRecognition' do |speechRecognition|
         speechRecognition.source_files = 'Authorization/SpeechRecognition/**/*', 'Extension/UIAlertController/**/*'
         speechRecognition.resource = 'Localizable/WYLocalizable.bundle'
         speechRecognition.frameworks = 'Speech', 'UIKit'
         speechRecognition.dependency 'WYBasisKit-swift/Localizable'
      end
   end

   kit.subspec 'Layout' do |layout|
      layout.subspec 'ScrollText' do |scrollText|
         scrollText.source_files = 'Layout/ScrollText/**/*', 'Config/WYBasisKitConfig.swift'
         scrollText.resource = 'Localizable/WYLocalizable.bundle'
         scrollText.frameworks = 'Foundation', 'UIKit'
         scrollText.dependency 'WYBasisKit-swift/Localizable'
         scrollText.dependency 'SnapKit'
      end

      layout.subspec 'PagingView' do |pagingView|
         pagingView.source_files = 'Layout/PagingView/**/*', 'Extension/UIView/**/*', 'Extension/UIButton/**/*', 'Extension/UIColor/**/*', 'Extension/UIImage/**/*', 'Config/WYBasisKitConfig.swift'
         pagingView.frameworks = 'Foundation', 'UIKit'
         pagingView.dependency 'SnapKit'
      end

      layout.subspec 'BannerView' do |bannerView|
         bannerView.source_files = 'Layout/BannerView/WYBannerView.swift', 'Extension/UIView/**/*', 'Config/WYBasisKitConfig.swift'
         bannerView.resource = 'Layout/BannerView/WYBannerView.bundle', 'Localizable/WYLocalizable.bundle'
         bannerView.frameworks = 'Foundation', 'UIKit'
         bannerView.dependency 'WYBasisKit-swift/Localizable'
         bannerView.dependency 'Kingfisher'
         
      end

      layout.subspec 'ChatView' do |chatView|
         chatView.source_files = 'Layout/ChatView/AudioManager/**/*', 'Layout/ChatView/Config/**/*', 'Layout/ChatView/Models/**/*', 'Layout/ChatView/RecordAnimation/**/*', 'Layout/ChatView/Views/**/*'
         chatView.resource = 'Layout/ChatView/WYChatView.bundle'
         chatView.frameworks = 'Foundation', 'UIKit'
         chatView.dependency 'WYBasisKit-swift/Extension'
         chatView.dependency 'WYBasisKit-swift/Localizable'
         chatView.dependency 'SnapKit'
         chatView.dependency 'Kingfisher'
      end
   end

   kit.subspec 'MediaPlayer' do |mediaPlayer|
      mediaPlayer.subspec 'Full' do |full|
         full.source_files = 'MediaPlayer/WYMediaPlayer.swift'
         full.vendored_frameworks = 'MediaPlayer/WYMediaPlayerFramework/arm64&x86_64/IJKMediaPlayer.xcframework'
         full.dependency 'SnapKit'
         full.dependency 'Kingfisher'
         # libraries 这里需要忽略前面的lib和后面的tbd，例如libz.tbd直接写为z即可
         full.libraries = 'c++', 'z', 'bz2'  #mediaPlayer.libraries = 'xxx.a'
         full.frameworks = 'UIKit', 'AudioToolbox', 'CoreGraphics', 'AVFoundation', 'CoreMedia', 'CoreVideo', 'MediaPlayer', 'CoreServices', 'Metal', 'QuartzCore', 'VideoToolbox'
         #full.vendored_libraries = 'xxx.a'
      end

      mediaPlayer.subspec 'Lite' do |lite|
         lite.source_files = 'MediaPlayer/WYMediaPlayer.swift'
         lite.vendored_frameworks = 'MediaPlayer/WYMediaPlayerFramework/arm64/IJKMediaPlayer.xcframework'
         lite.dependency 'SnapKit'
         lite.dependency 'Kingfisher'
         # libraries 这里需要忽略前面的lib和后面的tbd，例如libz.tbd直接写为z即可
         lite.libraries = 'c++', 'z', 'bz2'  #mediaPlayer.libraries = 'xxx.a'
         lite.frameworks = 'UIKit', 'AudioToolbox', 'CoreGraphics', 'AVFoundation', 'CoreMedia', 'CoreVideo', 'MediaPlayer', 'CoreServices', 'Metal', 'QuartzCore', 'VideoToolbox'
         #lite.vendored_libraries = 'xxx.a'
      end
   end
end
