//
//  SDKResponse.h
//  ObjCVerify
//
//  Created by guanren on 2025/10/20.
//

#import <Foundation/Foundation.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SDKResponseProtocol <NSObject>
@end

@interface SDKResponse : NSObject <SDKResponseProtocol, WYCodableProtocol>

@property (nonatomic, copy) NSString *errorCode;
@property (nonatomic, copy) NSString *errorMessage;

@end

NS_ASSUME_NONNULL_END
