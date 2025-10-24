//
//  SDKRequestContext.m
//  ObjCVerify
//
//  Created by guanren on 2025/10/20.
//

#import "SDKRequestContext.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>
#import "UserResponse.h"

@implementation SDKRequestContext

- (void)setResponse:(SDKResponse *)response {
    
    SDKRequest *request = (SDKRequest *)self.request;
    if (!request) return;
    
    NSError *error = nil;
    NSString *data = [WYCodable encode:response
                                     convertType:NSString.class
                                           error:&error];
    
    if (error == nil) {
        WYLog(@"eventId = %@, responseJson = %@", request.eventId, data);
        
        NSError *newError = nil;
        UserResponse *newResponse = [WYCodable decode:data modelClass:UserResponse.class error:&newError];
        if (newError == nil) {
            WYLog(@"newResponse = %@",newResponse);
            SubUserResponse *subUser = newResponse.subUser;
            NSArray *subResponses = newResponse.subResponses;
            SubUserResponse *firstResponse = subResponses.firstObject;
            WYLog(@"subUser.iconName = %@, firstResponse.iconName = %@",subUser.iconName, firstResponse.iconName);
            NSString *stringData = [WYCodable encode:newResponse
                                         convertType:NSString.class
                                               error:nil];
            WYLog(@"stringData = %@",stringData);
            
        }else {
            WYLog(@"newError = %@",newError);
        }
        
    }else {
        WYCodableError codableError = error.code;
        WYLog(@"encode error: %ld", codableError);
    }
}

@end
