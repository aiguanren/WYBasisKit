Pod::Spec.new do |chat|

  chat.name         = 'ChatView'
  chat.version      = '1.3.2'
  chat.summary      = 'WYBasisKit 不仅可以帮助开发者快速构建一个工程，还有基于常用网络框架和系统API而封装的各种实用方法、扩展，开发者只需简单的调用API就可以快速实现相应功能， 大幅提高开发效率。'
  chat.description  = <<-DESC
                         Localizable: 国际化解决方案
                         Extension: 各种系统扩展
                         Networking: 网络请求解决方案
                         Activity: 活动指示器
                         Storage: 本地存储
                         Layout: 布局相关
                         Codable: 数据解析
                         Authorization: 各种权限请求与判断
                   DESC

  chat.homepage     = 'https://github.com/Jacke-xu/WYBasisKit-swift'
  chat.license      = { :type => 'MIT', :file => 'License.md' }
  chat.author             = { '官人' => 'mobileAppDvlp@icloud.com' }
  chat.ios.deployment_target = '12.0'
  chat.source       = { :git => 'https://github.com/Jacke-xu/WYBasisKit-swift.git', :tag => "#{chat.version}" }
  chat.swift_versions = '5.0'
  chat.requires_arc = true
  chat.source_files = 'AudioManager/**/*', 'Config/**/*', 'Models/**/*', 'RecordAnimation/**/*', 'Views/**/*'
  chat.frameworks = 'Foundation', 'UIKit'
  chat.resource = 'WYChatView.bundle'
  chat.dependency 'WYBasisKit'
  chat.dependency 'WYBasisKit/Localizable'
  chat.dependency 'SnapKit'
  chat.dependency 'Kingfisher'
end
