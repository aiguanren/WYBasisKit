//
//  WYStorage.swift
//  WYBasisKit
//
//  Created by 官人 on 2021/10/18.
//  Copyright © 2021 官人. All rights reserved.
//

import Foundation
import UIKit

/// 数据缓存时长(有效期)
@frozen public enum WYStorageDurable {
    
    /// 缓存数据保持X分有效
    case minute(_ interval: TimeInterval)
    
    /// 缓存数据保持X小时有效
    case hour(_ interval: TimeInterval)
    
    /// 缓存数据保持X天有效
    case day(_ interval: TimeInterval)
    
    /// 缓存数据保持X周有效
    case week(_ interval: TimeInterval)
    
    /// 缓存数据保持X月有效
    case month(_ interval: TimeInterval)
    
    /// 缓存数据保持X年有效
    case year(_ interval: TimeInterval)
    
    /// 缓存数据无限时长有效
    case unlimited
}

/// 数据缓存对象
public struct WYStorageData: Codable {
    
    /// 存储的数据
    public var userData: Data?
    
    /// 存储有效时长(秒)
    public var durable: TimeInterval?
    
    /// 存入时间戳
    public var storageDate: TimeInterval?
    
    /// 是否超时过期
    public var isInvalid: Bool?
    
    /// 缓存路径
    public var path: URL?
    
    /// 报错提示
    public var error: String?
    
    public init(userData: Data? = nil, durable: TimeInterval? = nil, storageDate: TimeInterval? = nil, isInvalid: Bool? = nil, path: URL? = nil, error: String? = nil) {
        self.userData = userData
        self.durable = durable
        self.storageDate = storageDate
        self.isInvalid = isInvalid
        self.path = path
        self.error = error
    }
}

/// 缓存相关设置
public struct WYStorage {
    
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
    public static func storage(forKey key: String, data: Data, durable: WYStorageDurable = .unlimited, path: URL = createDirectory(directory: .cachesDirectory, subDirectory: "WYBasisKit/Memory")) -> WYStorageData {
        
        var storageData: WYStorageData = WYStorageData(userData: data, durable: interval(with: durable), isInvalid: false)
        
        guard key.count > 0 else {
            storageData.error = "本地存储时传入的 Key 不能为空"
            return storageData
        }
        
        if FileManager.default.fileExists(atPath: path.path) == false {
            
            guard let _ = try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil) else {
                
                storageData.error = "创建 \(path) 路径失败"
                return storageData
            }
        }
        
        let saveUrl: URL = path.appendingPathComponent(key)
        
        storageData.path = saveUrl
        
        storageData.storageDate = Date().timeIntervalSince1970
        
        guard let storageJson = try? JSONEncoder().encode(storageData) else {
            
            storageData.error = "\(storageData) 转换成 Data 类型失败"
            return storageData
        }
        
        guard let _ = try? storageJson.write(to: saveUrl) else {
            
            storageData.error = "\(storageJson) 写入 \(path) 路径失败"
            return storageData
        }
        return storageData
    }
    
    /// 根据Key获取对应的缓存数据
    public static func takeOut(forKey key: String, path: String = createDirectory(directory: .cachesDirectory, subDirectory: "WYBasisKit/Memory").path) -> WYStorageData {
        
        guard (key.count > 0) && (path.count > 0) else {
            return WYStorageData(path: URL(fileURLWithPath: path), error: "\(path) 路径不存在或者该路径下没有查找到相关资源")
        }
        
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: path) else {
            return WYStorageData(path: URL(fileURLWithPath: path), error: "\(path) 路径不存在或者该路径下没有查找到相关资源")
        }
        
        if contents.contains(key) {
            
            let contentPath: String = URL(fileURLWithPath: path).appendingPathComponent(key).path
            
            guard let storageJson: Data = FileManager.default.contents(atPath: contentPath) else {
                return WYStorageData(path: URL(string: path), error: "与 \(key) 对应的资源转换 Data 类型失败")
            }
            
            guard var storageData: WYStorageData = try? JSONDecoder().decode(WYStorageData.self, from: storageJson) else {
                
                return WYStorageData(path: URL(string: path), error: "与 \(key) 对应的资源转换成 WYMemoryData 类型失败")
            }
            
            let storageDate = storageData.storageDate!
            
            let currentDate = Date().timeIntervalSince1970
            
            let timeDifference = currentDate - storageDate
            
            let storageInterval: TimeInterval? = storageData.durable
            
            storageData.isInvalid = (storageInterval == nil) ? false : (timeDifference > storageInterval!)
            
            if storageData.isInvalid! {
                
                let formatter = DateFormatter()
                
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                let depositTime: String = formatter.string(from: Date(timeIntervalSince1970: storageDate))
                
                let expirationTime: String = formatter.string(from: Date(timeIntervalSince1970: storageDate + ((storageInterval == nil) ? 0 : storageInterval!)))
                
                clearMemory(forPath: path, asset: key)
                
                return WYStorageData(error: "上次存入的缓存文件 \(key) 已失效并自动清除，存入时间：\(depositTime)，失效时间：\(expirationTime)")
            }
            return storageData
            
        }else {
            return WYStorageData(path: URL(string: path), error: "没有找到与 \(key) 对应的资源")
        }
    }
    
    /**
     *  获取沙盒文件大小
     *
     *  @param path         要获取沙盒文件资源大小的路径，为空表示获取沙盒内所有 文件/文件夹的大小
     *
     */
    public static func sandboxSize(forPath path: String = "") -> CGFloat {
        
        if path.count <= 0 {
            
            let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first
            
            let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first
            
            return (folderSize(forPath: cachePath ?? "")) + (folderSize(forPath: documentPath ?? ""))
            
        }else {
            return folderSize(forPath: path)
        }
    }
    
    /// 计算沙盒内单个文件的大小
    public static func sandboxFileSize(forPath path: String) -> CGFloat {
        let manager = FileManager.default
        if manager.fileExists(atPath: path) {
            do {
                let attr = try manager.attributesOfItem(atPath: path)
                let size = attr[FileAttributeKey.size] as! CGFloat
                return size
            } catch  {
                return 0
            }
        }
        return 0
    }
    
    /// 创建一个指定目录/文件夹
    public static func createDirectory(directory: FileManager.SearchPathDirectory, subDirectory: String) -> URL {
        
        let directoryURLs = FileManager.default.urls(for: directory,
                                                        in: .userDomainMask)
        
        let savePath = (directoryURLs.first ?? URL(fileURLWithPath: NSTemporaryDirectory())).appendingPathComponent(subDirectory)
        let isExists: Bool = FileManager.default.fileExists(atPath: savePath.path)
        
        if !isExists {
            guard let _ = try? FileManager.default.createDirectory(at: savePath, withIntermediateDirectories: true, attributes: nil) else {
                fatalError("创建 \(savePath) 路径失败")
            }
        }
        return savePath
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
    public static func clearMemory(forPath path: String, asset: String = "", completion:((_ error: String?) -> Void)? = .none) {
        
        guard (path.count > 0) && (asset.count > 0) else {
            
            if completion != nil {
                completion!("\(path) 路径不存在或者该路径下没有需要清除的资源")
            }
            return
        }
        
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: path) else {
            
            if completion != nil {
                completion!("\(path) 路径不存在或者该路径下没有需要清除的资源")
            }
            return
        }
        
        if asset.isEmpty {
            
            for obj: String in contents {
                
                let contentPath: String = URL(fileURLWithPath: path).appendingPathComponent(obj).path
                
                guard let _ = try? FileManager.default.removeItem(atPath: contentPath) else {
                    
                    if completion != nil {
                        completion!("清除 \(obj) 资源失败")
                    }
                    return
                }
                if completion != nil {
                    completion!(nil)
                }
            }
            
        }else {
            
            if contents.contains(asset) {
                
                let contentPath: String = URL(fileURLWithPath: path).appendingPathComponent(asset).path
                
                guard let _ = try? FileManager.default.removeItem(atPath: contentPath) else {
                    
                    if completion != nil {
                        completion!("清除 \(asset) 资源失败")
                    }
                    return
                }
                if completion != nil {
                    completion!(nil)
                }
                return
                
            }else {
                if completion != nil {
                    completion!("没有找到 \(asset) 这个资源")
                }
                return
            }
        }
    }
}

public extension WYStorage {
    
    /// 存入时长转换成秒数，如果是无限有效，则返回nil
    static func interval(with durable: WYStorageDurable) ->TimeInterval? {
        
        switch durable {
            
        case .minute(let minute):
            return TimeInterval(((60 * minute)))
            
        case .hour(let hour):
            return TimeInterval(((60 * 60 * hour)))
            
        case .day(let day):
            return TimeInterval(((60 * 60 * 24 * day)))
            
        case .week(let week):
            return TimeInterval(((60 * 60 * 24 * 7 * week)))
            
        case .month(let month):
            return TimeInterval(((60 * 60 * 24 * 30 * month)))
            
        case .year(let year):
            return TimeInterval(((60 * 60 * 24 * 30 * 365 * year)))
            
        case .unlimited:
            return nil
        }
    }
    
    /// 遍历沙盒文件夹，返回大小
    private static func folderSize(forPath path: String) -> CGFloat {
        
        let manager = FileManager.default
        guard let files = manager.subpaths(atPath: path) else {
            return 0
        }
        var folderSize :CGFloat = 0
        for file in files {
            let filePath = path +  ("/\(file)")
            folderSize += sandboxFileSize(forPath:filePath)
        }
        return folderSize/(1024*1024)
    }
}
