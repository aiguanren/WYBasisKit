WYLivePlayer和WYLivePlayerLite共用一个WYLivePlayer.swift，唯一的区别是IJKMediaFramework.framework包不同，更新Cocoapods版本库的时候，需要手动解压对应的IJKMediaFramework包到当前目录中，不然验证会不通过

获取Github仓库中某个文件的下载地址

- 文件是压缩包

  例如文件链接是：https://github.com/gaunren/WYBasisKit-swift/blob/master/WYBasisKit/LivePlayer/IJKMediaFrameworkFull.zip，则在打开的链接的页面中找到`View raw`，然后右键点击，选择拷贝链接即可，也可以在点击`View raw`后在Safari浏览器的右上角的下载窗口中选择对应的下载文件右键，然后选择拷贝地址

- 文件是可以直接展示的

  例如文件链接是：https://github.com/gaunren/WYBasisKit-swift/blob/master/WYBasisKit.podspec，将其改为：https://raw.githubusercontent.com/gaunren/WYBasisKit-swift/master/WYBasisKit.podspec，将 `github.com` 替换为 `raw.githubusercontent.com`，并去除 `/blob`，也可以直接点击文件所在页面右侧的`Raw`按钮，然后地址栏中获取下载链接

