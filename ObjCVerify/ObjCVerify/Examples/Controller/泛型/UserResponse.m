//
//  UserResponse.m
//  ObjCVerify
//
//  Created by guanren on 2025/10/20.
//

#import "UserResponse.h"

@implementation SubUserResponse

@end

@implementation UserResponse

+ (NSDictionary<NSString *, Class> *)wy_objectClassMapping {
    return @{NSStringFromSelector(@selector(subResponses)): SubUserResponse.class};
}

@end
