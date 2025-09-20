//
//  ViewController.m
//  ObjCVerify
//
//  Created by guanren on 2025/8/18.
//

#import "ViewController.h"
#import <WYBasisKit/WYBasisKit-Swift.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
//    WYBasisKitConfigObjC.defaultScreenPixels = [[WYScreenPixelsObjC alloc] initWithWidth:0 height:0];
    
//    WYScrollInfoOptionsObjC *option = [[WYScrollInfoOptionsObjC alloc] init];
//    option.contentView = self.view;
//    option.offset = @(100.0);
//    option.config = [WYActivityConfigObjC scroll];
//    [WYActivityObjC showScrollInfo:@"" option:option];
//    [WYActivityObjC showScrollInfo:@"123"];
    
//    [WYActivityObjC showInfo:@"123"];
//    [WYActivityObjC showInfo:@"1234" option:nil];
    
//    WYLoadingInfoOptionsObjC *loadingOptions = [[WYLoadingInfoOptionsObjC alloc] init];
//    loadingOptions.animation = WYActivityAnimationObjCGifOrApng;
//    loadingOptions.config = [WYActivityConfigObjC concise];
//    loadingOptions.config.animationSize = CGSizeMake(50, 50);
//
//    WYActivity.showLoading(in: view, animation: .gifOrApng, config: WYActivityConfig.concise)
    
//    [WYActivityObjC showLoadingIn:self.view];
//    [WYActivityObjC showLoading:@"123" in:self.view];
//    [WYActivityObjC showLoadingIn:self.view option:loadingOptions];
//    [WYActivityObjC showLoading:@"加载中" in:self.view option:loadingOptions];
    
//    WYBiometricModeObjC style = [WYBiometricAuthorizationObjC checkBiometricObjc];
//    [WYBiometricAuthorizationObjC verifyBiometricsObjcWithLocalizedFallbackTitle:@"" localizedReason:@"" handler:^(BOOL isBackupHandler, BOOL isSuccess, NSString * _Nonnull error) {
//
//    }];
    
//    [WYCameraAuthorizationObjC authorizeCameraAccessWithShowAlert:YES handler:^(BOOL authorized) {
//
//    }];
    
//    [WYContactsAuthorizationObjC authorizeAddressBookAccessWithShowAlert:YES keysToFetch:nil handler:^(BOOL authorized, NSArray<CNContact *> * _Nullable userInfo) {
//
//    }];
    
//    [WYMicrophoneAuthorizationObjC authorizeMicrophoneAccessWithShowAlert:YES handler:^(BOOL authorized) {
//
//    }];
    
//    [WYPhotoAlbumsAuthorizationObjC authorizeAlbumAccessWithShowAlert:YES handler:^(BOOL authorized, BOOL limited) {
//
//    }];
    
//    [WYSpeechRecognitionAuthorizationObjC authorizeSpeechRecognitionWithShowAlert:YES handler:^(BOOL authorized) {
//
//    }];
    
//    NSString *csw = @"123cw&#￥dfvVE43t";
//    NSString *csw1 = [csw wy_specialCharactersEncoding:[NSCharacterSet URLQueryAllowedCharacterSet]];
//    NSLog(@"cs = %@",csw1);
//    
//    if ([csw wy_contains:@"VVE4" ignoreCase:NO]) {
//        NSLog(@"cs = haha");
//    }
//    
//    NSString *q = [NSString wy_sharedDeviceTimestamp:WYTimestampModeObjCSecond];
//    NSString *e = [NSString wy_sharedDeviceTimestamp:WYTimestampModeObjCMillisecond];
//    NSString *r = [NSString wy_sharedDeviceTimestamp:WYTimestampModeObjCMicroseconds];
//    NSLog(@"1 = %@\n1 = %@\n1 = %@",q,e,r);
//    
//    NSDictionary *ymd = [NSString wy_currentYearMonthDay];
//    NSLog(@"year = %@\nmonth = %@\nday = %@",ymd[@"year"], ymd[@"month"], ymd[@"day"]);
//    
//    WYWhatDayObjC whatDay = @"1757060466".wy_whatDay;
//    NSLog(@"whatDay = %ld",whatDay);
//    
//    NSString *cwdv1 = [@"1757063069" wy_dateDifferenceWithNowTimer:WYTimeFormatObjCYMDHMS customFormat:nil];
//    NSString *cwdv2 = [@"1757063069260" wy_dateDifferenceWithNowTimer:WYTimeFormatObjCYMDHMS customFormat:nil];
//    NSString *cwdv3 = [@"1757063069259821" wy_dateDifferenceWithNowTimer:WYTimeFormatObjCYMDHMS customFormat:nil];
//    NSLog(@"1 = %@\n2 = %@\n 3 = %@",cwdv1, cwdv2, cwdv3);
//    
//    NSString *cwdv3r3 = [@"你好" wy_phoneticTransformWithTone:YES interval:YES];
//    NSString *cwdv3dwr3 = [@"你好" wy_phoneticTransformWithTone:NO interval:NO];
//    NSLog(@"cwdv3r3 = %@, cwdv3dwr3 = %@",cwdv3r3, cwdv3dwr3);
//    
//    NSLog(@"1 = %ld, 2 = %ld, 3 = %ld", [NSString wy_zodiacSignFrom:@"1757063069"], [NSString wy_zodiacSignFrom:@"1757063069260"], (long)[NSString wy_zodiacSignFrom:@"1757063069259821"]);
    
//    NSString *str1 = @"";
//    NSString *str2 = @"123";
//    NSString *str3 = nil;
//    NSLog(@"str1 = %d\nstr2 = %d\nstr3 = %d",[NSString wy_isEmpty:str1], [NSString wy_isEmpty:str2],[NSString wy_isEmpty:str3]);
//    NSLog(@"str1 = %@\nstr2 = %@\nstr3 = %@",[NSString wy_safe:str1], [NSString wy_safe:str2],[NSString wy_safe:str3]);
//    NSLog(@"nstr3 = %@",str3);
    
//    NSLog(@"随机数 = %ld", [IntObjC wy_randomWithMinimum:10 maximum:20]);
//    
//    NSLog(@"随机浮点数 = %.2f", [DoubleObjC wy_randomWithMinimum:1 maximum:6]);
    
//    NSLog(@"1 = %f, 2 = %f",[FloatingPointObjC wy_degreesToRadianWithFloatFegrees:360], [FloatingPointObjC wy_radianToDegreesWithFloatRadian:M_PI_2]);
    
//    NSDecimalNumber *csdw = [[NSDecimalNumber alloc] initWithDouble:100];
//    [csdw wy_stringValue];
    
//    NSDictionary *dic = @{@"haah": @"123"};
//    NSLog(@"%@",[dic wy_valueForKey:@"haah"]);
//    NSLog(@"%@",[dic wy_valueForKey:@"xqws"]);
//    NSLog(@"%@",[dic wy_valueForKey:@"cewv" default:@"dwf"]);
}


@end
