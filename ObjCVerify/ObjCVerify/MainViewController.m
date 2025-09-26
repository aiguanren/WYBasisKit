//
//  ViewController.m
//  ObjCVerify
//
//  Created by guanren on 2025/8/18.
//

#import "MainViewController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC-Swift.h>

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
//    WYBasisKitConfig.defaultScreenPixels = [[WYScreenPixels alloc] initWithWidth:0 height:0];
//    
//    WYScrollInfoOptions *option = [[WYScrollInfoOptions alloc] init];
//    option.contentView = self.view;
//    option.offset = @(100.0);
//    option.config = [WYActivityConfig scroll];
//    [WYActivity showScrollInfo:@"" option:option];
//    [WYActivity showScrollInfo:@"123"];
//    
//    [WYActivity showInfo:@"123"];
//    [WYActivity showInfo:@"1234" option:nil];
//    
//    WYLoadingInfoOptions *loadingOptions = [[WYLoadingInfoOptions alloc] init];
//    loadingOptions.animation = WYActivityAnimationGifOrApng;
//    loadingOptions.config = [WYActivityConfig concise];
//    loadingOptions.config.animationSize = CGSizeMake(50, 50);
//    
//    [WYActivity showLoading:self.view];
//    [WYActivity showLoading:@"123" in:self.view];
//    [WYActivity showLoading:self.view option:loadingOptions];
//    [WYActivity showLoading:@"加载中" in:self.view option:loadingOptions];
//    [WYActivity dismissLoading:self.view];
//    [WYActivity dismissLoading:self.view animate:YES];
//    
//    WYBiometricMode style = [WYBiometricAuthorization checkBiometric];
//    [WYBiometricAuthorization verifyBiometrics:@"" localizedReason:@"" handler:^(BOOL isBackupHandler, BOOL isSuccess, NSString * _Nonnull error) {
//            
//    }];
//    
//    [WYCameraAuthorization authorizeCameraAccess:YES handler:^(BOOL authorized) {
//            
//    }];
//    
//    [WYContactsAuthorization authorizeAddressBookAccess:YES keysToFetch:nil handler:^(BOOL authorized, NSArray<CNContact *> * _Nullable userInfo) {
//
//    }];
//    
//    [WYMicrophoneAuthorization authorizeMicrophoneAccess:YES handler:^(BOOL authorized) {
//
//    }];
//    
//    [WYPhotoAlbumsAuthorization authorizeAlbumAccess:YES handler:^(BOOL authorized, BOOL limited) {
//
//    }];
//    
//    [WYSpeechRecognitionAuthorization authorizeSpeechRecognition:YES handler:^(BOOL authorized) {
//
//    }];
//    
//    NSString *csw = @"123cw&#￥dfvVE43t";
//    NSString *csw1 = [csw wy_specialCharactersEncoding:[NSCharacterSet URLQueryAllowedCharacterSet]];
//    NSLog(@"cs = %@",csw1);
//    
//    if ([csw wy_contains:@"VVE4" ignoreCase:NO]) {
//        NSLog(@"cs = haha");
//    }
//    
//    NSString *q = [NSString wy_sharedDeviceTimestamp:WYTimestampModeSecond];
//    NSString *e = [NSString wy_sharedDeviceTimestamp:WYTimestampModeMillisecond];
//    NSString *r = [NSString wy_sharedDeviceTimestamp:WYTimestampModeMicroseconds];
//    NSLog(@"1 = %@\n1 = %@\n1 = %@",q,e,r);
//    
//    NSDictionary *ymd = [NSString wy_currentYearMonthDay];
//    NSLog(@"year = %@\nmonth = %@\nday = %@",ymd[@"year"], ymd[@"month"], ymd[@"day"]);
//    
//    WYWhatDay whatDay = @"1757060466".wy_whatDay;
//    NSLog(@"whatDay = %ld",whatDay);
//    
//    NSString *cwdv1 = [@"1757063069" wy_dateDifferenceWithNowTimer:WYTimeFormatYMDHMS customFormat:nil];
//    NSString *cwdv2 = [@"1757063069260" wy_dateDifferenceWithNowTimer:WYTimeFormatYMDHMS customFormat:nil];
//    NSString *cwdv3 = [@"1757063069259821" wy_dateDifferenceWithNowTimer:WYTimeFormatYMDHMS customFormat:nil];
//    NSLog(@"1 = %@\n2 = %@\n 3 = %@",cwdv1, cwdv2, cwdv3);
//    
//    NSString *cwdv3r3 = [@"你好" wy_phoneticTransformWithTone:YES interval:YES];
//    NSString *cwdv3dwr3 = [@"你好" wy_phoneticTransformWithTone:NO interval:NO];
//    NSLog(@"cwdv3r3 = %@, cwdv3dwr3 = %@",cwdv3r3, cwdv3dwr3);
//    
//    NSLog(@"1 = %ld, 2 = %ld, 3 = %ld", [NSString wy_zodiacSignWith:@"1757063069"], [NSString wy_zodiacSignWith:@"1757063069260"], (long)[NSString wy_zodiacSignWith:@"1757063069259821"]);
//    
//    NSString *str1 = @"";
//    NSString *str2 = @"123";
//    NSString *str3 = nil;
//    NSLog(@"str1 = %d\nstr2 = %d\nstr3 = %d",[NSString wy_isEmpty:str1], [NSString wy_isEmpty:str2],[NSString wy_isEmpty:str3]);
//    NSLog(@"str1 = %@\nstr2 = %@\nstr3 = %@",[NSString wy_safe:str1], [NSString wy_safe:str2],[NSString wy_safe:str3]);
//    NSLog(@"nstr3 = %@",str3);
//    
//    NSLog(@"随机数 = %ld", [IntObjC wy_randomWithMinimum:10 maximum:20]);
//    
//    NSLog(@"随机浮点数 = %.2f", [DoubleObjC wy_randomWithMinimum:1 maximum:6]);
//    
//    NSLog(@"1 = %f, 2 = %f",[FloatingPointObjC wy_degreesToRadianWithFloatFegrees:360], [FloatingPointObjC wy_radianToDegreesWithFloatRadian:M_PI_2]);
//    
//    NSDecimalNumber *csdw = [[NSDecimalNumber alloc] initWithDouble:100];
//    [csdw wy_stringValue];
//    
//    NSDictionary *dic = @{@"haah": @"123"};
//    NSLog(@"%@",[dic wy_valueForKey:@"haah"]);
//    NSLog(@"%@",[dic wy_valueForKey:@"xqws"]);
//    NSLog(@"%@",[dic wy_valueForKey:@"cewv" default:@"dwf"]);
//    
//    NSMutableAttributedString *zxc = nil;
//    
//    WYImageAttachmentOption *cevde = [[WYImageAttachmentOption alloc] initWithImage:[UIImage imageNamed:@""] size:CGSizeZero position:PositionObjCAfter positionValue:@(10) alignment:AlignmentObjCTop alignmentOffset:10 spacingBefore:10 spacingAfter:10];
//    [zxc wy_insertImage:@[cevde]];
    
//    UIImage *image = nil;
//    [image wy_cuttingRoundWithBorderWidth:0 borderColor:0];
//    [image wy_drawingCornerRadius:6 borderWidth:0 borderColor:0 corners:UIRectCornerTopLeft];
    
//    UIView *test = [[UIView alloc] init];
//    test.backgroundColor = [UIColor magentaColor];
//    [self.view addSubview:test];
//    [test wy_makeVisual:^(UIView * make) {
//        make.wy_gradualColors(@[[UIColor yellowColor], [UIColor purpleColor]]);
//        make.wy_gradientDirection(WYGradientDirectionLeftToRight);
//        make.wy_borderWidth(5);
//        make.wy_borderColor([UIColor blackColor]);
//        make.wy_rectCorner(UIRectCornerTopRight);
//        make.wy_cornerRadius(20);
//        make.wy_shadowRadius(20);
//        make.wy_shadowColor([UIColor greenColor]);
//        make.wy_shadowOffset(CGSizeZero);
//        make.wy_shadowOpacity(0.5);
//    }];
//    test.wy_rectCorner(UIRectCornerAllCorners);
//    test.wy_cornerRadius(10);
//    test.wy_borderColor([UIColor blackColor]);
//    test.wy_borderWidth(5);
//    test.wy_gradualColors(@[[UIColor orangeColor], [UIColor redColor]]);
//    test.wy_gradientDirection(WYGradientDirectionLeftToRight);
//    test.wy_showVisual();
//    [test mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.right.equalTo(self.view);
//        make.top.equalTo(self.view).mas_offset(UIDevice.wy_navViewHeight);
//        make.bottom.equalTo(self.view).mas_offset(-UIDevice.wy_tabbarSafetyZone);
//    }];
//    
//    [self performSelector:@selector(clearVisual:) withObject:test afterDelay:5];
    
//    [self performSelector:@selector(test) withObject:nil afterDelay:2];
    
    
//    UICollectionView *cw = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[[WYCollectionViewFlowLayout alloc] init]];
//    UITableView *cd = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
//    [cw wy_register:[UICollectionViewCell class] style:WYCollectionViewRegisterStyleCell];
//    [cd wy_register:[UITableViewCell class] style:WYTableViewRegisterStyleCell];
    
    UILabel *label = nil;
//    [label wy_addRichTexts:@[@"1"] handler:^(NSString * _Nonnull text, NSRange range, NSInteger index) {
//            
//    }];
//    [label wy_addRichTexts:@[@""] delegate:self];
}

- (void)clearVisual:(UIView *)visualView {
    visualView.wy_clearVisual();
}

- (void)test {
    
    //[[UIApplication sharedApplication] wy_switchAppDisplayBrightness:UIUserInterfaceStyleDark];
    
//    [UIAlertController wy_showStyle:UIAlertControllerStyleActionSheet title:@"测试标题" message:@"测试消息" duration:0 actionSheetNeedCancel:YES textFieldPlaceholders:@[@"占位文本1", @"占位文本2"] actions:@[@"按钮1", @"按钮2"] handler:^(NSString * _Nonnull action, NSArray<NSString *> * _Nonnull inputTexts) {
//        NSLog(@"action = %@, inputTexts = %@",action, inputTexts);
//    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [[UIApplication sharedApplication] wy_switchAppDisplayBrightness:UIUserInterfaceStyleDark];
}

@end
