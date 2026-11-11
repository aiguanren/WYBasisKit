//
//  WYChatConfigurationChecks.h
//  ObjCVerify
//
//  Created by guanren on 2026/11/11.
//

#import <objc/runtime.h>
#import "WYChatConfigurationCatalog.h"

/// 检查配置属性的ObjC可见性、读写和Swift往返结果
static void WYChatCheckConfigurationProperties(NSObject *source, NSObject *restored, NSString *prefix, void (^check)(NSString *, BOOL)) {
    NSDictionary *catalog = WYChatConfigurationCatalog();
    NSArray<NSString *> *properties = catalog[NSStringFromClass(source.class)];
    for (NSString *name in properties) {
        NSString *path = [prefix stringByAppendingString:name];
        objc_property_t property = class_getProperty(source.class, name.UTF8String);
        if (!property) { check([@"configuration-export." stringByAppendingString:path], NO); continue; }
        @try {
            id original = [source valueForKey:name];
            id roundtrip = [restored valueForKey:name];
            if (original && catalog[NSStringFromClass([original class])]) {
                check([@"configuration-object." stringByAppendingString:path], roundtrip != nil && [roundtrip isKindOfClass:[original class]]);
                if (roundtrip) { WYChatCheckConfigurationProperties(original, roundtrip, [path stringByAppendingString:@"."], check); }
                continue;
            }
            NSString *attributes = @(property_getAttributes(property));
            BOOL block = [attributes hasPrefix:@"T@?"];
            BOOL equal = block ? (original == nil) == (roundtrip == nil) : original == roundtrip || [original isEqual:roundtrip];
            check([@"configuration-roundtrip." stringByAppendingString:path], equal);
            if (![attributes containsString:@",R"]) {
                [source setValue:original forKey:name];
                id reread = [source valueForKey:name];
                check([@"configuration-write." stringByAppendingString:path], block ? (original == nil) == (reread == nil) : original == reread || [original isEqual:reread]);
            }
        } @catch (NSException *exception) {
            check([@"configuration-access." stringByAppendingString:path], NO);
        }
    }
}

/// 对源文件清单中的每个配置属性检查运行时导出
static void WYChatCheckConfigurationExports(void (^check)(NSString *, BOOL)) {
    [WYChatConfigurationCatalog() enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSArray<NSString *> *properties, BOOL *stop) {
        Class type = NSClassFromString(name);
        for (NSString *property in properties) {
            check([NSString stringWithFormat:@"configuration-export.%@.%@", name, property], type && class_getProperty(type, property.UTF8String));
        }
    }];
}
