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
}
#endif
