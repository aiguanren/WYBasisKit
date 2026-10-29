//
//  WYCodableObjC+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import Foundation

#if canImport(WYBasisKitSwift)
extension WYCodableObjC {

    @nonobjc internal var keyDecodingTransform: (([String]) -> String)? {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.keyDecodingTransform) as? ([String]) -> String
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.keyDecodingTransform, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private struct WYAssociatedKeys {
        static var keyDecodingTransform: UInt8 = 0
    }

    @nonobjc static func keyFromSnakeCase(_ codingPath: [String]) -> String {
        guard let key = codingPath.last,
              let first = key.firstIndex(where: { $0 != "_" }),
              let last = key.lastIndex(where: { $0 != "_" }) else { return codingPath.last ?? "" }
        let components = key[first...last].split(separator: "_")
        guard components.count > 1 else { return key }
        let converted = components[0].lowercased() + components.dropFirst().map { $0.capitalized }.joined()
        return String(key[..<first]) + converted + String(key[key.index(after: last)...])
    }
    
    static func decodeJSONObject(_ jsonObject: Any, toClass modelClass: AnyClass, supportsProtocol: Bool) throws -> AnyObject {
        let className = NSStringFromClass(modelClass)
        
        // 只支持桥接方式
        if !supportsProtocol {
            throw WYCodableErrorObjC.protocolMismatch
        }
        
        if let jsonArray = jsonObject as? [[String: Any]] {
            // 数组处理
            let resultArray = try jsonArray.map { jsonDict in
                guard let object = WYCodableBridge.createObject(from: jsonDict, className: className) else {
                    throw WYCodableErrorObjC.typeMismatch
                }
                return object
            }
            return resultArray as AnyObject
        } else if let jsonDict = jsonObject as? [String: Any] {
            // 单个对象处理
            guard let result = WYCodableBridge.createObject(from: jsonDict, className: className) else {
                throw WYCodableErrorObjC.typeMismatch
            }
            return result
        } else {
            throw WYCodableErrorObjC.dataFormatError
        }
    }
}

#endif
