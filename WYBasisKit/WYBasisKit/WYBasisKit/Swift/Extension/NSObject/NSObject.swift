//
//  NSObject.swift
//  WYBasisKit
//
//  Created by 官人 on 2024/11/21.
//  Copyright © 2024 官人. All rights reserved.
//

import Foundation
import ObjectiveC.runtime

public extension NSObject {
    
    /**
     *  根据传入的superClass获取对应的子类
     *
     *  @param superClass 父类
     *
     *  @return 获取到的继承自superClass的子类
     */
    static func sharedSubClass(superClass: AnyClass) -> [String] {
        
        var count: UInt32 = 0
        // 获取所有已注册的类
        guard let allClassesPointer = objc_copyClassList(&count) else {
            return []
        }
        
        defer { free(UnsafeMutableRawPointer(allClassesPointer)) }
        
        // 手动复制所有类
        let allClasses = Array(UnsafeBufferPointer(start: allClassesPointer, count: Int(count)))
        
        var subClasses: [String] = []
        
        // 遍历所有类并筛选出继承自superClass的子类
        for someClass in allClasses {
            if class_getSuperclass(someClass) == superClass {
                subClasses.append(String(describing: someClass))
            }
        }
        
        return subClasses
    }
    
    /**
     *  根据传入的className获取对应的方法列表
     *
     *  @param className 类名
     *
     *  @return 获取到的className类中的所有方法
     */
    static func sharedClassMethod(className: String) -> [String] {
        
        guard let classType = NSClassFromString(className) else {
            return []
        }
        
        var methodList: [String] = []
        var methodCount: UInt32 = 0
        
        // 获取实例方法列表
        if let methods = class_copyMethodList(classType, &methodCount) {
            for i in 0..<Int(methodCount) {
                let method = methods[i]
                let selector = method_getName(method)
                let methodName = String(describing: selector)
                methodList.append(methodName)
            }
            free(methods)
        }
        return methodList
    }
    
    /// 获取对象或者类的所有属性和对应的类型(struct类型也适用本方法)
    static func wy_sharedPropertys(object: Any? = nil, className: String = "") -> [String: Any] {
        
        var properties: [String: Any] = [:]
        
        // 通过 Mirror 获取对象属性（支持 struct、class）
        if let obj = object {
            for child in Mirror(reflecting: obj).children {
                if let label = child.label {
                    properties[label] = type(of: child.value)
                }
            }
        }
        
        // 获取类的 Ivar 列表
        guard let objClass = NSClassFromString(className) else {
            return properties
        }
        
        var count: UInt32 = 0
        guard let ivars = class_copyIvarList(objClass, &count) else {
            return properties
        }
        defer { free(ivars) }
        
        for i in 0..<Int(count) {
            let ivar = ivars[i]
            if let nameC = ivar_getName(ivar), let typeC = ivar_getTypeEncoding(ivar) {
                let name = String(cString: nameC)
                let type = String(cString: typeC)
                properties[name] = type
            }
        }
        
        return properties
    }
}
