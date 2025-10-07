//
//  WYStorageObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/10/5.
//

import Foundation
import UIKit

/// 数据缓存时长(有效期)
@objc(WYStorageDurable)
@frozen public enum WYStorageDurableObjC: Int {
    
    /// 缓存数据保持X分有效
    case minute = 0
    
    /// 缓存数据保持X小时有效
    case hour
    
    /// 缓存数据保持X天有效
    case day
    
    /// 缓存数据保持X周有效
    case week
    
    /// 缓存数据保持X月有效
    case month
    
    /// 缓存数据保持X年有效
    case year
    
    /// 缓存数据无限时长有效
    case unlimited
}

/// 数据缓存对象
@objc(WYStorageData)
@objcMembers public class WYStorageDataObjC: NSObject, Codable {
    
    /// 存储的数据
    @objc public var userData: Data?
    
    /// 存储有效时长(秒)
    @objc public var durable: TimeInterval
    
    /// 存入时间戳
    @objc public var storageDate: TimeInterval
    
    /// 是否超时过期
    @objc public var isInvalid: Bool
    
    /// 缓存路径
    @objc public var path: URL?
    
    /// 报错提示
    @objc public var error: String?
    
    @objc public init(userData: Data? = nil, durable: TimeInterval = 0, storageDate: TimeInterval = 0, isInvalid: Bool = false, path: URL? = nil, error: String? = nil) {
        self.userData = userData
        self.durable = durable
        self.storageDate = storageDate
        self.isInvalid = isInvalid
        self.path = path
        self.error = error
    }
    
    // 转换WYStorageData为WYStorageDataObjC(内部使用)
    static func wy_swiftConvertToObjC(storageData: WYStorageData) -> WYStorageDataObjC {
        return WYStorageDataObjC(userData: storageData.userData, durable: storageData.durable ?? 0, storageDate: storageData.storageDate ?? 0, isInvalid: storageData.isInvalid ?? false, path: storageData.path, error: storageData.error)
    }
}

/// 缓存相关设置
@objc(WYStorage)
@objcMembers public class WYStorageObjC: NSObject {
    
    /*
     沙河目录简介
     
     - 1、Home(应用程序包)目录
     - 整个应用程序文档所在的目录,包含了所有的资源文件和可执行文件
     
     
     - 2、Documents
     - 保存应用运行时生成的需要持久化的数据，iTunes同步设备时会备份该目录
     - 需要保存由"应用程序本身"产生的文件或者数据，例如: 游戏进度，涂鸦软件的绘图
     - 目录中的文件会被自动保存在 iCloud
     - 注意: 不要保存从网络上下载的文件，否则会无法上架!
     
     
     - 3、Library
     - 该目录下有两个子目录：Caches 和 Preferences
     
     - 3.1、Library/Cache
     - 保存应用运行时生成的需要持久化的数据，iTunes同步设备时不会备份该目录。一般存放体积大、不需要备份的非重要数据
     - 保存临时文件,"后续需要使用"，例如: 缓存的图片，离线数据（地图数据）
     - 系统不会清理 cache 目录中的文件
     - 就要求程序开发时, "必须提供 cache 目录的清理解决方案"
     
     - 3.2、Library/Preference
     - 保存应用的所有偏好设置，IOS的Settings应用会在该目录中查找应用的设置信息。iTunes
     - 用户偏好，直接使用 NSUserDefault 读写！
     - 如果想要数据及时写入硬盘，还需要调用一个同步方法
     
     - 4、tmp
     - 用于存放临时文件，保存应用程序启动过程中不再需要使用的信息
     - 重启后会被系统自动清空。
     - 系统磁盘空间不足时，系统也会自动清理
     - 保存应用运行时所需要的临时数据，使用完毕后再将相应的文件从该目录删除。应用没有运行，系统也可能会清除该目录下的文件，iTunes不会同步备份该目录
     */
    
    /// 根据传入的Key将数据缓存到本地
    @discardableResult
    @objc public static func storage(forKey key: String, data: Data, durable: WYStorageDurableObjC = .unlimited, interval: TimeInterval, path: URL? = nil) -> WYStorageDataObjC {
        
        // 保证默认路径只在 path 为空时生成
        let realPath = path ?? createDirectory(directory: .cachesDirectory, subDirectory: "WYBasisKit/Memory")
        
        // 转换成 Swift 内部可识别的 durable
        let swiftDurable: WYStorageDurable
        switch durable {
        case .minute: swiftDurable = .minute(interval)
        case .hour: swiftDurable = .hour(interval)
        case .day: swiftDurable = .day(interval)
        case .week: swiftDurable = .week(interval)
        case .month: swiftDurable = .month(interval)
        case .year: swiftDurable = .year(interval)
        case .unlimited: swiftDurable = .unlimited
        }
        
        let storageData: WYStorageData = WYStorage.storage(forKey: key, data: data, durable: swiftDurable, path: realPath)
        
        return WYStorageDataObjC.wy_swiftConvertToObjC(storageData: storageData)
    }
    
    /// 根据Key获取对应的缓存数据
    @objc public static func takeOut(forKey key: String, path: String? = nil) -> WYStorageDataObjC {
        
        // 保证默认路径只在 path 为空时生成
        let realPath = path ?? createDirectory(directory: .cachesDirectory, subDirectory: "WYBasisKit/Memory").path
        
        let storageData: WYStorageData = WYStorage.takeOut(forKey: key, path: realPath)
        
        return WYStorageDataObjC.wy_swiftConvertToObjC(storageData: storageData)
    }
    
    /**
     *  获取沙盒文件大小
     *
     *  @param path         要获取沙盒文件资源大小的路径，为空表示获取沙盒内所有 文件/文件夹的大小
     *
     */
    @objc public static func sandboxSize(forPath path: String = "") -> CGFloat {
        return WYStorage.sandboxSize(forPath: path)
    }
    
    /// 计算沙盒内单个文件的大小
    @objc public static func sandboxFileSize(forPath path: String) -> CGFloat {
        return WYStorage.sandboxFileSize(forPath: path)
    }
    
    /// 创建一个指定目录/文件夹
    @objc public static func createDirectory(directory: FileManager.SearchPathDirectory, subDirectory: String) -> URL {
        return WYStorage.createDirectory(directory: directory, subDirectory: subDirectory)
    }
    
    /**
     *  清除缓存
     *
     *  @param path         要清除的资源的路径
     *
     *  @param asset        为空表示清除传入 path 下所有资源，否则表示清除传入 path 下对应 asset 的指定资源
     *
     *  @param complte      完成后回调，error 为空表示成功，否则为失败
     *
     */
    @objc public static func clearMemory(forPath path: String, asset: String = "", completion:((_ error: String?) -> Void)? = .none) {
        return WYStorage.clearMemory(forPath: path, asset: asset, completion: completion)
    }
}
