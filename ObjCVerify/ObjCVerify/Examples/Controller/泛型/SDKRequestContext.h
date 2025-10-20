//
//  SDKRequestContext.h
//  ObjCVerify
//
//  Created by guanren on 2025/10/20.
//

#import <Foundation/Foundation.h>
#import "SDKRequest.h"
#import "SDKResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface SDKRequestContext<TRequest: id<SDKRequestProtocol>, TResponse: id<SDKResponseProtocol>> : NSObject

@property (nonatomic, strong, nullable) TRequest request;

- (void)setResponse:(SDKResponse *)response;

@end

NS_ASSUME_NONNULL_END
