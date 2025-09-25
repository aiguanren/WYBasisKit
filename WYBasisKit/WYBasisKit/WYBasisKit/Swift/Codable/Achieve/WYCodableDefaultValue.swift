// 
//  WYCodableDefaultValue.swift
//  WYBasisKit
//
//  Created by 官人 on 2024/1/22.
//

import Foundation

protocol WYCodableDefaultValue {
    static var defaultValue: Self { get }
}

extension Bool: WYCodableDefaultValue {
    static var defaultValue: Bool {
        return false
    }
}

extension Int: WYCodableDefaultValue {
    static var defaultValue: Int {
        return 0
    }
}

extension UInt: WYCodableDefaultValue {
    static var defaultValue: UInt {
        return 0
    }
}

extension CGFloat: WYCodableDefaultValue {
    static var defaultValue: CGFloat {
        return 0.0
    }
}

extension Double: WYCodableDefaultValue {
    static var defaultValue: Double {
        return 0.0
    }
}

extension String: WYCodableDefaultValue {
    static var defaultValue: String {
        return ""
    }
}
