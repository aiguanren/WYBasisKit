//
//  Swift↔ObjC.swift
//  Swift ↔ Objective‑C 类型对照
//
//  Created by guanren on 2025/8/26.
//

/**

一、基础数值与布尔
────────────────────
整数（平台相关）
- Swift: Int / UInt
- ObjC: NSInteger / NSUInteger
- 特点: Swift 值语义，位宽随平台；OC NSInteger 引用类型，32/64 位不同
- 建议: 业务层统一用 Int；与 OC API 交互桥接自动
- 版本提示: 无

精确位宽整数
- Swift: Int8/16/32/64, UInt8/16/32/64
- ObjC(C): char/short/int/long long (+ unsigned)
- 特点: Swift 位宽明确，跨平台/协议更安全
- 建议: 协议/二进制/位运算使用精确位宽
- 版本提示: 无

浮点
- Swift: Float / Double
- ObjC: float / double
- 特点: Double 默认 64 位高精度，Float 性能好
- 建议: 默认用 Double；性能敏感或 C API 对齐用 Float
- 版本提示: 无

UI/图形浮点
- Swift: CGFloat
- ObjC: CGFloat
- 特点: 32 位平台为 Float，64 位为 Double
- 建议: UIKit/CoreGraphics 相关计算必须用 CGFloat
- 版本提示: 无

布尔
- Swift: Bool
- ObjC: BOOL
- 特点: Swift 类型安全；OC BOOL 本质是 signed char
- 建议: Swift 层统一 Bool；桥接自动转 YES/NO
- 版本提示: 无

十进制小数（金融）
- Swift: Decimal
- ObjC: NSDecimalNumber
- 特点: 十进制精度高，避免浮点误差
- 建议: 新代码用 Decimal；老 API 需要时用 NSDecimalNumber
- 版本提示: 无

随机数
- Swift: RandomNumberGenerator / Int.random(in:) / Double.random(in:)
- ObjC: arc4random 系列（C）
- 特点: Swift API 类型安全，支持范围
- 建议: 优先用 Swift 随机 API；遗留代码用 arc4random
- 版本提示: 无

二、文本与正则
────────────────────
字符串
- Swift: String
- ObjC: NSString / NSMutableString
- 特点: Swift 完整 Unicode/扩展字形簇；值语义；OC UTF-16，引用语义
- 建议: 统一用 String，桥接自动
- 版本提示: 无

字符集合
- Swift: CharacterSet
- ObjC: NSCharacterSet / NSMutableCharacterSet
- 特点: 类型安全，可组合操作
- 建议: 用 CharacterSet；桥接等价
- 版本提示: 无

正则表达式
- Swift: Regex / RegexBuilder（iOS16+）
- ObjC: NSRegularExpression
- 特点: Swift 类型安全，可组合
- 建议: iOS16+ 用 Swift Regex；早期系统用 NSRegularExpression
- 版本提示: Swift Regex 需 iOS16/macOS13+

富文本
- Swift: AttributedString（iOS15+）
- ObjC: NSAttributedString / NSMutableAttributedString
- 特点: Swift 值语义，类型安全
- 建议: 新文本构建用 AttributedString；与 UIKit 交互转换为 NSAttributedString
- 版本提示: iOS15+

三、容器与集合
────────────────────
数组
- Swift: Array<Element>
- ObjC: NSArray / NSMutableArray
- 特点: Swift 泛型、值语义；OC 引用语义、运行时类型不安全
- 建议: 统一 Array；桥接边界使用 NSArray
- 版本提示: 无

字典
- Swift: Dictionary<Key,Value>
- ObjC: NSDictionary / NSMutableDictionary
- 特点: Swift 类型安全，值语义；OC runtime 类型不安全
- 建议: 统一 Dictionary；桥接边界用 NSDictionary
- 版本提示: 无

集合
- Swift: Set<Element>
- ObjC: NSSet / NSMutableSet
- 特点: Swift 泛型、值语义；OC runtime 类型不安全
- 建议: 统一 Set；桥接边界用 NSSet
- 版本提示: 无

有序集合
- Swift: 无标准库等价
- ObjC: NSOrderedSet / NSMutableOrderedSet
- 特点: 保序 + 元素唯一
- 建议: 必须满足唯一+有序时使用；否则优先 Array/Set
- 版本提示: 无

计数集合
- Swift: 无标准库等价，可自建 [T:Int]
- ObjC: NSCountedSet
- 特点: 元素计数统计
- 建议: 需要“元素计数”时用
- 版本提示: 无

索引集合/索引路径
- Swift: IndexSet / IndexPath
- ObjC: NSIndexSet / NSIndexPath
- 特点: Swift 值语义；OC 引用语义
- 建议: 用 Swift 版本；桥接等价
- 版本提示: 无

四、二进制与缓冲
────────────────────
二进制数据
- Swift: Data
- ObjC: NSData / NSMutableData
- 特点: Swift 值语义、切片安全；OC 引用语义
- 建议: 统一 Data；与 C API 交互可取指针
- 版本提示: 无

字节缓冲/指针
- Swift: [UInt8], Unsafe(Mutable)Pointer<UInt8>
- C: unsigned char * / void *
- 特点: Swift 内存安全，可选 Unsafe 指针；OC 直接指针易崩溃
- 建议: 首选 Data/[UInt8]；仅底层 C API 使用指针
- 版本提示: 无

五、时间与本地化
────────────────────
日期/时间
- Swift: Date
- ObjC: NSDate
- 特点: Swift 值语义；OC 引用语义
- 建议: 统一 Date
- 版本提示: 无

日历/组件
- Swift: Calendar / DateComponents
- ObjC: NSCalendar / NSDateComponents
- 特点: Swift API 时区/历法安全
- 建议: 用 Swift API
- 版本提示: 无

时区/地区/语言
- Swift: TimeZone / Locale
- ObjC: NSTimeZone / NSLocale
- 特点: 类型安全
- 建议: Swift 版本
- 版本提示: 无

格式化器
- Swift/ObjC: DateFormatter / NumberFormatter / ByteCountFormatter / DateComponentsFormatter / MeasurementFormatter / ListFormatter / ISO8601DateFormatter
- 特点: Foundation 已 Swift 化
- 建议: 使用这些 Formatter，线程安全自行管理
- 版本提示: 无

六、URL / 网络
────────────────────
URL
- Swift: URL
- ObjC: NSURL
- 特点: Swift 值语义；OC 引用语义
- 建议: 统一 URL
- 版本提示: 无

URL 组件
- Swift: URLComponents / URLQueryItem
- ObjC: NSURLComponents / NSURLQueryItem
- 特点: 类型安全
- 建议: 用 URLComponents 构建/解析
- 版本提示: 无

请求/会话
- Swift: URLRequest / URLSession
- ObjC: NSURLRequest / NSMutableURLRequest / NSURLSession
- 建议: 统一 URLSession + URLRequest
- 版本提示: 无

七、文件系统与 Bundle
────────────────────
文件系统
- Swift: FileManager
- ObjC: NSFileManager
- 建议: 用 FileManager；路径建议 URL 而非 String

包资源
- Swift/ObjC: Bundle / NSBundle
- 建议: 用 Bundle；SwiftPM/资源包安全使用

八、通知 / KVO / Timer / 线程
────────────────────
通知中心
- Swift: NotificationCenter + Notification.Name
- ObjC: NSNotificationCenter + NSString
- 特点: Swift 类型安全；OC 字符串易错
- 建议: 用 Notification.Name 静态扩展避免拼写错误

KVO / KVC
- Swift: `@objc dynamic` 或 Observation (iOS17+)
- ObjC: KVO/KVC
- 建议: Swift 业务优先 Combine/async 序列或 Observation
- 版本提示: Observation iOS17+；低版本可用 Combine (iOS13+)

计时器
- Swift/ObjC: Timer / NSTimer
- 建议: 用 Timer.scheduledTimer；异步环境可用 DispatchSourceTimer

线程与并发
- Swift: async/await, Task, TaskGroup, actors (iOS15+)
- Swift/ObjC: DispatchQueue / OperationQueue
- 建议: iOS15+ 首选 async/await；其次 GCD；复杂依赖用 OperationQueue

九、用户默认（偏好）
────────────────────
UserDefaults
- Swift: UserDefaults
- ObjC: NSUserDefaults
- 特点: 类型化存取（bool(forKey:), integer(forKey:)…）
- 建议: 统一 UserDefaults.standard；键名封装为静态常量/枚举

十、序列化 / 编解码 / 归档
────────────────────
Codable
- Swift: Codable
- 建议: 优先 Codable + JSONEncoder/Decoder 或 PropertyListEncoder/Decoder

JSON 序列化
- Swift/ObjC: JSONSerialization
- 建议: 仅动态/轻量场合使用；结构化数据优先 Codable

Plist 序列化
- Swift/ObjC: PropertyListSerialization
- 建议: 与老格式互通时使用；更推荐 Codable + PropertyListEncoder

归档
- Swift/ObjC: NSKeyedArchiver / NSKeyedUnarchiver
- 建议: 与历史/OC 框架互通；新代码优先 Codable

十一、图形与几何
────────────────────
几何结构体
- Swift/C: CGPoint / CGSize / CGRect / CGVector / CGAffineTransform / UIEdgeInsets / UIOffset
- 建议: 直接使用对应结构体；需要存容器时由 NSValue 包裹

颜色/图片
- Swift/ObjC: UIColor / UIImage
- 建议: 平台统一；涉及 CoreGraphics 时注意色彩空间/位图

十二、桥接与 CoreFoundation
────────────────────
- Toll-Free Bridging: CFString ↔ NSString, CFData ↔ NSData, CFArray ↔ NSArray, CFDictionary ↔ NSDictionary, CFSet ↔ NSSet, CFURL ↔ NSURL
- 建议: Swift 层优先使用 Overlay 类型；Create/Copy 函数需配对释放

十三、错误处理模型
────────────────────
- Swift: Error + throw/try/catch
- ObjC: NSError**
- 建议: Swift 内部抛错；与 OC API 交互时转换为/从 NSError 还原

十四、任意类型与动态性
────────────────────
Any / AnyObject ↔ id
- 建议: 避免 Any；改用泛型/枚举/协议约束；仅边界层短暂使用

十五、UI 控件事件
────────────────────
Selector 与 @objc
- UIKit addTarget(_:action:for:) 依赖 ObjC selector
- 纯 Swift 写法:
  - iOS14+ 可用 UIAction / addAction，无需 @objc
  - iOS13− 方法需加 @objc 或封装闭包转 selector
 
 十六、Swift 独有（ObjC 无等价）
 ────────────────────
 可选类型
 - Swift: Optional<T> (T?)
 - ObjC: 无；仅对象可为 nil
 - 特点: Swift 类型系统级安全；ObjC 用 NSNull 代替集合中的空值
 - 建议: Swift 内部统一使用 Optional；跨语言注意 Optional ↔ NSNull

 元组
 - Swift: (Int, String)
 - ObjC: 无直接等价；常用 NSDictionary、NSArray 或自定义类代替
 - 建议: 仅 Swift 内部打包使用；跨语言时显式转换

 带关联值枚举
 - Swift: enum Foo { case a(Int), b(String) }
 - ObjC: 仅支持整型枚举 (NS_ENUM/NS_OPTIONS)
 - 建议: Swift 内部强类型枚举；与 ObjC 交互时桥接为整数或对象模型

 泛型
 - Swift: Array<T>, Dictionary<K,V>, Result<T,E>, 等
 - ObjC: 无真正泛型（泛型是编译器提示，运行时擦除）
 - 建议: Swift 内部统一泛型，ObjC 交互时降级为 id/NSArray/NSDictionary

 协议关联类型
 - Swift: protocol P { associatedtype T }
 - ObjC: @protocol P 仅方法约束
 - 建议: Swift 内部使用；跨语言用具体化协议代替

 Result 类型
 - Swift: Result<Success, Failure: Error>
 - ObjC: 无对应；一般回调 (id result, NSError *error)
 - 建议: Swift 内部用 Result；跨语言手动解包

 Never 类型
 - Swift: Never
 - ObjC: 无对应
 - 特点: 表示函数不会返回 (fatalError, 无限循环)
 - 建议: Swift 内部安全使用

 actor
 - Swift: actor (iOS15+)
 - ObjC: 无等价；可用 GCD/锁 模拟
 - 建议: Swift 并发环境推荐 actor

 结构化并发
 - Swift: async/await, Task, TaskGroup
 - ObjC: 无；传统 GCD 或 NSOperation
 - 建议: 新代码首选 async/await

 十七、ObjC 独有（Swift 无等价）
 ────────────────────
 NSInvocation
 - ObjC: NSInvocation
 - Swift: 无等价；受限于静态类型
 - 用途: 动态构造方法调用
 - 建议: 避免；Swift 层无法直接使用

 NSMethodSignature
 - ObjC: NSMethodSignature
 - Swift: 无等价
 - 用途: 动态方法签名检查

 NSProxy
 - ObjC: NSProxy
 - Swift: 无等价
 - 用途: 消息转发、动态代理（KVO、分布式对象）
 - 建议: Swift 层一般用协议+泛型实现代理

 isa / Runtime API
 - ObjC: class_getInstanceMethod, objc_msgSend, method_exchangeImplementations
 - Swift: 无等价；部分暴露于 ObjectiveC 模块
 - 建议: 仅在运行时黑魔法/调试工具中使用

 NSZone
 - ObjC: NSZone
 - Swift: 无等价
 - 用途: 内存分配器（已废弃）

 十七、UIKit / CoreGraphics 常用对照补充
 ────────────────────
 几何包装
 - Swift: NSValue(cgPoint:), NSValue(cgSize:), NSValue(cgRect:)
 - ObjC: NSValue
 - 建议: 存入容器时使用

 边距/Insets
 - Swift: NSDirectionalEdgeInsets (iOS11+)
 - ObjC: 无等价（仅 UIEdgeInsets）
 - 建议: 国际化布局用 NSDirectionalEdgeInsets

 颜色空间
 - Swift/ObjC: CGColor / UIColor
 - CoreGraphics: CGColorRef
 - 建议: UIKit 层用 UIColor，跨平台/底层渲染用 CGColor

 图像
 - Swift/ObjC: UIImage
 - CoreGraphics: CGImage
 - 建议: UIKit 层 UIImage；底层图像处理用 CGImage

 富媒体
 - Swift: NSTextAttachment
 - ObjC: NSTextAttachment
 - 建议: NSAttributedString 搭配使用

 十八、Foundation 扩展对照补充
 ────────────────────
 操作队列
 - Swift/ObjC: Operation / OperationQueue
 - ObjC: NSOperation / NSOperationQueue
 - 建议: 复杂依赖关系任务使用

 索引描述
 - Swift: IndexPath
 - ObjC: NSIndexPath
 - 桥接自动

 范围
 - Swift: Range<T>, ClosedRange<T>
 - ObjC: NSRange
 - 建议: Swift 内部 Range；桥接时需转换为 NSRange

 测量值
 - Swift: Measurement<Unit>
 - ObjC: NSMeasurement / NSUnit
 - 建议: Swift 内部 Measurement；ObjC 交互桥接

 通知标识
 - Swift: Notification.Name
 - ObjC: NSString
 - 建议: Swift 内部统一静态常量避免拼写错误

 十九、调试 / 标识符
 ────────────────────
 对象标识
 - Swift: ObjectIdentifier
 - ObjC: pointer 地址 或 NSObject.hash
 - 建议: Swift 层用 ObjectIdentifier 区分对象实例

 反射
 - Swift: Mirror
 - ObjC: runtime (class_copyPropertyList 等)
 - 建议: Swift 层轻量使用 Mirror；复杂反射仍依赖 ObjC runtime

 二十、内存管理 / 引用
 ────────────────────
 弱引用
 - Swift: weak / unowned
 - ObjC: __weak / __unsafe_unretained
 - 建议: 优先 weak；性能敏感时 unowned

 自动释放池
 - Swift: 无直接关键字
 - ObjC: @autoreleasepool
 - Swift 对应写法: autoreleasepool { … }
 - 建议: 大量临时对象时使用

 二十一、系统底层类型
 ────────────────────
 时间戳
 - Swift: TimeInterval (Double)
 - ObjC: NSTimeInterval (typedef double)
 - 建议: 统一 Double

 指针
 - Swift: UnsafePointer<T>, UnsafeMutablePointer<T>
 - ObjC(C): T * (C 指针)
 - 建议: Swift 内部尽量避免直接指针；与 C API 交互时使用

 选择子
 - Swift: Selector
 - ObjC: SEL
 - 建议: Swift 内部 Selector；桥接自动

 C 枚举/位掩码
 - Swift: OptionSet
 - ObjC: NS_OPTIONS
 - 特点: Swift 类型安全，支持集合操作
 - 建议: Swift 内部统一 OptionSet

 二十二、跨语言补充
 ────────────────────
 Block ↔ 闭包
 - Swift: () -> Void
 - ObjC: ^{ }
 - 注意: ObjC block 需 copy；Swift 闭包自动管理

 泛型类桥接
 - Swift: Array<T> ↔ NSArray
 - Swift: Dictionary<K,V> ↔ NSDictionary
 - Swift: Set<T> ↔ NSSet
 - 特点: 自动桥接但运行时类型检查不同
 - 建议: Swift 层优先泛型；跨语言时小心类型擦除

 NSNull
 - Swift: 无等价
 - ObjC: NSNull
 - 特点: 用于集合中表示“空值”
 - 建议: Swift 层判断时注意 Optional 与 NSNull 区分
 
 */
