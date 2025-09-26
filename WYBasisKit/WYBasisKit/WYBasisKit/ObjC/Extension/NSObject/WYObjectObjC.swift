//
//  NSObjectObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/24.
//

import Foundation

@objc public extension NSObject {
    
    /**
     *  根据传入的superClass获取对应的子类
     *
     *  @param superClass 父类
     *
     *  @return 获取到的继承自superClass的子类
     */
    @objc static func sharedSubClass(_ superClass: AnyClass) -> [String] {
        return sharedSubClass(superClass: superClass)
    }
    
    /**
     *  根据传入的className获取对应的方法列表
     *
     *  @param className 类名
     *
     *  @return 获取到的className类中的所有方法
     */
    @objc static func sharedClassMethod(_ className: String) -> [String] {
        return sharedClassMethod(className: className)
    }
    
    /// 获取对象或者类的所有属性和对应的类型(struct类型也适用本方法)
    @objc static func wy_sharedPropertys(_ object: Any? = nil, className: String = "") -> [String: Any] {
        return wy_sharedPropertys(object: object, className: className)
    }
}
