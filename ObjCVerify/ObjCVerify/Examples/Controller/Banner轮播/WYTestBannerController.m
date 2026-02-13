//
//  WYTestBannerController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/8.
//

#import "WYTestBannerController.h"
#import <Masonry/Masonry.h>
#import "AppEventDelegate.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestBannerController ()<WYBannerViewDelegate>

@end

@implementation WYTestBannerController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    WYBannerView *bannerView = [[WYBannerView alloc] init];
    bannerView.backgroundColor = [UIColor whiteColor];
    bannerView.delegate = self;
    
//    [bannerView updatePageControlDefaultColor:[UIColor purpleColor] currentColor:[UIColor greenColor]];
//    [bannerView updatePageControlDefaultImage:[UIImage wy_find:@"banner_dot_default"] currentImage:[UIImage wy_find:@"banner_dot_current"]];
//    bannerView.pageControlHideForSingle = YES;
//    bannerView.scrollForSinglePage = NO;
//    bannerView.imageContentMode = UIViewContentModeScaleAspectFit;
//    bannerView.unlimitedCarousel = NO;
//    bannerView.automaticCarousel = NO;
//    bannerView.describeViewPosition = CGRectMake(50, 50, 100, 20);
//    bannerView.placeholderDescribe = @"测试";
    
    NSArray *images = @[[UIImage imageNamed:@"banner_1"],
                        [UIImage imageNamed:@"banner_2"],
                        [UIImage imageNamed:@"banner_3"],
                        [UIImage imageNamed:@"banner_4"],
                        [UIImage imageNamed:@"banner_5"],
                        [UIImage imageNamed:@"banner_6"],
                        [UIImage imageNamed:@"banner_7"],
                        [UIImage imageNamed:@"banner_8"],
                        [UIImage imageNamed:@"banner_9"]];
    
    NSArray *describes = @[@"banner_1",
                           @"banner_2",
                           @"banner_3",
                           @"banner_4",
                           @"banner_5",
                           @"banner_6",
                           @"banner_7",
                           @"banner_8",
                           @"banner_9"];
    
    [bannerView reloadImages:images describes:describes];
    [self.view addSubview:bannerView];
    [bannerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.size.equalTo([NSValue valueWithCGSize:CGSizeMake(300, 600)]);
    }];
    
    [bannerView didClick:^(NSInteger index) {
        WYLog(@"Block监听，点击了第 %ld 张图片", index+1);
    }];
    
    [bannerView didScroll:^(CGFloat offset, NSInteger index) {
        WYLog(@"Block监听，滑动Banner到第 %ld 张图片了， offset = %f", index+1, offset);
    }];
    
    [WYEventHandler responseWithEvent:AppEventDidShowBannerView data:@"didShowBannerView"];
}

#pragma mark - WYBannerViewDelegate

- (void)wy_bannerViewDidClick:(WYBannerView *)bannerView index:(NSInteger)index {
    WYLog(@"代理监听，点击了第 %ld 张图片",index+1);
}

- (void)wy_bannerViewDidScroll:(WYBannerView *)bannerView offset:(CGFloat)offset index:(NSInteger)index {
    WYLog(@"代理监听，滑动Banner到第 %ld 张图片了， offset = %f", index + 1, offset);
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
