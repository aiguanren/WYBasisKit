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
    class func sharedSubClass(superClass: AnyClass) -> [String] {
        
        var count: UInt32 = 0
        // 获取所有已注册的类
        guard let allClassesPointer = objc_copyClassList(&count) else {
            return []
        }
        
        // 手动复制所有类
        let allClasses = Array(UnsafeBufferPointer(start: allClassesPointer, count: Int(count)))
        
        var subClasses: [String] = []
        
        // 遍历所有类并筛选出继承自superClass的子类
        for someClass in allClasses {
            if class_getSuperclass(someClass) == superClass {
                subClasses.append(NSStringFromClass(someClass))
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
    class func sharedClassMethod(className: String) -> [String] {
        
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
                let methodName = NSStringFromSelector(selector)
                methodList.append(methodName)
            }
            free(methods)
        }
        return methodList
    }
    
    /// 获取对象或者类的所有属性和对应的类型(struct类型也适用本方法)
    class func wy_sharedPropertys(object: Any? = nil, className: String = "") -> [String: Any] {
        
        var propertys: [String: Any] = [:]
        
        if (object != nil) {
            
            Mirror(reflecting: object!).children.forEach { (child) in
                propertys[child.label ?? ""] = type(of: child.value)
            }
        }
        guard let objClass = NSClassFromString(className) else {
            return propertys
        }
        
        var count: UInt32 = 0
        let ivars = class_copyIvarList(objClass, &count)
        for i in 0..<count {
            let ivar = ivars?[Int(i)]
            let ivarName = NSString(cString: ivar_getName(ivar!)!, encoding: String.Encoding.utf8.rawValue)
            let ivarType = NSString(cString: ivar_getTypeEncoding(ivar!)!, encoding: String.Encoding.utf8.rawValue)
            
            propertys[((ivarName ?? "") as String)] = (ivarType as String?) ?? ""
        }
        return propertys
    }
}
