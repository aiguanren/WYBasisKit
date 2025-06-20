//
//  NumberFormatter.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import Foundation

public extension NumberFormatter {
    
    /// 千位符之四舍五入的整数(1234.5678 -> 1235)
    class func wy_roundToInteger(string: String?) -> String {
        
        return NumberFormatter.localizedString(from: NSNumber(value: Double(string ?? "0.0") ?? 0.0), number: .none)
    }
    
    /// 千位符之小数转百分数(1234.5678 -> 123,457%)
    class func wy_decimalToPercent(string: String?, maximumFractionDigits: Int = 4) -> String {
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .percent
        numberFormatter.maximumFractionDigits = maximumFractionDigits
        
        return numberFormatter.string(from: NSNumber(value: Double(string ?? "0") ?? 0)) ?? "0%"
    }
    
    /// 千位符之国际化格式小数(1234.5678 -> 1,234.5678)
    class func wy_internationalizedFormat(string: String?, maximumFractionDigits: Int = 4) -> String {
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = maximumFractionDigits
        
        return numberFormatter.string(from: NSNumber(value: Double(string ?? "0") ?? 0)) ?? "0"
    }
}
