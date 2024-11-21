Pod::Spec.new do |livePlayer|

  livePlayer.name         = 'WYLivePlayerLite'
  livePlayer.version      = '1.0.0'
  livePlayer.summary      = '基于IJKPlayer编译封装的直播播放器，支持RTMP/RTMPS/RTMPT/RTMPE/RTSP/HLS/HTTP(S)-FLV/KMP  等网络协议， 支持录屏功能, 支持arm64'
  livePlayer.description  = <<-DESC

                          集成注意事项：
                          1.使用cocoapods官方源
                          source 'https://github.com/CocoaPods/Specs.git'
                          pod 'WYLivePlayerLite'

                          2.指定 podspec 文件路径
                          source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'
                          pod 'WYLivePlayerLite', :podspec => 'https://raw.githubusercontent.com/Jacke-xu/WYBasisKit-swift/master/WYLivePlayerLite.podspec'
                   DESC

  livePlayer.homepage     = 'https://github.com/gaunren/WYBasisKit-swift'
  livePlayer.license      = { :type => 'MIT', :file => 'License.md' }
  livePlayer.author             = { '官人' => 'mobileAppDvlp@icloud.com' }
  livePlayer.ios.deployment_target = '12.0'
  livePlayer.source       = { :http => 'https://github.com/Jacke-xu/WYBasisKit-swift/blob/master/WYBasisKit/LivePlayer/WYLivePlayerLite.zip?raw=true' }
  livePlayer.swift_versions = '5.0'
  livePlayer.requires_arc = true
  livePlayer.source_files = 'WYBasisKit/LivePlayer/WYLivePlayerLite/WYLivePlayer.swift'
  livePlayer.dependency 'SnapKit'
  livePlayer.dependency 'Kingfisher'
  livePlayer.vendored_frameworks = 'WYBasisKit/LivePlayer/WYLivePlayerLite/IJKMediaFramework.framework'
  livePlayer.libraries = 'c++', 'z', 'bz2'
  livePlayer.frameworks = 'UIKit', 'AudioToolbox', 'CoreGraphics', 'AVFoundation', 'CoreMedia', 'CoreVideo', 'MediaPlayer', 'CoreServices', 'Metal', 'QuartzCore', 'VideoToolbox'
end
