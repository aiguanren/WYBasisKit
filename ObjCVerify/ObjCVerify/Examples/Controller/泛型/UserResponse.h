//
//  UserResponse.h
//  ObjCVerify
//
//  Created by guanren on 2025/10/20.
//

#import "SDKResponse.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>

NS_ASSUME_NONNULL_BEGIN

@interface UserResponse : SDKResponse<WYCodableProtocol>

@property (nonatomic, copy) NSString *haha;

@property (nonatomic, assign) NSInteger index;

@property (nonatomic, assign) BOOL isBool;

@end

NS_ASSUME_NONNULL_END
