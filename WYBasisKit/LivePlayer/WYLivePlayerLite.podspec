Pod::Spec.new do |livePlayer|

  livePlayer.name         = 'WYLivePlayerLite'
  livePlayer.version      = '1.0.2'
  livePlayer.summary      = '基于IJKPlayer编译封装的直播播放器(也可作为视屏播放器)，支持RTMP/RTMPS/RTMPT/RTMPE/RTSP/HLS/HTTP(S)-FLV/KMP 等直播协议与MP4、FLV等格式， 支持录屏功能，支持arm64设备'
  livePlayer.description  = <<-DESC

                          集成注意事项：
                          1.使用cocoapods官方源
                          source 'https://github.com/CocoaPods/Specs.git'
                          pod 'WYLivePlayerLite'

                          2.指定 podspec 文件路径
                          source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'
                          pod 'WYLivePlayerLite', :podspec => 'https://raw.githubusercontent.com/gaunren/WYBasisKit-swift/master/WYLivePlayerLite.podspec'
                   DESC

  livePlayer.homepage     = 'https://github.com/gaunren/WYBasisKit-swift'
  livePlayer.license      = { :type => 'MIT', :file => 'License.md' }
  livePlayer.author             = { '官人' => 'mobileAppDvlp@icloud.com' }
  livePlayer.ios.deployment_target = '13.0'
  livePlayer.source       = { :http => 'https://github.com/gaunren/WYBasisKit-swift/raw/refs/heads/master/WYBasisKit/LivePlayer/Lite/Lite.zip' }
  livePlayer.swift_versions = '5.0'
  livePlayer.requires_arc = true
  livePlayer.source_files = 'Lite/WYLivePlayer.swift'
  livePlayer.dependency 'SnapKit'
  livePlayer.dependency 'Kingfisher'
  livePlayer.vendored_frameworks = 'Lite/IJKMediaPlayer.xcframework'
  livePlayer.libraries = 'c++', 'z', 'bz2'
  livePlayer.frameworks = 'UIKit', 'AudioToolbox', 'CoreGraphics', 'AVFoundation', 'CoreMedia', 'CoreVideo', 'MediaPlayer', 'CoreServices', 'Metal', 'QuartzCore', 'VideoToolbox'
end
