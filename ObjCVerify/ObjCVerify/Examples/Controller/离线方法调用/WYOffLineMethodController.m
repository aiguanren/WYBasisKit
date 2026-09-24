//
//  WYOffLineMethodController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/13.
//

#import "WYOffLineMethodController.h"
#import <objc/message.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYOffLineMethodController ()

@end

@implementation WYOffLineMethodController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    Class class = NSClassFromString(@"WYGenericTypeController");
    if ([class isSubclassOfClass:[UIViewController class]]) {
        UIViewController *moduleClass = [[class alloc] init];
        NSString *method = @"testMethodWithData:data2:";
        SEL selector = NSSelectorFromString(method);
        
        if ([moduleClass respondsToSelector:selector]) {
            // 声明函数指针类型与所需参数
            id (*typed_msgSend)(id, SEL, NSString *, NSInteger) = (id (*)(id, SEL, NSString *, NSInteger))objc_msgSend;
            // 直接调用并传参
            typed_msgSend(moduleClass, selector, @"context", 99999);
        }
    }
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
