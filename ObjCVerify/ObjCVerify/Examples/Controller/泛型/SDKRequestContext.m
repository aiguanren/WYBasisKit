//
//  SDKRequestContext.m
//  ObjCVerify
//
//  Created by guanren on 2025/10/20.
//

#import "SDKRequestContext.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@implementation SDKRequestContext

- (void)setResponse:(SDKResponse *)response {
    
    SDKRequest *request = (SDKRequest *)self.request;
    if (!request) return;
    
    NSError *error = nil;
    
    WYCodable *codable = [[WYCodable alloc] init];
    NSString *data = [codable encode:response
                                     convertType:NSString.class
                                           error:&error];
    
    if (error == nil) {
        WYLog(@"eventId = %@, responseJson = %@", request.eventId, data);
    }else {
        WYCodableError codableError = error.code;
        WYLog(@"encode error: %ld", codableError);
    }
}

@end
