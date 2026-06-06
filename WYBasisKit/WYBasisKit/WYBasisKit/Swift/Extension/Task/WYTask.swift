//
//  WYTask.swift
//  WYBasisKit
//
//  Created by guanren on 2026/6/6.
//

import Foundation

public extension Task where Success == Never, Failure == Never {

    /**
     可取消的延时任务

     - 功能：等待指定秒数，支持可选的取消行为控制和延时后的主线程操作。
     - 取消行为：
       - 若 `cancelThrows = true`，取消时会抛出 `CancellationError`。
       - 若 `cancelThrows = false`，取消时静默结束，不抛错误。
     - 注意：无论 `cancelThrows` 为何值，一旦取消，`onMain` 闭包都不会被执行（因为延时未完成）。

     - Parameters:
       - seconds: 延时的秒数。
       - cancelThrows: 取消时是否抛出错误，默认为 `true`。
       - onMain: 延时结束后在主线程执行的闭包（可选），仅当任务未取消且延时完成时才会执行。

     - Throws: 若 `cancelThrows = true` 且任务被取消，则抛出 `CancellationError`。

     - 使用场景:
       - `cancelThrows = true`：需要区分正常完成和取消（例如依赖取消状态做逻辑）。
       - `cancelThrows = false`：UI 动画、非关键延时，避免编写 `do-catch`。
       - 提供 `onMain`：延时后更新 UI，最常用写法：`cancelThrows: false, onMain: { ... }`。

     - 注意：取消时剩余等待时间会被跳过，不会“强行等够时间”。
     */
    static func wy_delay(
        _ seconds: Double,
        cancelThrows: Bool = true,
        onMain operation: (@MainActor () -> Void)? = nil
    ) async throws {
        do {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            // 延时完成后，若有主线程操作则执行
            if let operation = operation {
                await MainActor.run { operation() }
            }
        } catch {
            // 若取消且需要抛出错误，则抛出；否则静默
            if cancelThrows {
                throw error
            }
            // 取消且不需要抛出错误时，忽略 operation（不会执行）
        }
    }

    /**
     可主动取消的延时任务（返回 Task 句柄）

     - 功能：创建一个独立的延时任务，返回 `Task` 对象，可随时调用 `.cancel()` 取消。
     - 取消行为：被取消后，内部的 `operation` 闭包不会被执行。

     - Parameters:
       - seconds: 延时的秒数。
       - operation: 延时结束后执行的异步闭包（`@Sendable`）。

     - Returns: 可取消的 `Task<Void, Never>` 句柄。

     - 使用场景：需要单独控制一个延时操作的取消，例如“延迟跳转”或“延迟动画”，用户反悔时可取消。
     */
    @discardableResult
    static func wy_delayForTask(
        _ seconds: Double,
        operation: @escaping @Sendable () async -> Void
    ) -> Task<Void, Never> {
        return Task<Void, Never> {
            do {
                try await Task<Never, Never>.sleep(
                    nanoseconds: UInt64(seconds * 1_000_000_000)
                )
                // sleep 被取消时会直接抛错，因此这里无需再判断 isCancelled
                await operation()
            } catch {
                // 取消时什么都不做
            }
        }
    }
}

public extension Task {

    /**
     可取消的延时重试（带固定间隔）

     - 功能：执行操作，若失败则等待 `delay` 秒后重试，最多尝试 `numberOfRetries` 次（包含第一次尝试）。
     - 取消行为：若操作或等待期间任务被取消，立即抛出 `CancellationError`，不会继续重试。

     - Parameters:
       - delay: 每次失败后的等待秒数（重试间隔）。
       - numberOfRetries: 最大重试次数（包含第一次尝试）。
       - operation: 要执行的可抛出错误的异步操作（`@Sendable`）。

     - Returns: 操作成功时的返回值，类型为 `Success`。

     - Throws:
       - `CancellationError`：当任务被外部取消时。
       - 最后一次失败的错误：所有重试均失败时抛出最后一次捕获的错误。

     - 使用场景：网络请求、数据库操作等临时性失败，需要自动重试并带间隔。
     - 注意：这是一个异步延时任务，每次重试间隔通过 `sleep` 实现，可被取消。
     */
    static func wy_delayForRetry(
        _ delay: Double,
        numberOfRetries: Int,
        operation: @escaping @Sendable () async throws -> Success
    ) async throws -> Success {
        var lastError: Error?
        for attempt in 0..<numberOfRetries {
            do {
                return try await operation()
            } catch let error as CancellationError {
                throw error
            } catch {
                lastError = error
                if attempt < numberOfRetries - 1 {
                    try await Task<Never, Never>.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        throw lastError!
    }

    /**
     可取消的超时控制（带延时）

     - 功能：为异步任务设定最大执行时间 `seconds` 秒，若任务在指定时间内未完成，则抛出超时错误。
     - 取消行为：
       - 若任务在超时前被外部取消，会抛出 `CancellationError`。
       - 若超时发生，会抛出一个包含中文描述的 `NSError`（domain: "WYTask", code: -1, 描述: "任务执行超时"）。
       - 无论哪种失败，未完成的任务都会被自动取消。

     - Parameters:
       - seconds: 超时时间（秒）。
       - operation: 要执行的可抛出错误的异步操作（`@Sendable`）。

     - Returns: 操作成功时的返回值，类型为 `T`。

     - Throws:
       - `CancellationError`：任务被外部取消。
       - `NSError`：超时发生时抛出的自定义错误。

     - 使用场景：防止网络请求、长时间计算等操作卡死。
     - 注意：超时计时通过内部 `sleep` 实现，可被取消。
     */
    static func wy_delayForTimeout<T>(
        seconds: Double,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // 实际任务
            group.addTask {
                try await operation()
            }

            // 超时任务：抛出超时错误
            group.addTask {
                try await Task<Never, Never>.sleep(
                    nanoseconds: UInt64(seconds * 1_000_000_000)
                )
                throw NSError(
                    domain: "WYTask",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: WYLocalized("任务执行超时", table: WYBasisKitConfig.kitLocalizableTable)]
                )
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}
