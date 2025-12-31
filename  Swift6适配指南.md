# Swift 6 适配指南

## 目录

- Swift 版本设置
- 并发严格度模式
- 核心关键字速查
- 性能优化
- 向后兼容

## Swift 版本设置

### Xcode 中的 Swift 版本配置

#### 1. 项目级别设置

**位置**: Project → Build Settings → Swift Language Version

swift

```
// 在项目的 .xcconfig 文件中配置：
SWIFT_VERSION = 6.0

// 或者在 Podfile 中指定：
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '6.0'
    end
  end
end
```



#### 2. Target级别设置

**位置**: Target → Build Settings → Swift Language Version

swift

```
// 对于混合项目，可以不同目标使用不同版本：
// - Main App: Swift 6.0
// - Legacy Framework: Swift 5.0
// - New Feature Module: Swift 6.0
```



#### 3. 条件编译

swift

```
#if swift(>=6.0)
// Swift 6 专属代码
@MainActor
class Swift6ViewController: UIViewController {
    // ...
}
#elseif swift(>=5.5)
// Swift 5.5-5.10 代码  
class Swift55ViewController: UIViewController {
    @available(iOS 13.0, *)
    func useConcurrency() async {
        // ...
    }
}
#else
// Swift 5.4 及以下
class LegacyViewController: UIViewController {
    // 传统实现
}
#endif
```



## 并发严格度模式

### 严格度级别详解

#### 1. Minimal 模式

**设置方式**:

bash

```
# 在 Build Settings 中：
SWIFT_STRICT_CONCURRENCY = minimal

# 或在 Package.swift 中：
.swiftSettings([
    .enableUpcomingFeature("StrictConcurrency"),
    .unsafeFlags(["-Xfrontend", "-strict-concurrency=minimal"])
])
```



**行为特点**:

swift

```
// ✅ 允许的代码
class MinimalExample {
    var data: [String] = []  // 无 Sendable 警告
    
    func updateData() {
        // 可以自由修改，无并发检查
        data.append("new item")
    }
}

// ❌ 仍然会警告的情况
class Problematic {
    @MainActor var mainData: String = ""
    
    func updateFromBackground() {
        // 会警告：@MainActor 属性在非主线程访问
        // mainData = "updated" 
    }
}
```



**适用场景**:

- 迁移初期
- 大型遗留代码库
- 需要逐步迁移的项目

#### 2. Targeted 模式

**设置方式**:

bash

```
SWIFT_STRICT_CONCURRENCY = targeted
```



**行为特点**:

swift

```
// ✅ 对标记了 @MainActor, @Sendable 的代码进行严格检查
@MainActor
class TargetedExample {
    var uiData: String = ""  // 受 MainActor 保护
    
    func updateUI() {
        uiData = "updated"  // 安全，在主线程
    }
}

// ❌ 会警告的情况
class NonSendable {
    var data: [String] = []
}

Task.detached {
    let instance = NonSendable()  // 警告：NonSendable 不符合 Sendable
    instance.data.append("test")
}
```



**检查范围**:

- 显式标记为 `@MainActor`、`@globalActor` 的代码
- 显式标记为 `@Sendable` 的闭包
- 跨隔离域的类型传递

#### 3. Complete 模式

**设置方式**:

bash

```
SWIFT_STRICT_CONCURRENCY = complete
```



**行为特点**:

swift

```
// ✅ 必须完全符合 Sendable
final class CompleteExample: Sendable {
    let immutableData: String
    var mutableButSafe: [String]  // 警告！数组不是线程安全的
    
    init(data: String) {
        immutableData = data
        mutableButSafe = []
    }
}

// ❌ 严格检查所有潜在的并发问题
class Suspicious {
    var counter = 0
    
    func increment() {
        counter += 1  // 警告：可能的数据竞争
    }
}
```



**检查项目**:

- 所有跨并发域的类型必须符合 `Sendable`
- 所有共享可变状态必须有适当的保护
- 所有全局变量必须符合 `Sendable`

### 模式选择建议

| 模式       | 严格度 | 编译时间 | 迁移难度 | 适用阶段 |
| :--------- | :----- | :------- | :------- | :------- |
| `minimal`  | 低     | 快       | 易       | 开始迁移 |
| `targeted` | 中     | 中等     | 中等     | 中期迁移 |
| `complete` | 高     | 慢       | 难       | 迁移完成 |

## 核心关键字速查

### 并发隔离关键字

#### @MainActor

**作用**: 确保代码在主线程执行
**替代**: `DispatchQueue.main.async`

swift

```
@MainActor
class ViewController: UIViewController {
    @IBOutlet weak var label: UILabel!
    
    func updateUI() {
        label.text = "Updated"  // 自动在主线程
    }
}

// 单个方法标记
class MixedClass {
    @MainActor func updateOnMain() {
        // 保证在主线程执行
    }
    
    func backgroundWork() {
        // 可以在任何线程
    }
}
```



#### actor

**作用**: 保护共享状态，防止数据竞争
**替代**: 手动锁、串行队列

swift

```
actor BankAccount {
    private var balance: Double = 0
    
    func deposit(_ amount: Double) {
        balance += amount
    }
    
    func withdraw(_ amount: Double) async -> Bool {
        guard balance >= amount else { return false }
        balance -= amount
        return true
    }
    
    var currentBalance: Double {
        balance  // 只读属性不需要 await
    }
}
```



#### @globalActor

**作用**: 创建全局隔离域

swift

```
@globalActor
actor DatabaseActor {
    static let shared = DatabaseActor()
}

@DatabaseActor
class DataRepository {
    private var cache: [String: Any] = [:]
    
    func store(_ value: Any, for key: String) {
        cache[key] = value
    }
}
```



### 异步编程关键字

#### async

**作用**: 标记异步函数
**替代**: 回调闭包

swift

```
// 传统回调
func fetchData(completion: @escaping (Result<Data, Error>) -> Void)

// async 版本
func fetchData() async throws -> Data
```



#### await

**作用**: 等待异步操作完成
**替代**: 回调嵌套

swift

```
func loadUserData() async {
    do {
        let user = try await fetchUser()
        let profile = try await fetchProfile(userId: user.id)
        await updateUI(user: user, profile: profile)
    } catch {
        await handleError(error)
    }
}
```



#### Task

**作用**: 创建和管理异步任务
**替代**: `DispatchQueue`, `OperationQueue`

swift

```
// 基本任务
Task {
    let data = await fetchData()
    await updateUI(with: data)
}

// 带优先级的任务
Task(priority: .high) {
    await processUrgentData()
}

// 分离任务（不继承上下文）
Task.detached {
    await heavyProcessing()
}
```



### 数据安全关键字

#### Sendable

**作用**: 标记可以在并发域间安全传递的类型

swift

```
// 自动符合 Sendable 的情况
struct User: Sendable {
    let id: String
    let name: String
}

final class Config: Sendable {
    let version: String
    init(version: String) { self.version = version }
}

// 手动实现 Sendable
final class ThreadSafeCache: @unchecked Sendable {
    private var storage: [String: Any] = [:]
    private let lock = NSLock()
    
    func set(_ value: Any, for key: String) {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = value
    }
}
```



#### nonisolated

**作用**: 在 actor 中声明不访问隔离状态的方法

swift

```
actor DataProcessor {
    private var processedCount = 0
    
    func process(_ data: Data) {
        // 访问隔离状态
        processedCount += 1
    }
    
    nonisolated var processorId: String {
        // 不访问隔离状态
        return "DataProcessor-\(UUID().uuidString)"
    }
}
```



### 任务管理关键字

#### TaskGroup

**作用**: 管理一组相关任务

swift

```
func processMultipleFiles(_ urls: [URL]) async throws -> [Data] {
    try await withThrowingTaskGroup(of: Data.self) { group in
        for url in urls {
            group.addTask {
                return try await processFile(at: url)
            }
        }
        
        var results: [Data] = []
        for try await result in group {
            results.append(result)
        }
        return results
    }
}
```



#### withCheckedContinuation

**作用**: 将回调代码转换为 async/await

swift

```
func asyncOperation() async -> String {
    return await withCheckedContinuation { continuation in
        legacyCallbackOperation { result in
            continuation.resume(returning: result)
        }
    }
}
```

## 实战示例

### @MainActor 示例

swift

```
// 迁移前
class OldViewController: UIViewController {
    func updateData() {
        DispatchQueue.main.async {
            self.titleLabel.text = "New Title"
            self.tableView.reloadData()
        }
    }
}

// 迁移后  
@MainActor
class NewViewController: UIViewController {
    func updateData() {
        titleLabel.text = "New Title"
        tableView.reloadData()  // 自动在主线程
    }
    
    // 从后台更新 UI 的安全方式
    func fetchAndUpdate() async {
        let data = await fetchData()  // 在后台执行
        updateUI(with: data)          // 自动切回主线程
    }
}
```



### actor 示例

swift

```
// 迁移前 - 手动线程安全
class ThreadSafeCounter {
    private var count = 0
    private let queue = DispatchQueue(label: "counter.queue")
    
    func increment() {
        queue.async(flags: .barrier) {
            self.count += 1
        }
    }
    
    func getValue(completion: @escaping (Int) -> Void) {
        queue.async {
            completion(self.count)
        }
    }
}

// 迁移后 - Actor 自动安全
actor SafeCounter {
    private var count = 0
    
    func increment() {
        count += 1
    }
    
    func getValue() -> Int {
        return count
    }
}

// 使用示例
class CounterManager {
    let counter = SafeCounter()
    
    func performIncrements() async {
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<1000 {
                group.addTask {
                    await self.counter.increment()
                }
            }
        }
        
        let finalCount = await counter.getValue()
        print("Final count: \(finalCount)")  // 保证是 1000
    }
}
```



### async/await 示例

swift

```
// 迁移前 - 回调地狱
func loadUserDashboard(completion: @escaping (Result<Dashboard, Error>) -> Void) {
    loadUserProfile { profileResult in
        switch profileResult {
        case .success(let profile):
            self.loadUserSettings(userId: profile.id) { settingsResult in
                switch settingsResult {
                case .success(let settings):
                    self.loadUserFriends(userId: profile.id) { friendsResult in
                        // 更多嵌套...
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }
}

// 迁移后 - 线性异步代码
func loadUserDashboard() async throws -> Dashboard {
    // 并行加载所有数据
    async let profile = loadUserProfile()
    async let settings = loadUserSettings()
    async let friends = loadUserFriends()
    
    // 等待所有结果
    return try await Dashboard(
        profile: profile,
        settings: settings, 
        friends: friends
    )
}
```



### Task 示例

swift

```
// 各种 Task 使用场景
class TaskExamples {
    
    // 1. 简单后台任务
    func startBackgroundWork() {
        Task {
            let result = await performHeavyCalculation()
            await updateUI(with: result)
        }
    }
    
    // 2. 带取消的任务
    func startCancellableWork() {
        let task = Task {
            for i in 0..<100 {
                try Task.checkCancellation()  // 检查取消
                await processStep(i)
            }
        }
        
        // 稍后取消
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            task.cancel()
        }
    }
    
    // 3. 超时任务
    func startWithTimeout() async throws -> Data {
        try await withThrowingTaskGroup(of: Data.self) { group in
            group.addTask {
                return try await fetchData()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: 10_000_000_000)  // 10秒
                throw TimeoutError()
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}
```



### TaskGroup 示例

swift

```
// 批量处理文件
actor FileProcessor {
    func processFiles(_ urls: [URL]) async throws -> [ProcessedFile] {
        try await withThrowingTaskGroup(of: ProcessedFile.self) { group in
            // 添加所有处理任务
            for url in urls {
                group.addTask {
                    let data = try Data(contentsOf: url)
                    return try await processFileData(data)
                }
            }
            
            // 收集结果
            var results: [ProcessedFile] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }
}

// 限制并发数量
actor LimitedConcurrencyProcessor {
    private let semaphore: AsyncSemaphore
    
    init(maxConcurrent: Int) {
        self.semaphore = AsyncSemaphore(value: maxConcurrent)
    }
    
    func processWithLimit(_ items: [Processable]) async -> [Result] {
        await withTaskGroup(of: Result.self) { group in
            for item in items {
                group.addTask {
                    await self.semaphore.wait()
                    defer { self.semaphore.signal() }
                    
                    return await processItem(item)
                }
            }
            
            var results: [Result] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }
}
```

## 性能优化

### Actor 性能优化

#### 1. 减少隔离开销

swift

```
// ❌ 性能差的实现
actor InefficientProcessor {
    private var data: [String] = []
    
    func processAll() async -> [String] {
        var results: [String] = []
        for item in data {
            // 每次循环都切换 Actor
            let result = await processItem(item)
            results.append(result)
        }
        return results
    }
}

// ✅ 优化后的实现  
actor EfficientProcessor {
    private var data: [String] = []
    
    func processAll() async -> [String] {
        // 批量处理，减少切换
        return await withTaskGroup(of: String.self) { group in
            for item in data {
                group.addTask {
                    return await self.processItem(item)
                }
            }
            
            var results: [String] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }
}
```



#### 2. 合理使用 nonisolated

swift

```
actor DataManager {
    private var cache: [String: Data] = [:]
    private let config: AppConfig
    
    init(config: AppConfig) {
        self.config = config
    }
    
    // 需要隔离 - 访问 cache
    func getData(for key: String) -> Data? {
        return cache[key]
    }
    
    // 不需要隔离 - 只访问 config
    nonisolated var appVersion: String {
        return config.version
    }
    
    // 不需要隔离 - 纯计算
    nonisolated func generateId() -> String {
        return UUID().uuidString
    }
}
```



### 内存管理优化

#### 1. 使用 AsyncStream 处理流数据

swift

```
class MemoryEfficientLoader {
    func loadLargeDataset() -> AsyncStream<DataChunk> {
        AsyncStream { continuation in
            Task {
                let stream = openDataStream()
                defer {
                    stream.close()
                    continuation.finish()
                }
                
                while let chunk = try? stream.nextChunk() {
                    continuation.yield(chunk)
                    
                    // 定期让出控制权，避免阻塞
                    await Task.yield()
                    
                    if Task.isCancelled {
                        break
                    }
                }
            }
        }
    }
}
```



#### 2. 避免意外强引用

swift

```
actor ImageCache {
    private var storage: [String: UIImage] = [:]
    
    func cacheImage(_ image: UIImage, for key: String) {
        storage[key] = image
    }
    
    func clearCache() {
        storage.removeAll()
    }
    
    // 使用弱引用避免循环引用
    nonisolated weak var delegate: CacheDelegate?
}
```



## 向后兼容

### 多版本 Swift 支持

#### 1. 条件编译策略

swift

```
// 并发特性可用性检查
#if swift(>=6.0)
// Swift 6 专属特性
@MainActor
public class Swift6Component {
    public func modernMethod() async -> String {
        return "Swift 6 Implementation"
    }
}

#elseif swift(>=5.5) && canImport(_Concurrency)
// Swift 5.5-5.10 实现
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public class Swift55Component {
    public func modernMethod() async -> String {
        return "Swift 5.5 Implementation"
    }
}

#else
// Swift 5.4 及以下传统实现
public class LegacyComponent {
    public func traditionalMethod(completion: @escaping (String) -> Void) {
        DispatchQueue.global().async {
            let result = self.legacyWork()
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}
#endif
```



#### 2. 渐进式 API 设计

swift

```
public class MigrationFriendlyAPI {
    private let implementation: APIImplementation
    
    // 现代 async 接口
    @available(macOS 10.15, iOS 13.0, *)
    public func fetchData() async throws -> Data {
        #if swift(>=5.5)
        return try await implementation.fetchDataModern()
        #else
        return try await withCheckedThrowingContinuation { continuation in
            implementation.fetchDataTraditional { result in
                continuation.resume(with: result)
            }
        }
        #endif
    }
    
    // 传统回调接口（用于向后兼容）
    public func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
        #if swift(>=5.5) && canImport(_Concurrency)
        if #available(macOS 10.15, iOS 13.0, *) {
            Task {
                do {
                    let data = try await fetchData()
                    completion(.success(data))
                } catch {
                    completion(.failure(error))
                }
            }
            return
        }
        #endif
        
        // 传统实现
        implementation.fetchDataTraditional(completion: completion)
    }
}
```



### Objective-C 兼容性

#### 1. 桥接层设计

swift

```
@objc public class OCBridge: NSObject {
    private let swiftCore = SwiftCore()
    
    @objc public static let shared = OCBridge()
    
    // Objective-C 友好接口
    @objc public func processUserData(_ data: NSData, 
                                    completion: @escaping (NSData?, Error?) -> Void) {
        Task {
            do {
                let userData = try JSONDecoder().decode(UserData.self, from: data as Data)
                let result = try await swiftCore.processUserData(userData)
                let resultData = try JSONEncoder().encode(result)
                completion(resultData as NSData, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    // 避免暴露 Swift 专属类型
    @objc public func getConfiguration(completion: @escaping ([String: Any]?, Error?) -> Void) {
        Task {
            do {
                let config = try await swiftCore.getConfiguration()
                let dict: [String: Any] = [
                    "version": config.version,
                    "build": config.buildNumber
                ]
                completion(dict, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
}
```



#### 2. 选择性暴露

swift

```
// 只暴露必要的接口给 Objective-C
@objc public class OCVisibleClass: NSObject {
    private let hiddenActor = HiddenActor()
    
    @objc public func performWork(completion: @escaping (Bool) -> Void) {
        Task {
            let success = await hiddenActor.doWork()
            completion(success)
        }
    }
}

// 这个 Actor 对 Objective-C 不可见
actor HiddenActor {
    func doWork() async -> Bool {
        // 复杂的 Swift 并发逻辑
        return true
    }
}
```