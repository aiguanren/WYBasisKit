//
//  WYQRCodeController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/12.
//

#import "WYQRCodeController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYQRCodeController ()

@end

@implementation WYQRCodeController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSDictionary *jsonDict = @{@"简书": @"https://www.jianshu.com/p/dec880e5d401", @"GitHub": @"https://github.com/gaunren/WYBasisKit-swift"};
    NSError *error = nil;
    NSData *qrData = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        WYLog(@"JSON序列化失败: %@", error);
        return;
    }
    //NSData *qrData = [@"WYBasisKit" dataUsingEncoding:NSUTF8StringEncoding];
    
    UIImage *qrImage = [UIImage wy_createQrCodeWith:qrData size:CGSizeMake(350, 350) waterImage:[UIImage wy_find:@"WYBasisKit_60*60"]];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:qrImage];
    [self.view addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    
    // 获取二维码信息(必须要真机环境才能获取到相关信息)
    NSArray *infoArr = [imageView.image wy_recognitionQRCode];
    if (infoArr) {
        WYLog(@"二维码信息 = %@", infoArr);
    }
}

- (void)dealloc {
    WYLog(@"WYQRCodeController release");
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
