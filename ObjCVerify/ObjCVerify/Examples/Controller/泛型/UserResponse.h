//
//  UserResponse.h
//  ObjCVerify
//
//  Created by guanren on 2025/10/20.
//

#import "SDKResponse.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>

NS_ASSUME_NONNULL_BEGIN

@interface SubUserResponse : NSObject<WYCodableProtocol>

@property (nonatomic, copy) NSString *iconName;

@end

@interface UserResponse : SDKResponse<WYCodableProtocol>

@property (nonatomic, copy) NSString *haha;

@property (nonatomic, assign) NSInteger index;

@property (nonatomic, assign) BOOL isBool;

@property (nonatomic, strong) SubUserResponse *subUser;

@property (nonatomic, strong) NSArray <SubUserResponse *>*subResponses;

@end

NS_ASSUME_NONNULL_END
