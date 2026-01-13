//
//  WYParseGifController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/12.
//

#import "WYParseGifController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYParseGifController ()

@end

@implementation WYParseGifController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat widthHeight = ([UIScreen mainScreen].bounds.size.width - 40) / 3;
    UIViewContentMode contentMode = UIViewContentModeScaleAspectFit;
    
    UIImageView *oneGifView = [[UIImageView alloc] init];
    oneGifView.contentMode = contentMode;
    [self.view addSubview:oneGifView];
    [oneGifView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(10);
        make.top.equalTo(self.view).offset([UIDevice wy_navViewHeight] + 80);
        make.width.height.equalTo(@(widthHeight));
    }];
    
    UIImageView *animatedGifView = [[UIImageView alloc] init];
    animatedGifView.contentMode = contentMode;
    [self.view addSubview:animatedGifView];
    [animatedGifView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset([UIDevice wy_navViewHeight] + 80);
        make.width.height.equalTo(@(widthHeight));
    }];
    
    UIImageView *customGifView = [[UIImageView alloc] init];
    customGifView.contentMode = contentMode;
    [self.view addSubview:customGifView];
    [customGifView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-10);
        make.top.equalTo(self.view).offset([UIDevice wy_navViewHeight] + 80);
        make.width.height.equalTo(@(widthHeight));
    }];
    
    UIImageView *oneApngView = [[UIImageView alloc] init];
    oneApngView.contentMode = contentMode;
    [self.view addSubview:oneApngView];
    [oneApngView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(10);
        make.top.equalTo(self.view).offset([UIDevice wy_navViewHeight] + 80 + widthHeight + 50);
        make.width.height.equalTo(@(widthHeight));
    }];
    
    UIImageView *animatedApngView = [[UIImageView alloc] init];
    animatedApngView.contentMode = contentMode;
    [self.view addSubview:animatedApngView];
    [animatedApngView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset([UIDevice wy_navViewHeight] + 80 + widthHeight + 50);
        make.width.height.equalTo(@(widthHeight));
    }];
    
    UIImageView *customApngView = [[UIImageView alloc] init];
    customApngView.contentMode = contentMode;
    customApngView.layer.masksToBounds = YES;
    [self.view addSubview:customApngView];
    [customApngView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-10);
        make.top.equalTo(self.view).offset([UIDevice wy_navViewHeight] + 80 + widthHeight + 50);
        make.width.height.equalTo(@(widthHeight));
    }];
    
    // 修复：三个 imageView 的 contentMode 都设置为 oneGifView 的问题
    animatedGifView.contentMode = contentMode;
    customGifView.contentMode = contentMode;
    
    WYGifInfo *apngInfo1 = [UIImage wy_animatedParse:WYAnimatedImageStyleAPNG imageName:@"apng格式图片1"];
    WYGifInfo *apngInfo2 = [UIImage wy_animatedParse:WYAnimatedImageStyleAPNG imageName:@"apng格式图片2"];
    
    WYGifInfo *gifInfo1 = [UIImage wy_animatedParse:WYAnimatedImageStyleGIF imageName:@"动图1"];
    WYGifInfo *gifInfo2 = [UIImage wy_animatedParse:WYAnimatedImageStyleGIF imageName:@"动图2"];
    
    // 直接显示解析得到的图片(实际上就是无限循环播放)
    oneGifView.image = gifInfo2.animatedImage;
    oneApngView.image = apngInfo2.animatedImage;
    
    // 只播放一次解析得到的图片
    NSArray<UIImageView *> *animatedImageViews = @[animatedGifView, animatedApngView];
    for (UIImageView *imageView in animatedImageViews) {
        if (imageView == animatedGifView) {
            imageView.animationImages = gifInfo1.animationImages;
            imageView.animationDuration = gifInfo1.animationDuration;
        } else {
            imageView.animationImages = apngInfo1.animationImages;
            imageView.animationDuration = apngInfo1.animationDuration;
        }
        imageView.animationRepeatCount = 1;
        [imageView startAnimating];
        
        [UIView animateWithDuration:imageView.animationDuration animations:^{
            // 空动画块，只是为了延迟
        } completion:^(BOOL finished) {
            imageView.image = imageView.animationImages.lastObject;
        }];
    }
    
    // 无限循环播放(和直接调用解析得到的animatedImage效果一样)
    NSArray<UIImageView *> *customImageViews = @[customGifView, customApngView];
    for (UIImageView *imageView in customImageViews) {
        if (imageView == customGifView) {
            imageView.animationImages = gifInfo2.animationImages;
            imageView.animationDuration = gifInfo2.animationDuration;
        } else {
            imageView.animationImages = apngInfo2.animationImages;
            imageView.animationDuration = apngInfo2.animationDuration;
        }
        // 0 表示无限循环播放
        imageView.animationRepeatCount = 0;
        [imageView startAnimating];
        
        [UIView animateWithDuration:imageView.animationDuration animations:^{
            // 空动画块，只是为了延迟
        } completion:^(BOOL finished) {
            imageView.image = imageView.animationImages.lastObject;
        }];
    }
}

- (void)dealloc {
    WYLog(@"release");
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
