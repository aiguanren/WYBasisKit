//
//  WYGenericTypeController.m
//  ObjCVerify
//
//  Created by guanren on 2025/10/20.
//

#import "WYGenericTypeController.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>
#import "SDKRequestContext.h"
#import "UserRequest.h"
#import "UserResponse.h"

@interface WYGenericTypeController ()

@end

@implementation WYGenericTypeController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    SDKRequestContext<UserRequest *, UserResponse *> *context = [[SDKRequestContext alloc] init];
    UserRequest *request = [[UserRequest alloc] init];
    request.eventId = @"测试eventId";
    context.request = request;
    [self userMoudleSuccessMethodWithContext:context];
}

- (void)userMoudleSuccessMethodWithContext:(SDKRequestContext<UserRequest *, UserResponse *> *)context {
    WYLog(@"context.request?.eventId = %@",context.request.eventId ?: @"");
    
    UserResponse *response = [[UserResponse alloc] init];
    response.errorCode = @"100";
    response.errorMessage = @"测试消息";
    [UserResponse wy_registerArchivedClass];
    
    [context setResponse:response];
}

- (void)testMothodWithData:(NSString *)data {
    
    WYLog(@"离线方法调用,data = %@", data);
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
