//
//  NSObjectObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/24.
//

import Foundation
import ObjectiveC.runtime

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

/// 支持 NSSecureCoding 自动归档与解档
@objc public extension NSObject {
    
    /// 注册自定义Model类以支持归档/解归档
    @objc class func wy_registerArchivedClass() {
        let className = NSStringFromClass(self)
        wy_archive_registeredClasses.insert(className)
        
        // 动态添加 NSSecureCoding 支持
        NSObject.injectSecureCodingSupport()
    }
    
    /// 将对象安全归档为 NSData（内部使用 NSSecureCoding）
    @objc func wy_archivedData() -> Data? {
        do {
            // 确保当前类支持 NSSecureCoding
            let currentClass = type(of: self)
            let className = NSStringFromClass(currentClass)
            if wy_archive_registeredClasses.contains(className) {
                NSObject.injectSecureCodingSupport()
            }
            
            // 确保所有嵌套对象也支持 NSSecureCoding
            ensureNestedObjectsSupportSecureCoding(self)
            
            let data = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: true)
            return data
        } catch {
            print("WYArchived archive error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 从 NSData 安全解档为对象（失败返回 nil）
    @objc class func wy_unarchiveFromData(_ data: Data?) -> AnyObject? {
        guard let data = data, data.count > 0 else {
            return nil
        }
        
        do {
            // 构建允许的类集合
            var allowedClassWrappers = Set<WYArchiveWrapper>()
            
            // 添加基础 Foundation 类
            let foundationClasses: [AnyClass] = [
                NSString.self, NSNumber.self,
                NSArray.self, NSMutableArray.self,
                NSDictionary.self, NSMutableDictionary.self,
                NSSet.self, NSMutableSet.self,
                NSData.self, NSDate.self,
                NSValue.self
            ]
            
            foundationClasses.forEach { allowedClassWrappers.insert(WYArchiveWrapper(classType: $0)) }
            allowedClassWrappers.insert(WYArchiveWrapper(classType: self))
            
            // 添加所有已注册的类
            for className in wy_archive_registeredClasses {
                if let cls = NSClassFromString(className) {
                    allowedClassWrappers.insert(WYArchiveWrapper(classType: cls))
                }
            }
            
            // 转换为 AnyClass 数组
            let allowedClasses = allowedClassWrappers.map { $0.classType }
            
            let object = try NSKeyedUnarchiver.unarchivedObject(ofClasses: allowedClasses, from: data)
            return object as AnyObject?
        } catch {
            print("WYArchived unarchive error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 使用全局常量来定义 Selector，避免嵌套类的问题
    private struct WYArchiveSelectors {
        // 使用 NSSelectorFromString 但通过常量管理，避免硬编码散落各处
        static let supportsSecureCoding: Selector = NSSelectorFromString("supportsSecureCoding")
        static let encodeWithCoder: Selector = NSSelectorFromString("encodeWithCoder:")
        static let initWithCoder: Selector = NSSelectorFromString("initWithCoder:")
    }
    
    // 使用明确的协议引用
    private static var secureCodingProtocol: Protocol? {
        return objc_getProtocol("NSSecureCoding")
    }
    
    // 类包装器用于 Set
    private struct WYArchiveWrapper: Hashable {
        let classType: AnyClass
        
        static func == (lhs: WYArchiveWrapper, rhs: WYArchiveWrapper) -> Bool {
            return lhs.classType == rhs.classType
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(classType))
        }
    }
    
    /// 注入 NSSecureCoding 支持
    private static func injectSecureCodingSupport() {
        let classType = self
        
        // 确保类遵循 NSSecureCoding 协议
        if let proto = secureCodingProtocol {
            if !class_conformsToProtocol(classType, proto) {
                class_addProtocol(classType, proto)
            }
        }
        
        // 注入 +supportsSecureCoding 类方法
        let metaClass: AnyClass = object_getClass(classType)!
        if !classType.responds(to: WYArchiveSelectors.supportsSecureCoding) {
            let block: @convention(block) () -> Bool = { true }
            let imp = imp_implementationWithBlock(unsafeBitCast(block, to: AnyObject.self))
            class_addMethod(metaClass, WYArchiveSelectors.supportsSecureCoding, imp, "B@:")
        }
        
        // 注入 encodeWithCoder: 方法
        if !classType.instancesRespond(to: WYArchiveSelectors.encodeWithCoder) {
            let encodeBlock: @convention(block) (AnyObject, NSCoder) -> Void = { obj, coder in
                guard let object = obj as? NSObject else { return }
                
                // 跳过 NSObject 和 NSProxy
                if type(of: object) == NSObject.self || NSStringFromClass(type(of: object)) == "NSProxy" {
                    return
                }
                
                var currentClass: AnyClass? = type(of: object)
                while let cls = currentClass, cls != NSObject.self {
                    var count: UInt32 = 0
                    if let properties = class_copyPropertyList(cls, &count) {
                        for i in 0..<Int(count) {
                            let property = properties[i]
                            // 跳过只读属性
                            if let attributes = property_getAttributes(property),
                               strstr(attributes, ",R") != nil {
                                continue
                            }
                            
                            let key = String(cString: property_getName(property))
                            if let value = object.value(forKey: key) {
                                // 递归确保嵌套对象支持 NSSecureCoding
                                if let nestedObject = value as? NSObject {
                                    let nestedClass = type(of: nestedObject)
                                    let nestedClassName = NSStringFromClass(nestedClass)
                                    if wy_archive_registeredClasses.contains(nestedClassName) {
                                        NSObject.injectSecureCodingSupportForClass(nestedClass)
                                    }
                                }
                                coder.encode(value, forKey: key)
                            }
                        }
                        free(properties)
                    }
                    currentClass = class_getSuperclass(cls)
                }
            }
            let encodeImp = imp_implementationWithBlock(unsafeBitCast(encodeBlock, to: AnyObject.self))
            class_addMethod(classType, WYArchiveSelectors.encodeWithCoder, encodeImp, "v@:@")
        }
        
        // 注入 initWithCoder: 方法
        if !classType.instancesRespond(to: WYArchiveSelectors.initWithCoder) {
            let initBlock: @convention(block) (AnyObject, NSCoder) -> AnyObject? = { obj, coder in
                // obj 已经是分配好的实例，我们只需要初始化属性
                guard let object = obj as? NSObject else { return nil }
                
                var currentClass: AnyClass? = type(of: object)
                while let currentCls = currentClass, currentCls != NSObject.self {
                    var count: UInt32 = 0
                    if let properties = class_copyPropertyList(currentCls, &count) {
                        for i in 0..<Int(count) {
                            let property = properties[i]
                            // 跳过只读属性
                            if let attributes = property_getAttributes(property),
                               strstr(attributes, ",R") != nil {
                                continue
                            }
                            
                            let key = String(cString: property_getName(property))
                            let setterName = "set" + key.prefix(1).uppercased() + key.dropFirst() + ":"
                            let setterSel = NSSelectorFromString(setterName)
                            
                            if object.responds(to: setterSel) {
                                if let value = coder.decodeObject(forKey: key) {
                                    object.setValue(value, forKey: key)
                                }
                            }
                        }
                        free(properties)
                    }
                    currentClass = class_getSuperclass(currentCls)
                }
                return object
            }
            let initImp = imp_implementationWithBlock(unsafeBitCast(initBlock, to: AnyObject.self))
            class_addMethod(classType, WYArchiveSelectors.initWithCoder, initImp, "@@:@")
        }
    }
    
    /// 为指定类注入 NSSecureCoding 支持
    private static func injectSecureCodingSupportForClass(_ classType: AnyClass) {
        if let proto = secureCodingProtocol {
            if !class_conformsToProtocol(classType, proto) {
                class_addProtocol(classType, proto)
            }
        }
        
        // 注入 +supportsSecureCoding
        let metaClass: AnyClass = object_getClass(classType)!
        if !classType.responds(to: WYArchiveSelectors.supportsSecureCoding) {
            let block: @convention(block) () -> Bool = { true }
            let imp = imp_implementationWithBlock(unsafeBitCast(block, to: AnyObject.self))
            class_addMethod(metaClass, WYArchiveSelectors.supportsSecureCoding, imp, "B@:")
        }
        
        // 注入 encodeWithCoder:
        if !classType.instancesRespond(to: WYArchiveSelectors.encodeWithCoder) {
            let encodeBlock: @convention(block) (AnyObject, NSCoder) -> Void = { obj, coder in
                guard let object = obj as? NSObject else { return }
                
                if type(of: object) == NSObject.self || NSStringFromClass(type(of: object)) == "NSProxy" {
                    return
                }
                
                var currentClass: AnyClass? = type(of: object)
                while let cls = currentClass, cls != NSObject.self {
                    var count: UInt32 = 0
                    if let properties = class_copyPropertyList(cls, &count) {
                        for i in 0..<Int(count) {
                            let property = properties[i]
                            if let attributes = property_getAttributes(property),
                               strstr(attributes, ",R") != nil {
                                continue
                            }
                            
                            let key = String(cString: property_getName(property))
                            if let value = object.value(forKey: key) {
                                coder.encode(value, forKey: key)
                            }
                        }
                        free(properties)
                    }
                    currentClass = class_getSuperclass(cls)
                }
            }
            let encodeImp = imp_implementationWithBlock(unsafeBitCast(encodeBlock, to: AnyObject.self))
            class_addMethod(classType, WYArchiveSelectors.encodeWithCoder, encodeImp, "v@:@")
        }
        
        // 注入 initWithCoder:
        if !classType.instancesRespond(to: WYArchiveSelectors.initWithCoder) {
            let initBlock: @convention(block) (AnyObject, NSCoder) -> AnyObject? = { obj, coder in
                // obj 已经是分配好的实例，我们只需要初始化属性
                guard let object = obj as? NSObject else { return nil }
                
                var currentClass: AnyClass? = type(of: object)
                while let currentCls = currentClass, currentCls != NSObject.self {
                    var count: UInt32 = 0
                    if let properties = class_copyPropertyList(currentCls, &count) {
                        for i in 0..<Int(count) {
                            let property = properties[i]
                            if let attributes = property_getAttributes(property),
                               strstr(attributes, ",R") != nil {
                                continue
                            }
                            
                            let key = String(cString: property_getName(property))
                            let setterName = "set" + key.prefix(1).uppercased() + key.dropFirst() + ":"
                            let setterSel = NSSelectorFromString(setterName)
                            
                            if object.responds(to: setterSel) {
                                if let value = coder.decodeObject(forKey: key) {
                                    object.setValue(value, forKey: key)
                                }
                            }
                        }
                        free(properties)
                    }
                    currentClass = class_getSuperclass(currentCls)
                }
                return object
            }
            let initImp = imp_implementationWithBlock(unsafeBitCast(initBlock, to: AnyObject.self))
            class_addMethod(classType, WYArchiveSelectors.initWithCoder, initImp, "@@:@")
        }
    }
    
    /// 确保嵌套对象支持 NSSecureCoding
    private func ensureNestedObjectsSupportSecureCoding(_ object: NSObject) {
        let currentClass = type(of: object)
        var currentClassToCheck: AnyClass? = currentClass
        
        while let cls = currentClassToCheck, cls != NSObject.self {
            var count: UInt32 = 0
            if let properties = class_copyPropertyList(cls, &count) {
                for i in 0..<Int(count) {
                    let property = properties[i]
                    if let attributes = property_getAttributes(property),
                       strstr(attributes, ",R") != nil {
                        continue
                    }
                    
                    let key = String(cString: property_getName(property))
                    if let value = object.value(forKey: key) as? NSObject {
                        let nestedClassName = NSStringFromClass(type(of: value))
                        if wy_archive_registeredClasses.contains(nestedClassName) {
                            NSObject.injectSecureCodingSupportForClass(type(of: value))
                        }
                        // 递归检查更深层的嵌套对象
                        ensureNestedObjectsSupportSecureCoding(value)
                    } else if let array = object.value(forKey: key) as? [NSObject] {
                        for item in array {
                            let itemClassName = NSStringFromClass(type(of: item))
                            if wy_archive_registeredClasses.contains(itemClassName) {
                                NSObject.injectSecureCodingSupportForClass(type(of: item))
                            }
                            ensureNestedObjectsSupportSecureCoding(item)
                        }
                    } else if let dict = object.value(forKey: key) as? [String: NSObject] {
                        for (_, value) in dict {
                            let valueClassName = NSStringFromClass(type(of: value))
                            if wy_archive_registeredClasses.contains(valueClassName) {
                                NSObject.injectSecureCodingSupportForClass(type(of: value))
                            }
                            ensureNestedObjectsSupportSecureCoding(value)
                        }
                    }
                }
                free(properties)
            }
            currentClassToCheck = class_getSuperclass(cls)
        }
    }
}

// 全局注册表
private var wy_archive_registeredClasses: Set<String> = Set<String>()
