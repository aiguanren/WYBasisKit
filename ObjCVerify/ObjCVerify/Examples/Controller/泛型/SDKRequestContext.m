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
        wy_print(@"eventId = %@, responseJson = %@", request.eventId, data);
        
        NSError *newError = nil;
        UserResponse *newResponse = [WYCodable decode:data modelClass:UserResponse.class error:&newError];
        if (newError == nil) {
            wy_print(@"newResponse = %@",newResponse);
            SubUserResponse *subUser = newResponse.subUser;
            NSArray *subResponses = newResponse.subResponses;
            SubUserResponse *firstResponse = subResponses.firstObject;
            wy_print(@"subUser.iconName = %@, firstResponse.iconName = %@",subUser.iconName, firstResponse.iconName);
            NSString *stringData = [WYCodable encode:newResponse
                                         convertType:NSString.class
                                               error:nil];
            wy_print(@"stringData = %@",stringData);
            
        }else {
            wy_print(@"newError = %@",newError);
        }
        
    }else {
        WYCodableError codableError = error.code;
        wy_print(@"encode error: %ld", codableError);
    }
}

@end
