//
//  SDKRequest.h
//  ObjCVerify
//
//  Created by guanren on 2025/10/20.
//

#import <Foundation/Foundation.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SDKRequestProtocol <NSObject>
@end

@interface SDKRequest : NSObject <SDKRequestProtocol, WYCodableProtocol>

@property (nonatomic, copy) NSString *eventId;

@end

NS_ASSUME_NONNULL_END
