Pod::Spec.new do |livePlayer|

  livePlayer.name         = 'WYLivePlayer'
  livePlayer.version      = '1.0.1'
  livePlayer.summary      = '基于IJKPlayer编译封装的直播播放器(也可作为视屏播放器)，支持RTMP/RTMPS/RTMPT/RTMPE/RTSP/HLS/HTTP(S)-FLV/KMP 等直播协议与MP4、FLV等格式， 支持录屏功能, 支持支持arm64设备与x86_64模拟器'
  livePlayer.description  = <<-DESC

                          集成注意事项：
                          1.使用cocoapods官方源
                          source 'https://github.com/CocoaPods/Specs.git'
                          pod 'WYLivePlayer'

                          2.指定 podspec 文件路径
                          source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'
                          pod 'WYLivePlayer', :podspec => 'https://raw.githubusercontent.com/gaunren/WYBasisKit-swift/master/WYLivePlayer.podspec'
                   DESC

  livePlayer.homepage     = 'https://github.com/gaunren/WYBasisKit-swift'
  livePlayer.license      = { :type => 'MIT', :file => 'License.md' }
  livePlayer.author             = { '官人' => 'mobileAppDvlp@icloud.com' }
  livePlayer.ios.deployment_target = '13.0'
  livePlayer.source       = { :http => 'https://github.com/gaunren/WYBasisKit-swift/raw/refs/heads/master/WYBasisKit/LivePlayer/IJKMediaFrameworkFull.zip' }
  livePlayer.swift_versions = '5.0'
  livePlayer.requires_arc = true
  livePlayer.source_files = 'WYBasisKit/LivePlayer/WYLivePlayer.swift'
  livePlayer.dependency 'SnapKit'
  livePlayer.dependency 'Kingfisher'
  livePlayer.vendored_frameworks = 'WYBasisKit/LivePlayer/IJKMediaFramework.framework'
  #livePlayer.vendored_libraries = 'xxx.a'
  livePlayer.libraries = 'c++', 'z', 'bz2'
  livePlayer.frameworks = 'UIKit', 'AudioToolbox', 'CoreGraphics', 'AVFoundation', 'CoreMedia', 'CoreVideo', 'MediaPlayer', 'CoreServices', 'Metal', 'QuartzCore', 'VideoToolbox'
  #livePlayer.libraries = 'xxx.a'
end
