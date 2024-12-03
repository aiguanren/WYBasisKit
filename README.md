# *WYBasisKit (持续更新)*



## WYBasisKit 是做什么的?

WYBasisKit 不仅可以帮助开发者快速构建一个工程，还有基于常用网络框架和系统API而封装的各种实用方法、扩展，开发者只需简单的调用API就可以快速实现相应功能， 大幅提高开发效率。

想必做 iOS 开发的小伙伴都有以下困扰吧，比如：
- 经常调用某个API，每次都需要复制粘贴；
- 想把网络请求进行易用化封装；
- 想把各种实用且好用的控件进行封装；
- 想对系统功能进行一些拓展；
- 想简单地调用 API 以快速实现相应功能；
- 想大幅提高开发效率等等。



## 基于此，也本着自我成长、总结的种种原因，**WYBasisKit** 便应运而生了。



## 使用示例(太多了，简单写几个)

##### 活动指示器
```
// 显示
WYActivity.showLoading(in: player, animation: .gifOrApng, config: WYActivityConfig.concise)

// 隐藏
WYActivity.dismissLoading(in: self.view)
```

##### Codable使用
```
let assetObj: WYDownloadModel? = try! WYCodable().decode(WYDownloadModel.self, from: success.origin.data(using: .utf8)!)
```

##### 国际化
```
WYLocalized("这是使用示例")
```

##### 本地存储(可设置过期时间)

```
// 获取
let cache = try! ImageCache(name: "hahaxiazai", cacheDirectoryURL: WYStorage.createDirectory(directory: .cachesDirectory, subDirectory: "WYBasisKit/Download"))

// 存储
let memoryData: WYStorageData = WYStorage.storage(forKey: "AAAAA", data: image!.jpegData(compressionQuality: 1.0)!, durable: .minute(2))
```

##### 网络请求(支持HTTPS自建证书单/双向认证、支持ProtoBuf、支持缓存等)

```
// 发起一个网络请求
public static func request(method: HTTPMethod = .post, path: String = "", data: Data? = nil, parameter: [String : Any] = [:], config: WYNetworkConfig = .default, handler:((_ result: WYHandler) -> Void)? = .none)

// 发起一个上传请求
public static func upload(path: String = "", parameter: [String : Any] = [:], files: [WYFileModel], config: WYNetworkConfig = .default, progress:((_ progress: Double) -> Void)? = .none, handler:((_ result: WYHandler) -> Void)? = .none)

// 发起一个下载请求
public static func download(path: String = "", parameter: [String : Any] = [:], assetName: String = "", config: WYNetworkConfig = .default, handler:((_ result: WYHandler) -> Void)? = .none)

// 清除缓存
public static func clearDiskCache(path: String, asset: String = "", completion:((_ error: String?) -> Void)? = .none)
```

## 效果展示(部分)

##### 暗夜模式切换
![暗夜模式切换.gif](https://upload-images.jianshu.io/upload_images/2795727-655d8095fa831984.gif?imageMogr2/auto-orient/strip)

##### UIView控件设置 圆角、阴影、边框等
![UIView控件圆角、阴影、边框.png](https://upload-images.jianshu.io/upload_images/2795727-009d8cc0fbf2a26b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

##### 自定义按钮的图片和文本控件位置
![自定义按钮的图片和文本控件位置.png](https://upload-images.jianshu.io/upload_images/2795727-7521a15b842dd4a1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

##### 二维码识别
![二维码.png](https://upload-images.jianshu.io/upload_images/2795727-05c338c47baa0482.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

##### 自定义Banner控件(2个ImageView极限优化)
![自定义Banner控件(2个ImageView极限优化).gif](https://upload-images.jianshu.io/upload_images/2795727-2f28ce8637eba031.gif?imageMogr2/auto-orient/strip)

##### 富文本控件
![富文本.gif](https://upload-images.jianshu.io/upload_images/2795727-8c2e5e4967e36b6a.gif?imageMogr2/auto-orient/strip)

##### 资源下载、保存(可设置本地资源过期时间)
![资源下载、保存.gif](https://upload-images.jianshu.io/upload_images/2795727-98d390183582e477.gif?imageMogr2/auto-orient/strip)

##### 网络请求
![网络请求.gif](https://upload-images.jianshu.io/upload_images/2795727-0c23bac40c439410.gif?imageMogr2/auto-orient/strip)

##### 屏幕旋转
![屏幕旋转.gif](https://upload-images.jianshu.io/upload_images/2795727-1f622a9594b25e9d.gif?imageMogr2/auto-orient/strip)

##### Gif加载
![Gif加载.gif](https://upload-images.jianshu.io/upload_images/2795727-c2113bb72e77192d.gif?imageMogr2/auto-orient/strip)

##### 魔改UICollectionViewFlowLayout，支持各种瀑布流
![瀑布流.gif](https://upload-images.jianshu.io/upload_images/2795727-648e17fc376af9a5.gif?imageMogr2/auto-orient/strip)

##### 直播、点播播放器(也可作为本地播放器)

![直播.gif](https://upload-images.jianshu.io/upload_images/2795727-c34a42eccae35729.gif?imageMogr2/auto-orient/strip)

##### 分页控制器
![分页控制器.gif](https://upload-images.jianshu.io/upload_images/2795727-82cd82599f668676.gif?imageMogr2/auto-orient/strip)

### 如何使用WYBasisKit
```
一、集成方式
    1、CocoaPods方式集成(推荐)
    pod 'WYBasisKit'
    
    # 集成数据解析类
    pod 'WYBasisKit/Codable'
    
    # 集成Layout库(libName： 目前包含ScrollText、PagingView和BannerView)
    pod 'WYBasisKit/Layout' 或者 pod 'WYBasisKit/Layout/libName'

    更多请查看WYBasisKit.podspec文件或者pod search WYBasisKit

    2、下载WYBasisKit，解压后将工程下的整个WYBasisKit文件或您需要的文件放进项目中
    
二、头文件引入
    1、推荐在AppDelegate中全局引入，复制粘贴 @_exported import WYBasisKit 在引入头文件的位置
    
    2、在需要使用的页面引入，即 import WYBasisKit
```

### 传送门

*   **简书**：[https://www.jianshu.com/u/2404ca96b483](https://www.jianshu.com/u/2404ca96b483)

*   **GitHub**：[https://github.com/gaunren/WYBasisKit-swift](https://github.com/gaunren/WYBasisKit-swift)

*   **CSDN**：[https://blog.csdn.net/qq_17157763?type=blog](https://blog.csdn.net/qq_17157763?type=blog)

*   **博客园**：[https://www.cnblogs.com/aiguanren](https://www.cnblogs.com/aiguanren)

## If you think it's cool,Please give me a little star. (如果你也觉得很酷😎，就点一下Star吧(●ˇ∀ˇ●))

### 目前WYBasisKit已基本开发完毕，更多功能敬请期待。

如您在使用过程中发现BUG,或有好的意见建议，可发邮件至[mobileAppDvlp@icloud.com](mailto:mobileAppDvlp@icloud.com)
