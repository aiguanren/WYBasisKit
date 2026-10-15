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

##### 通用加解密(2026-10-12新增，MD5/SHA/HMAC/AES-GCM/XOR/Base64/Hex/随机数/PBKDF2)
```
// 摘要与签名(小写十六进制串)
WYCryptor.md5Hex("abc")                    // 900150983cd24fb0d6963f7d28e17f72
WYCryptor.sha256Hex("abc")
WYCryptor.hmacSHA256Hex(message: "content", key: "secret")

// AES-256-GCM(每次随机nonce，密钥任意长度，篡改可检测)
let cipher = WYCryptor.aesGCMEncryptString("明文内容", key: "任意长度密钥")
let plain = WYCryptor.aesGCMDecryptString(cipher!, key: "任意长度密钥")

// 其他工具
WYCryptor.xor(data, key: keyData)          // 加密解密同一方法
WYCryptor.hexDecode("deadbeef")
WYCryptor.randomBytes(count: 32)           // 安全随机源
WYCryptor.pbkdf2(password: "pwd", salt: "salt", rounds: 10000, length: 32)
```

##### 日志(文件默认AES-GCM加密，直接打开或导出的都是密文；预览界面自动解密)
```
// 打印日志(五种输出模式，含只落文件不打控制台的onlySaveToFile)
wy_print("日志内容", outputMode: .onlySaveToFile)

// 加密四档：none(排查用)/base64/xor/aesGCM(默认)，零配置默认开启
WYLogManager.encryptionMode = .aesGCM

// 建议接入方首次写日志前设置自己的密钥(不设置时按包名派生)
WYLogManager.encryptionKey = Data("你的密钥".utf8)

// 自定义日志文件名(不含扩展名；不设置时取App名，纯中文App名自动回落包名末段，不会生成"____.log")
WYLogManager.logFileName = "MyApp-DiagnosticLog"

// 读回明文(历史明文条目原样保留，解密失败条目自动跳过)
let plainLogs = WYLogManager.decryptedLogText()

// 悬浮按钮预览日志(内置搜索/复制/分享/清除)
WYLogManager.showPreview()
```

##### 相片裁剪与标记(2026-10-15新增，矩形/圆形支持固定或自由尺寸，文本/矩形/圆形/箭头标记)
```
// 一行代码打开编辑器(编辑成成品图回调图片，取消回调nil)
WYImageEditorViewController.present(from: self, image: image) { resultImage in
    // 圆形裁剪时resultImage是四角透明的PNG
}

// 也可以自己组装配置(固定300x300圆形头像裁剪、只裁剪不让标记)
var configuration = WYImageEditorConfiguration()
configuration.cropShape = .circle
configuration.cropSize = CGSize(width: 300, height: 300)
configuration.allowsMarking = false
configuration.markerColor = .white
configuration.markerLineWidth = 0            // 0按图片宽度自动
configuration.markerTextFontSize = 0         // 0按图片宽度自动
let editor = WYImageEditorViewController(image: image, configuration: configuration)
editor.onFinish = { resultImage in ... }     // Block回调
editor.onCancel = { ... }
editor.editorDelegate = self                 // 与Block同时设置时两边都会回调
present(editor, animated: true)
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

*   **GitHub**：[https://github.com/aiguanren/WYBasisKit](https://github.com/aiguanren/WYBasisKit)

*   **CSDN**：[https://blog.csdn.net/qq_17157763?type=blog](https://blog.csdn.net/qq_17157763?type=blog)

*   **博客园**：[https://www.cnblogs.com/aiguanren](https://www.cnblogs.com/aiguanren)

## If you think it's cool,Please give me a little star. (如果你也觉得很酷😎，就点一下Star吧(●ˇ∀ˇ●))

### 目前WYBasisKit已基本开发完毕，更多功能敬请期待。

如您在使用过程中发现BUG,或有好的意见建议，可发邮件至[aiguanren@icloud.com](mailto:aiguanren@icloud.com)
