//
//  WYNetworkManager+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import Foundation
import UIKit
import Moya
import Network
import Alamofire

extension WYNetworkManager {
    
    /// 网络连接模式与用户操作选项
    private enum NetworkStatus {
        
        /// 未知网络，可能是不安全的连接
        case unknown
        /// 无网络连接
        case notReachable
        /// wifi网络
        case reachableWifi
        /// 蜂窝移动网络
        case reachableCellular
        
        /// 用户未选择
        case userNotSelectedConnect
        /// 用户设置取消连接
        case userCancelConnect
        /// 用户设置继续连接
        case userContinueConnect
    }
    
    private static var networkSecurityInfo = (NetworkStatus.userNotSelectedConnect, "")
    
    static func request(method: HTTPMethod, path: String, data: Data?, config: WYNetworkConfig = .default, parameter: [String : Any], files: [WYFileModel], assetName: String = "", handler:((_ result: WYHandler) -> Void)?) {
        
        if config.taskMethod == .data && data == nil {
            handlerFailure(error: WYError(code: config.unpackServerFailCode, describe: WYLocalized("数据请求失败", table: WYBasisKitConfig.kitLocalizableTable)), debugModeLog: config.debugModeLog, handler: handler)
            return
        }
        if config.taskMethod == .upload {
            for file in files {
                let valid = file.fileType == .urlPath ? FileManager.default.isReadableFile(atPath: WYTarget.fileURL(for: file.fileUrl).path) : file.data != nil
                guard valid else {
                    handlerFailure(error: WYError(code: config.unpackServerFailCode, describe: WYLocalized("数据请求失败", table: WYBasisKitConfig.kitLocalizableTable)), debugModeLog: config.debugModeLog, handler: handler)
                    return
                }
            }
        }
        let request = WYRequest(method: method, path: path, data: data, parameter: parameter, files: files, assetName: assetName, config: config)
        let target = WYTarget(request: request)
        guard let scheme = target.baseURL.scheme?.lowercased(), ["http", "https"].contains(scheme),
              target.baseURL.host != nil, target.baseURL != WYTarget.invalidDomainURL else {
            let error = URLError(.badURL)
            handlerFailure(error: WYError(code: String(error.code.rawValue), describe: error.localizedDescription), debugModeLog: config.debugModeLog, handler: handler)
            return
        }
        let provider: MoyaProvider<WYTarget>
        do {
            var providerConfig = config
            if providerConfig.domain.isEmpty { providerConfig.domain = path }
            provider = try WYProviderConfig<WYTarget>.provider(config: providerConfig)
        } catch {
            handlerFailure(error: WYError(code: config.networkServerFailCode, describe: error.localizedDescription), debugModeLog: config.debugModeLog, handler: handler)
            return
        }
        let url = config.domain.isEmpty ? path : config.domain + path
        let requestID = WYNetworkRequestRegistry.shared.register(provider: provider, url: url) {
            let error = URLError(.cancelled)
            handlerFailure(error: WYError(code: String(error.code.rawValue), describe: error.localizedDescription), debugModeLog: config.debugModeLog, handler: handler)
        }
        checkNetworkStatus { statusInfo in
            guard WYNetworkRequestRegistry.shared.isActive(requestID) else { return }
            if statusInfo.0 == .userCancelConnect {
                _ = WYNetworkRequestRegistry.shared.finish(requestID)
                handlerFailure(error: WYError(code: config.networkServerFailCode, describe: statusInfo.1), debugModeLog: config.debugModeLog, handler: handler)
            } else {
                self.request(target: target, config: config, provider: provider, requestID: requestID, handler: handler)
            }
        }
    }

    private static func request(target: WYTarget, config: WYNetworkConfig, provider: MoyaProvider<WYTarget>, requestID: UUID, handler:((_ result: WYHandler) -> Void)?) {
        
        if config.requestCache != nil {
            
            if config.requestCache!.cacheKey.count > 0 {
                
                let storageData = WYStorage.takeOut(forKey: config.requestCache!.cacheKey, path: config.requestCache!.cachePath.path)
                
                if (storageData.error == nil) && (handler != nil) && (storageData.userData != nil)  {
                    
                    if (config.originObject == true) {
                        handler!(.success(WYSuccess(origin: String(data: storageData.userData!, encoding: .utf8) ?? "", storage: storageData, isCache: true)))
                    }else {
                        handler!(.success(WYSuccess(parse: String(data: storageData.userData!, encoding: .utf8) ?? "", storage: storageData, isCache: true)))
                    }
                }
                
            }else {
                wy_networkPrint("由于传入的用于缓存的唯一标识 cacheKey 为空，本次请求不会被缓存")
            }
        }
        
        guard WYNetworkRequestRegistry.shared.isActive(requestID) else { return }
        let cancellable = provider.request(target, callbackQueue: config.callbackQueue) { (progressResponse) in
            
            if WYNetworkRequestRegistry.shared.isActive(requestID), handler != nil {

                handler!(.progress(WYProgress(progress: progressResponse.progress, completedUnit: progressResponse.progressObject?.completedUnitCount ?? 0, totalUnit: progressResponse.progressObject?.totalUnitCount ?? 0, description: progressResponse.progressObject?.description ?? "")))
            }
            
        } completion: { result in
            defer {
                if config.taskMethod == .download { try? FileManager.default.removeItem(at: target.request.downloadStagingURL) }
            }
            guard let wasCancelled = WYNetworkRequestRegistry.shared.finish(requestID) else { return }
            if wasCancelled {
                let error = URLError(.cancelled)
                handlerFailure(error: WYError(code: String(error.code.rawValue), describe: error.localizedDescription), debugModeLog: config.debugModeLog, handler: handler)
                return
            }
            switch result {
                
            case .success(let response):
                guard config.acceptableStatusCodes.contains(response.statusCode) else {
                    handlerFailure(error: WYError(code: String(response.statusCode), describe: WYLocalized("状态码异常", table: WYBasisKitConfig.kitLocalizableTable)), isStatusCodeError: true, debugModeLog: config.debugModeLog, handler: handler)
                    return
                }
                if config.taskMethod == .download {
                    
                    guard let urlResponse = response.response else {
                        handlerFailure(error: WYError(code: config.unpackServerFailCode, describe: URLError(.badServerResponse).localizedDescription), debugModeLog: config.debugModeLog, handler: handler)
                        return
                    }
                    let saveUrl = WYTarget.downloadURL(for: target.request, response: urlResponse)
                    let format = saveUrl.pathExtension
                    do {
                        try FileManager.default.createDirectory(at: saveUrl.deletingLastPathComponent(), withIntermediateDirectories: true)
                        if FileManager.default.fileExists(atPath: saveUrl.path) {
                            guard config.removeSameNameFile else { throw CocoaError(.fileWriteFileExists) }
                            _ = try FileManager.default.replaceItemAt(saveUrl, withItemAt: target.request.downloadStagingURL)
                        } else {
                            try FileManager.default.moveItem(at: target.request.downloadStagingURL, to: saveUrl)
                        }
                    } catch {
                        handlerFailure(error: WYError(code: config.unpackServerFailCode, describe: error.localizedDescription), debugModeLog: config.debugModeLog, handler: handler)
                        return
                    }
                    showDebugModeLog(target: target, response: response, saveUrl: saveUrl)
                    
                    var downloadModel = WYDownloadModel()
                    downloadModel.assetPath = saveUrl.path
                    downloadModel.diskPath = config.downloadSavePath.path
                    downloadModel.assetName = (target.request.assetName.isEmpty ? (response.response?.suggestedFilename ?? "") : target.request.assetName)
                    downloadModel.mimeType = format
                    
                    let codable: WYCodable = WYCodable()
                    let jsonString = try? codable.encode(String.self, from: downloadModel)
                    handlerSuccess(response: WYSuccess(origin: jsonString ?? ""), handler: handler)
                }else {
                    
                    let statusCode = response.statusCode
                    
                    if !config.acceptableStatusCodes.contains(statusCode) {
                        
                        showDebugModeLog(target: target, response: response)
                        
                        handlerFailure(error: WYError(code: String(statusCode), describe: WYLocalized("状态码异常", table: WYBasisKitConfig.kitLocalizableTable)), isStatusCodeError: true, debugModeLog: config.debugModeLog, handler: handler)
                        
                    }else {
                        
                        var storage: WYStorageData? = nil
                        
                        if config.originObject || response.data.isEmpty {
                            
                            if (config.requestCache != nil) && (config.requestCache!.cacheKey.count > 0) {
                                
                                storage = WYStorage.storage(forKey: config.requestCache!.cacheKey, data: response.data, durable: config.requestCache!.storageDurable, path: (config.requestCache?.cachePath)!)
                            }
                            
                            showDebugModeLog(target: target, response: response)
                            
                            handlerSuccess(response: WYSuccess(origin: String(data: response.data, encoding: .utf8) ?? "", storage: storage), handler: handler)
                            
                        }else {
                            do {
                                let codable: WYCodable = WYCodable()
                                if config.mapper.isEmpty == false {
                                    var mappingKeys: [[String]: String] = [[String]: String]()
                                    if let mapperMessage: String = config.mapper[WYMappingKey.message] {
                                        mappingKeys[[mapperMessage]] = "message"
                                    }
                                    
                                    if let mapperCode: String = config.mapper[WYMappingKey.code] {
                                        mappingKeys[[mapperCode]] = "code"
                                    }
                                    
                                    if let mapperData: String = config.mapper[WYMappingKey.data] {
                                        mappingKeys[[mapperData]] = "data"
                                    }
                                    
                                    if mappingKeys.isEmpty == false {
                                        codable.mappingKeys = .mapper(mappingKeys)
                                    }
                                }
                                
                                let responseData = try codable.decode(WYResponse.self, from: response.data)
                                
                                if responseData.code == config.serverRequestSuccessCode {
                                    
                                    if (config.requestCache != nil) && (config.requestCache!.cacheKey.count > 0) && (responseData.data.isEmpty == false) {
                                        
                                        if let storageData: Data = responseData.data.data(using: .utf8) {
                                            
                                            storage = WYStorage.storage(forKey: config.requestCache!.cacheKey, data: storageData, durable: config.requestCache!.storageDurable, path: (config.requestCache?.cachePath)!)
                                        }
                                    }
                                    
                                    showDebugModeLog(target: target, response: response)
                                    
                                    handlerSuccess(response: WYSuccess(parse: responseData.data, storage: storage), handler: handler)
                                    
                                }else {
                                    
                                    showDebugModeLog(target: target, response: response)
                                    
                                    handlerFailure(error: WYError(code: responseData.code, describe: (responseData.message.isEmpty ? WYLocalized("响应数据Code校验失败", table: WYBasisKitConfig.kitLocalizableTable) : responseData.message)), debugModeLog: config.debugModeLog, handler: handler)
                                }
                                
                            } catch  {
                                
                                showDebugModeLog(target: target, response: response)
                                
                                handlerFailure(error: WYError(code: config.unpackServerFailCode, describe: error.localizedDescription), debugModeLog: config.debugModeLog, handler: handler)
                            }
                        }
                        guard let storageError = storage?.error else { return  }
                        wy_networkPrint("数据缓存到本地失败：\(storageError)")
                    }
                }
                break
                
            case .failure(let error):
                
                showDebugModeLog(target: target, response: Response(statusCode: error.errorCode, data: error.localizedDescription.data(using: .utf8) ?? Data()))
                
                handlerFailure(error: WYError(code: String(error.errorCode), describe: error.localizedDescription), debugModeLog: config.debugModeLog, handler: handler)
                
                break
            }
        }
        WYNetworkRequestRegistry.shared.setCancellable(cancellable, for: requestID)
    }

    private static func handlerSuccess(response: WYSuccess, handler:((_ success: WYHandler) -> Void)? = .none) {
        
        Swift.Task { @MainActor in
            
            if (handler != nil) {
                handler!(.success(response))
            }
        }
    }
    
    private static func handlerFailure(error: WYError, isStatusCodeError: Bool = false, debugModeLog: Bool, function: String = #function, line: Int = #line, handler:((_ error: WYHandler) -> Void)? = .none) {
        
        Swift.Task { @MainActor in
            
            if (handler != nil) {
                
                handler!(.error(error))
            }
            
            guard debugModeLog == true else { return }
            
            if isStatusCodeError {
                wy_networkPrint("statusCode: \(error.code)\n statusError:  \(error)", function: function, line: line)
            }else {
                wy_networkPrint("serverCode: \(error.code)\n serverError:  \(error)", function: function, line: line)
            }
        }
    }
    
    private static func showDebugModeLog(target: WYTarget, response: Response, saveUrl: URL? = nil, function: String = #function, line: Int = #line) {
        
        let config = target.request.config
        
        guard config.debugModeLog == true else { return }
        
        switch target.request.config.taskMethod {
        case .data:
            wy_networkPrint("接口: \(target.baseURL)\(target.path)\n 请求头: \(target.headers ?? [:])\n dataString: \((target.request.data == nil ? "" : (String(data: target.request.data!, encoding: .utf8))) ?? "")\n 参数: \(target.request.parameter))\n 返回数据: \(String(describing: try? response.mapJSON()))", function: function, line: line)
            
        case .download:
            wy_networkPrint("下载地址: \(target.baseURL)\(target.path)\n 请求头: \(target.headers ?? [:])\n 参数: \(target.request.parameter))\n 资源保存路径: \(saveUrl?.absoluteString ?? "")", function: function, line: line)
            
        default:
            wy_networkPrint("接口: \(target.baseURL)\(target.path)\n 请求头: \(target.headers ?? [:])\n 参数: \(target.request.parameter))\n 返回数据: \(String(describing: try? response.mapJSON()))", function: function, line: line)
        }
    }
    
    private static func checkNetworkStatus(handler: ((_ status: (NetworkStatus, String)) -> Void)? = .none) {
        
        networkStatus(showStatusAlert: false, openSetting: true, statusHandler: { (status) in
            
            Swift.Task { @MainActor in
                
                if ((status == .unknown) || (status == .notReachable)) {
                    
                    if (networkSecurityInfo.0 == .userNotSelectedConnect) {
                        
                        networkStatus(showStatusAlert: true, openSetting: true, actionHandler: { (actionStr, networkStatus) in
                            
                            Swift.Task { @MainActor in
                                
                                if (actionStr == WYLocalized("继续连接", table: WYBasisKitConfig.kitLocalizableTable)) {
                                    
                                    if (handler != nil) {
                                        
                                        handler!((.userContinueConnect, ""))
                                    }
                                    
                                }else if ((actionStr == WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)) || (actionStr == WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable))) {
                                    
                                    if (handler != nil) {
                                        
                                        handler!((networkSecurityInfo.0, networkSecurityInfo.1))
                                    }
                                    
                                }else {
                                    
                                    if (handler != nil) {
                                        
                                        handler!((.userNotSelectedConnect, ""))
                                    }
                                }
                            }
                        })
                        
                    }else {
                        
                        if (handler != nil) {
                            
                            handler!((networkSecurityInfo.0, networkSecurityInfo.1))
                        }
                    }
                    
                }else {
                    
                    networkStatus(showStatusAlert: false, openSetting: true, statusHandler: { (_) in
                        
                        Swift.Task { @MainActor in
                            
                            if (handler != nil) {
                                
                                handler!((.userNotSelectedConnect, ""))
                            }
                        }
                    })
                }
            }
        })
    }
    
    private static func networkStatus(showStatusAlert: Bool, openSetting: Bool, statusHandler:((_ status: NetworkStatus) -> Void)? = nil, actionHandler:((_ action: String, _ status: NetworkStatus) -> Void)? = nil) {
        
        WYNetworkMonitor.listening("WYNetworkManager") { nwpath in
            
            var message = WYLocalized("未知的网络，可能存在安全隐患，是否继续？", table: WYBasisKitConfig.kitLocalizableTable)
            var networkStatus = NetworkStatus.unknown
            var actions = openSetting ? [WYLocalized("去设置", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("继续连接", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)] : [WYLocalized("继续连接", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)]
            switch nwpath.status {
            case .requiresConnection:
                message = WYLocalized("未知的网络，可能存在安全隐患，是否继续？", table: WYBasisKitConfig.kitLocalizableTable)
                networkStatus = .unknown
                actions = openSetting ? [WYLocalized("去设置", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("继续连接", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)] : [WYLocalized("继续连接", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)]
                break
            case .unsatisfied:
                message = WYLocalized("不可用的网络，请确认您的网络环境或网络连接权限已正确设置", table: WYBasisKitConfig.kitLocalizableTable)
                networkStatus = .notReachable
                actions = openSetting ? [WYLocalized("去设置", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)] : [WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)]
                break
            case .satisfied:
                
                if nwpath.usesInterfaceType(.wifi) {
                    message = WYLocalized("您正在使用Wifi联网", table: WYBasisKitConfig.kitLocalizableTable)
                    networkStatus = .reachableWifi
                    actions = openSetting ? [WYLocalized("去设置", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)] : [WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)]
                }
                
                if nwpath.usesInterfaceType(.cellular) {
                    message = WYLocalized("您正在使用蜂窝移动网络联网", table: WYBasisKitConfig.kitLocalizableTable)
                    networkStatus = .reachableCellular
                    actions = openSetting ? [WYLocalized("去设置", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)] : [WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)]
                }
                break
            @unknown default: break
            }
            
            if (statusHandler != nil) {
                
                statusHandler!(networkStatus)
            }
            
            showNetworkStatusAlert(showStatusAlert: showStatusAlert, status: networkStatus, message: message, actions: actions, actionHandler: actionHandler)
        }
    }
    
    private static func showNetworkStatusAlert(showStatusAlert: Bool, status: NetworkStatus, message: String, actions: [String], actionHandler: ((_ action: String, _ status: NetworkStatus) -> Void)? = nil) {
        
        if (showStatusAlert == false) {
            
            networkSecurityInfo = (NetworkStatus.userNotSelectedConnect, "")
            return
        }
        
        UIAlertController.wy_show(message: message, actions: actions) { (actionStr, _) in
            
            Swift.Task { @MainActor in
                
                if (actionHandler != nil) {
                    
                    actionHandler!(actionStr, status)
                }
                
                if actionStr == WYLocalized("去设置", table: WYBasisKitConfig.kitLocalizableTable) {
                    
                    networkSecurityInfo = (NetworkStatus.userNotSelectedConnect, "")
                    
                    let settingUrl = URL(string: UIApplication.openSettingsURLString)
                    if let url = settingUrl, UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(settingUrl!, options: [:], completionHandler: nil)
                    }
                }else if ((actionStr == WYLocalized("继续连接", table: WYBasisKitConfig.kitLocalizableTable)) && (status == .unknown)) {
                    
                    networkSecurityInfo = (NetworkStatus.userContinueConnect, "")
                    
                }else if (((actionStr == WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)) && (status == .unknown)) || ((actionStr == WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)) && (status == .notReachable))) {
                    
                    let errorStr = (actionStr == WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)) ? WYLocalized("已取消不安全网络连接", table: WYBasisKitConfig.kitLocalizableTable) : WYLocalized("无网络连接，请检查您的网络设置", table: WYBasisKitConfig.kitLocalizableTable)
                    networkSecurityInfo = (NetworkStatus.userCancelConnect, errorStr)
                    
                    cancelAllRequest()
                    
                }else {
                    networkSecurityInfo = (NetworkStatus.userNotSelectedConnect, "")
                }
            }
        }
    }
    
    /// DEBUG打印日志
    public static func wy_networkPrint(_ messages: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let time = timeFormatter.string(from: Date())
        let message = messages.compactMap { "\($0)" }.joined(separator: " ")
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("\n\(time) ——> \(fileName) ——> \(function) ——> line:\(line)\n\n \(message)\n\n\n")
        #endif
    }
}
