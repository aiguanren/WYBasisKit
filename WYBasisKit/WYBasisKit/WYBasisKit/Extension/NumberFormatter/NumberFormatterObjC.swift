//
//  NumberFormatterObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/24.
//

import Foundation

@objc public extension NumberFormatter {
    
    /// 千位符之四舍五入的整数(1234.5678 -> 1235)
    @objc static func wy_roundToIntegerObjC(string: String?) -> String {
        return wy_roundToInteger(string: string)
    }
    
    /// 千位符之小数转百分数(1234.5678 -> 123,457%)
    @objc static func wy_decimalToPercentObjC(string: String?, maximumFractionDigits: Int = 4) -> String {
        return wy_decimalToPercent(string: string, maximumFractionDigits: maximumFractionDigits)
    }
    
    /// 千位符之国际化格式小数(1234.5678 -> 1,234.5678)
    @objc static func wy_internationalizedFormatObjC(string: String?, maximumFractionDigits: Int = 4) -> String {
        return wy_internationalizedFormat(string: string, maximumFractionDigits: maximumFractionDigits)
    }
}
