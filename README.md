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

##### 方法交换(MethodSwizzler)

Swift 与 Objective-C 共用交换实现，可按单个能力集成，注册和移除操作放在主线程执行。钩子作用于目标类的所有实例，建议为自己的子类注册。

```ruby
# Swift 最小组合
pod 'WYBasisKit-swift/MethodSwizzler/UIView/LayoutSubviews'

# Objective-C 最小组合
pod 'WYBasisKit-ObjC/MethodSwizzler/UIView/HitTest'
```

```swift
import WYBasisKitSwift

final class SampleView: UIView {}

wy_swizzlerLayoutSubviews(for: SampleView.self, after: { view in
    print(view.bounds)
})
wy_removeMethodExchangeHooks(for: SampleView.self, selector: #selector(UIView.layoutSubviews))
```

```objc
#import <UIKit/UIKit.h>
#import <WYBasisKitSwift/WYBasisKitSwift-Swift.h>

@interface SampleView : UIView
@end
@implementation SampleView
@end

// 在主线程中注册，返回result(nil)可明确阻止命中，不会被当成继续执行
WYMethodSwizzler.hitTest(SampleView.class,
    ^WYViewInterceptResult *(UIView *view, CGPoint point, UIEvent *event) {
        return CGRectContainsPoint(view.bounds, point)
            ? WYViewInterceptResult.proceed
            : WYViewInterceptResult.result(nil);
    },
    nil,
    ^UIView *(UIView *view, CGPoint point, UIEvent *event, UIView *originalResult) {
        return originalResult;
    });

WYMethodSwizzler.removeHooks(SampleView.class, @selector(hitTest:withEvent:));
```

ObjC 最小组合通过依赖的 `WYBasisKitSwift-Swift.h` 导出接口，无需 Swift 宿主源码。`WYMethodSwizzler` 的类属性返回 block，Swift 也可调用这些点语法入口，原有 `wy_swizzler*` 函数保持可用。各入口参数顺序均为目标类、可选 intercept、before、after，不含 intercept 的入口只传目标类、before、after。

同一目标类重复注册时，before 与 after 按注册顺序追加，非 nil intercept 替换已有 intercept，传入 nil 不会删除已有回调。通常执行顺序为 intercept → before → 原方法 → after，after 可修改返回值的入口会把上一个 after 的结果传给下一个 after。intercept 返回 nil 决策对象或 `proceed` 均继续执行，`result(value)` 跳过原方法及 before/after，value 可以明确为 nil、false 或零值。`drawRect` 与 `drawText` 的 `result(rect)` 仅替换绘制矩形，before、原绘制方法、after 仍依次执行。`popViewController` 的 after 只观察弹出的控制器，不替换返回值。

| 决策类型 | result参数 |
| --- | --- |
| WYViewInterceptResult | UIView *，允许nil |
| WYViewControllerInterceptResult | UIViewController *，允许nil |
| WYSizeInterceptResult | CGSize，允许CGSizeZero |
| WYRectInterceptResult | CGRect，允许CGRectZero |
| WYBoolInterceptResult | BOOL，允许false |
| WYLayoutAttributesInterceptResult | UICollectionViewLayoutAttributes *，允许nil |
| WYLayoutAttributesArrayInterceptResult | NSArray<UICollectionViewLayoutAttributes *> *，允许nil或空数组 |

每个能力的 subspec 路径在 `MethodSwizzler/` 后追加下表路径。`General` 单独提供决策类型和清理入口，不依赖其他能力。

| 能力路径 | Swift函数 | WYMethodSwizzler点语法入口 |
| --- | --- | --- |
| KVO/ObserveValue | wy_swizzlerKVOObserve | kvoObserve |
| UICollectionViewLayout/CollectionViewContentSize | wy_swizzlerCollectionViewContentSize | collectionViewContentSize |
| UICollectionViewLayout/LayoutAttributesForElements | wy_swizzlerLayoutAttributesForElements | layoutAttributesForElements |
| UICollectionViewLayout/LayoutAttributesForItem | wy_swizzlerLayoutAttributesForItem | layoutAttributesForItem |
| UICollectionViewLayout/LayoutAttributesForSupplementaryView | wy_swizzlerLayoutAttributesForSupplementaryView | layoutAttributesForSupplementaryView |
| UICollectionViewLayout/Prepare | wy_swizzlerLayoutPrepare | layoutPrepare |
| UICollectionViewLayout/ShouldInvalidateLayout | wy_swizzlerShouldInvalidateLayout | shouldInvalidateLayout |
| UIGestureRecognizerDelegate/GestureRecognizerShouldBegin | wy_swizzlerGestureRecognizerShouldBegin | gestureRecognizerShouldBegin |
| UILabel/DrawText | wy_swizzlerDrawText | drawText |
| UILabel/TextRect | wy_swizzlerTextRect | textRect |
| UINavigationController/PopViewController | wy_swizzlerPopViewController | popViewController |
| UIResponder/TouchesBegan | wy_swizzlerTouchesBegan | touchesBegan |
| UIResponder/TouchesCancelled | wy_swizzlerTouchesCancelled | touchesCancelled |
| UIResponder/TouchesEnded | wy_swizzlerTouchesEnded | touchesEnded |
| UIResponder/TouchesMoved | wy_swizzlerTouchesMoved | touchesMoved |
| UIScrollViewDelegate/ScrollViewDidEndDecelerating | wy_swizzlerScrollViewDidEndDecelerating | scrollViewDidEndDecelerating |
| UIScrollViewDelegate/ScrollViewDidEndDragging | wy_swizzlerScrollViewDidEndDragging | scrollViewDidEndDragging |
| UIScrollViewDelegate/ScrollViewDidScroll | wy_swizzlerScrollViewDidScroll | scrollViewDidScroll |
| UIScrollViewDelegate/ScrollViewDidZoom | wy_swizzlerScrollViewDidZoom | scrollViewDidZoom |
| UIScrollViewDelegate/ScrollViewWillBeginDecelerating | wy_swizzlerScrollViewWillBeginDecelerating | scrollViewWillBeginDecelerating |
| UIScrollViewDelegate/ScrollViewWillBeginDragging | wy_swizzlerScrollViewWillBeginDragging | scrollViewWillBeginDragging |
| UIScrollViewDelegate/ScrollViewWillEndDragging | wy_swizzlerScrollViewWillEndDragging | scrollViewWillEndDragging |
| UIView/DrawRect | wy_swizzlerDrawRect | drawRect |
| UIView/HitTest | wy_swizzlerHitTest | hitTest |
| UIView/IntrinsicContentSize | wy_swizzlerIntrinsicContentSize | intrinsicContentSize |
| UIView/LayoutSubviews | wy_swizzlerLayoutSubviews | layoutSubviews |
| UIView/SizeThatFits | wy_swizzlerSizeThatFits | sizeThatFits |
| UIViewController/Present | wy_swizzlerControllerPresent | controllerPresent |
| UIViewController/ViewDidAppear | wy_swizzlerViewDidAppear | viewDidAppear |
| UIViewController/ViewDidDisappear | wy_swizzlerViewDidDisappear | viewDidDisappear |
| UIViewController/ViewDidLoad | wy_swizzlerViewDidLoad | viewDidLoad |
| UIViewController/ViewWillAppear | wy_swizzlerViewWillAppear | viewWillAppear |
| UIViewController/ViewWillDisappear | wy_swizzlerViewWillDisappear | viewWillDisappear |

`removeHooks(targetClass, selector)` 仅清除指定类和方法的回调，selector 为 NULL 时清除该类全部回调；`removeAllHooks()` 清除全部已注册回调。清理会释放回调持有的对象，保留已安装的方法转发，后续可以重新注册。清理父类不会删除子类独立注册的回调，子类是否调用父类钩子遵循原方法继承和 super 调用关系。全局清理也会移除库内部注册的钩子，正在使用相关扩展时应按自己的目标类和 selector 清理。

错误类型的目标类或缺少目标实例方法时，点语法入口不注册回调。滚动结束拖动回调的 targetContentOffset 是可读写指针，修改值会继续传递给原方法及 after；KVO 的 context 和 present 的 completion 原样传递。回调会被持有到清理为止，捕获控制器或视图时应避免形成引用循环。

##### 系统服务与 eSIM (AppleServices)

```ruby
pod 'WYBasisKit-swift/AppleServices'
# Objective-C 工程
pod 'WYBasisKit-ObjC/AppleServices'
```

模块依赖 Localizable 与 Config，使用 Foundation、UIKit、CoreImage、CoreTelephony，不需要整个 Extension。系统链接操作的回调在主线程执行，允许不传回调；Objective-C 点语法操作需要回调参数时，可用空闭包或使用允许 nil 回调的方法入口。

| API | 用途与结果 |
| --- | --- |
| `esimCapability` | 返回 `WYEsimRegionSupport`，无法可靠确认时为 `unknown` |
| `isEsimInstallationLinkAvailable` | 系统版本是否提供 eSIM 通用链接入口，不检查设备、地区、套餐或系统是否接受请求 |
| `esimInstallationURL(lpa:)` | 生成链接，不打开链接、不检查设备能力，不合法时返回 nil |
| `requestEsimInstallation(lpa:completion:)` | 请求系统处理通用链接，返回非法资料、系统入口不可用、系统拒绝或系统接受，不回退到浏览器 |
| `install(lpa:unsupportedTip:completion:)` | iOS 17.4 起可用的兼容入口，请求失败显示提示，布尔回调仅表示系统是否接受链接 |
| `qrCode(lpa:size:)` | 生成完整 LPA 内容的二维码，不能生成时返回 nil |
| `open(url:completion:)` | 处理系统或自定义 scheme 链接，拒绝无 scheme 的相对链接与文件链接 |
| `openAppSettings(completion:)` | 请求打开当前 App 的系统设置 |
| `sendMail(to:cc:bcc:subject:body:completion:)` | 请求处理邮件链接，不自动发送邮件 |
| `sendSms(to:body:completion:)` | 请求处理短信链接，不自动发送短信 |
| `call(number:completion:)` | 请求处理拨号链接，不代表已接通电话 |
| `openAppPage(appId:completion:)` / `writeReview(appId:completion:)` | 请求打开 App Store 详情或评分链接，不代表已完成评分 |

`WYEsimRegionSupport` 同时表达硬件与适用地区，`supported` 表示硬件查询已返回支持、地区未知，`unknown` 表示连硬件能力也无法可靠确认。`chinaMainland`、`international` 分别表示仅支持对应地区运营商，`chinaMainlandAndInternational` 表示两者均支持，`unsupported` 表示已确认不支持。自动查询目前只返回 `supported` 或 `unknown`，不会推测地区或将未知转换为不支持。

[Apple 将 supportsEmbeddedSIM 定义为硬件支持属性](https://developer.apple.com/documentation/coretelephony/ctcellularplanprovisioning/supportsembeddedsim)，本地 SDK 声明其从 iOS 16 起可用。[所属类文档仍要求运营商授权](https://developer.apple.com/documentation/coretelephony/ctcellularplanprovisioning)，没有明确给出该属性的授权豁免，因此查询返回 false 时保留 unknown。模拟器与没有此属性的系统也返回 unknown。[supportsCellularPlan() 同时检查硬件、激活策略和运营商授权](https://developer.apple.com/documentation/coretelephony/ctcellularplanprovisioning/supportscellularplan())，不能用它的 false 判断设备不支持。

模块面向全球设备与使用地区，设备销售版本、eSIM 硬件、套餐支持地区、运营商锁定与实际安装条件分别影响可用性，不能把人在中国大陆或使用中文当作大陆销售版本，也不能把人在境外当作国际版本。[XS、XS Max、XR 已支持 eSIM](https://support.apple.com/zh-cn/118669)，[美版 iPhone 14 系列的变化是仅使用 eSIM，其他销售地区的 SIM 形态有所不同](https://support.apple.com/zh-cn/118569)。地区枚举表达运营商安装能力，不能等同当前所在地或保证任意运营商套餐都可安装。

公开查询没有提供大陆与境外运营商适用范围，不能用系统版本、Locale、当前 SIM 运营商或机型字符串单独判定。[中国大陆 eSIM 还受设备销售地区、所在地与运营商办理条件影响](https://support.apple.com/zh-cn/123879)。可在“设置 → 蜂窝网络”检查“添加 eSIM”，并请运营商核对具体销售型号、设备与套餐资格；有添加入口也不保证指定套餐可安装。

eSIM 的储存和同时启用数量取决于设备机型及销售版本，不取决于所安装套餐的运营商地区。中国大陆销售且支持 eSIM 的 iPhone，在境外开启定位服务后可安装当地运营商的 eSIM，在中国大陆境内不能安装境外运营商 eSIM；储存总数在境外仍最多两个，装满后需先删除一个，回国恢复已删除的大陆 eSIM 需重新到运营商营业厅办理。[大陆销售 iPhone 的安装和数量限制](https://support.apple.com/zh-cn/123879)

境外销售机型也不是无限储存，例如美版 iPhone 15 的规格为可储存八个或更多 eSIM、同时启用两个。储存数量与同时启用数量是独立限制，不能把所有境外机型都视为支持同时启用两个，也不能把这些 iPhone 数量说明直接套用于 iPad，需按具体机型和销售版本核对。本枚举不查询或返回这些数量。[iPhone 15 技术规格](https://support.apple.com/en-us/111831)

[CTCellularPlanProperties](https://developer.apple.com/documentation/coretelephony/ctcellularplanproperties) 的 `supportedRegionCodes` 用于配置指定 eSIM 的服务地区，不是读取设备销售地区或全球安装资格的查询入口。

LPA 支持省略或使用任意大小写的 `LPA:` 前缀，会去掉首尾空白并统一成大写前缀。内容需为 `1$SM-DP+服务器地址$激活码`，允许空激活码及后续可选字段，拒绝缺失字段、非法服务器地址和内部空白或控制字符。激活资料的大小写与特殊字符会保留，链接参数会编码，二维码内容为原始归一 LPA 串。二维码尺寸以像素计，输出采用正方形整数倍点阵且不超过传入宽高，尺寸过小、非有限、非正数或超过 `maximumQRCodeDimension`（4096）时返回 nil。

邮件地址使用裸邮箱地址，不支持显示名称或单个元素中拼入多个地址，多个地址分别放入数组。空白地址会跳过，非空非法地址会拒绝整个请求。电话和短信号码支持前导 `+`、ASCII 数字、空格、连字符、圆括号与小数点，不接受控制字符、查询分隔符或 `*`、`#`。App Store id 必须为包含非零数字的 ASCII 数字串。无效参数回调 false，不会请求系统处理。

```swift
let capability = WYAppleServices.esimCapability
if capability == .unknown {
    // 引导查看系统设置，并向运营商确认资格
}
let lpa = "1$example.com$ACTIVATION-CODE"
let image = WYAppleServices.qrCode(lpa: lpa, size: CGSize(width: 512, height: 512))
WYAppleServices.requestEsimInstallation(lpa: lpa) { result in
    switch result {
    case .requestAccepted:
        // 系统接受链接，安装与激活结果仍需在系统设置中确认
        break
    case .invalidLpa, .linkUnavailable, .requestRejected:
        // 根据请求结果提供二维码或运营商安装方式
        break
    @unknown default:
        break
    }
}
WYAppleServices.sendMail(to: ["help@example.com"], subject: "咨询", body: "内容") { accepted in
    // accepted 仅表示系统是否接受链接
}
```

```objc
WYEsimRegionSupport capability = WYAppleServices.esimCapability;
NSURL *url = WYAppleServices.esimInstallationURL(@"1$example.com$ACTIVATION-CODE");
UIImage *image = WYAppleServices.qrCode(@"1$example.com$ACTIVATION-CODE", CGSizeMake(512, 512));
WYAppleServices.requestEsimInstallation(@"1$example.com$ACTIVATION-CODE", ^(WYEsimRequestResult result) {
    if (result == WYEsimRequestResultRequestAccepted) {
        // 系统接受链接，安装与激活结果仍需在系统设置中确认
    }
});
WYAppleServices.sendMail(@[@"help@example.com"], @[], @[], @"咨询", @"内容", ^(BOOL accepted) {
    // accepted 仅表示系统是否接受链接
});
[WYAppleServices openAppSettingsWithCompletion:nil];
```

[Apple 的 eSIM 通用链接从 iOS 17.4 起启用](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-17_5-release-notes)。模块分别表达设备能力、系统入口版本可用性与链接请求结果，链接回调无法确认安装界面是否实际出现，也无法获知最终安装或激活结果。示例的“ESim”页面提供能力查询、二维码和请求入口，不会自动安装或修改蜂窝套餐。

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

##### 相片裁剪与标记(2026-10-15新增，矩形/圆形支持固定或自由尺寸，文本/矩形/圆形/箭头/划线标记)
```
// 一行代码打开编辑器(编辑成成品图回调图片，取消回调nil)
WYImageEditorViewController.present(from: self, image: image) { resultImage in
    // 圆形裁剪时resultImage是四角透明的PNG
}

// 也可以自己组装配置(固定300x300圆形头像裁剪、只裁剪不让标记)
var configuration = WYImageEditorConfiguration()
configuration.cropShape = .circle
configuration.cropSize = CGSize(width: 300, height: 300)
configuration.allowsCropping = true          // false时编辑器只有标记功能
configuration.allowsMarking = false          // false时编辑器只有裁剪功能
configuration.markerColor = .white
configuration.markerLineWidth = 0            // 0按图片宽度自动
configuration.markerTextFontSize = 0         // 0按图片宽度自动
configuration.lineDrawsStraight = false      // 划线形态(true为两点连直线，false为跟随手指自由划线)
configuration.showsStyleOptions = true       // 界面是否显示粗细字号选择行(false时用户只能用配置的默认值)
configuration.showsColorOptions = true       // 界面是否显示颜色选择条(false时用户只能用配置的默认颜色)
configuration.allowsImageZoom = true        // false时编辑器里不能捏合缩放图片
configuration.initialImageZoomScale = 1     // 进入页面时图片初始缩放倍数(1为适配显示)

// 界面外观全部可配(22项：画布/遮罩/裁剪框线/把手/选中虚线/删除钮/色板/档位倍率/工具条/分段控件/强调色等)
configuration.appearance.topBarCropButtonColor = .systemYellow // 顶部裁剪按钮颜色
configuration.appearance.selectionDashColor = .systemRed   // 标记选中态虚线颜色
configuration.appearance.handleColor = .systemYellow       // 裁剪把手颜色
configuration.appearance.accentColor = .systemGreen        // 选中态强调色
configuration.appearance.markerPalette = [.white, .red]    // 颜色条色板(空数组隐藏颜色行)
configuration.appearance.lineWidthRatios = [0.5, 1, 2]     // 线宽档位倍率

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

##### 点播播放器

`WYVideoPlayer` 在视频就绪后通过 `audioTrackNames` 读取声音语言名称，通过 `selectedAudioTrackIndex` 读取当前选项，`selectAudioTrack(at:)` 选择对应下标，传入 `-1` 恢复系统自动选择，其他越界值会被忽略。更多面板通过 `.audioTrack` 显示声音语言入口，只有一条或没有声音轨时不可点击。

```swift
player.selectAudioTrack(at: 1)
```

```objc
player.selectAudioTrack(1);
[player selectAudioTrackAtIndex:-1];
```

##### 直播、点播播放器(也可作为本地播放器)

`WYMediaPlayer` 加载视频后可读取 `pictureInPictureController`，系统不支持画中画时返回 `nil`。设置该控制器的 `delegate` 接收启动、停止和界面还原回调，在 `isPictureInPicturePossible` 为 `true` 时调用 `startPictureInPicture()`，停止时调用 `stopPictureInPicture()`。后台继续播放时调用 `setPauseInBackground(false)`，宿主 App 开启后台音频能力，`releaseAll` 会停止画中画并释放视频源。

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

### 图片浏览测试素材

两组 Live Photo 样例位于 [SwiftVerify/SwiftVerify/Resource](SwiftVerify/SwiftVerify/Resource)，Swift 与 Objective-C 验证工程共用这些资源。每组由同名 HEIC 静图和 MOV 视频组成，需保持配对使用，在「图片浏览」测试页长按播放。

- `棕榈步道`：[素材来源](https://github.com/NightMean/MotionPhotoSamples/tree/main/Apple%20Live%20Photo)
- `水中游鸟`：[素材来源](https://github.com/thun888/LivePhoto/tree/main/images)

### 传送门

*   **简书**：[https://www.jianshu.com/u/2404ca96b483](https://www.jianshu.com/u/2404ca96b483)

*   **GitHub**：[https://github.com/aiguanren/WYBasisKit](https://github.com/aiguanren/WYBasisKit)

*   **CSDN**：[https://blog.csdn.net/qq_17157763?type=blog](https://blog.csdn.net/qq_17157763?type=blog)

*   **博客园**：[https://www.cnblogs.com/aiguanren](https://www.cnblogs.com/aiguanren)

## If you think it's cool,Please give me a little star. (如果你也觉得很酷😎，就点一下Star吧(●ˇ∀ˇ●))

### 目前WYBasisKit已基本开发完毕，更多功能敬请期待。

如您在使用过程中发现BUG,或有好的意见建议，可发邮件至[aiguanren@icloud.com](mailto:aiguanren@icloud.com)
