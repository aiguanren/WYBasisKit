//
//  WYCenterController.m
//  ObjCVerify
//
//  Created by guanren on 2025/10/1.
//

#import "WYCenterController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYCenterController ()

@end

@implementation WYCenterController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];

    UIView *testView = [[UIView alloc] init];
    testView.backgroundColor = UIColor.purpleColor;
    testView.frame = CGRectMake(20, 200, UIDevice.wy_screenWidth - 40, 300);
    [self.view addSubview:testView];

    UIView *testView2 = [[UIView alloc] init];
    testView2.backgroundColor = UIColor.greenColor;
    testView2.frame = CGRectMake(10, 100, UIDevice.wy_screenWidth - 60, 200);
    [testView addSubview:testView2];
    
    // 添加虚线图层
    [testView.layer addSublayer:[CALayer wy_drawDashLine:WYDashDirectionLeftToRight bounds:CGRectMake([UIDevice wy_screenWidth:10 pixels:WYBasisKitConfig.defaultScreenPixels], 100, [UIDevice wy_screenWidth:315 pixels:WYBasisKitConfig.defaultScreenPixels], [UIDevice wy_screenWidth:2.5 pixels:WYBasisKitConfig.defaultScreenPixels]) color:[UIColor orangeColor] length:[UIDevice wy_screenWidth:10 pixels:WYBasisKitConfig.defaultScreenPixels] spacing:[UIDevice wy_screenWidth:5 pixels:WYBasisKitConfig.defaultScreenPixels]]];
    
    [testView.layer addSublayer:[CALayer wy_drawDashLine:WYDashDirectionTopToBottom bounds:CGRectMake([UIDevice wy_screenWidth:10 pixels:WYBasisKitConfig.defaultScreenPixels], 100, [UIDevice wy_screenWidth:2.5 pixels:WYBasisKitConfig.defaultScreenPixels], [UIDevice wy_screenWidth:190 pixels:WYBasisKitConfig.defaultScreenPixels]) color:[UIColor blackColor] length:[UIDevice wy_screenWidth:10 pixels:WYBasisKitConfig.defaultScreenPixels] spacing:[UIDevice wy_screenWidth:5 pixels:WYBasisKitConfig.defaultScreenPixels]]];
    
    [self.view.layer addSublayer:[CALayer wy_drawDashLine:WYDashDirectionLeftToRight bounds:CGRectMake(20, 200, UIDevice.wy_screenWidth - 40, 2.5) color:[UIColor orangeColor] length:[UIDevice wy_screenWidth:10 pixels:WYBasisKitConfig.defaultScreenPixels] spacing:[UIDevice wy_screenWidth:5 pixels:WYBasisKitConfig.defaultScreenPixels]]];
    
    [self.view.layer addSublayer:[CALayer wy_drawDashLine:WYDashDirectionTopToBottom bounds:CGRectMake(10, 100, 2.5, UIDevice.wy_screenWidth-60) color:[UIColor blackColor] length:[UIDevice wy_screenWidth:10 pixels:WYBasisKitConfig.defaultScreenPixels] spacing:[UIDevice wy_screenWidth:5 pixels:WYBasisKitConfig.defaultScreenPixels]]];
    
    // 图片视图
    UIImage *image = [[UIImage wy_find:@"WYBasisKit_60*60"] wy_cuttingRoundWithBorderWidth:0 borderColor:[UIColor clearColor]];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeCenter;
    imageView.backgroundColor = UIColor.wy_random;
    [self.view addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(150, 150));
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-150);
    }];

    // 左边线
    UIView *leftLineView = [[UIView alloc] init];
    leftLineView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:leftLineView];
    [leftLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(imageView);
        make.right.equalTo(imageView.mas_centerX).offset(-30);
        make.height.mas_equalTo(60);
        make.width.mas_equalTo(2);
    }];

    // 底部线
    UIView *bottomLineView = [[UIView alloc] init];
    bottomLineView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:bottomLineView];
    [bottomLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(imageView);
        make.top.equalTo(imageView.mas_centerY).offset(30);
        make.height.mas_equalTo(2);
        make.width.mas_equalTo(64);
    }];

    // 右边线
    UIView *rightLineView = [[UIView alloc] init];
    rightLineView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:rightLineView];
    [rightLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(imageView);
        make.left.equalTo(imageView.mas_centerX).offset(30);
        make.height.mas_equalTo(60);
        make.width.mas_equalTo(2);
    }];
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
