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
    
    CGFloat spacing = [UIDevice wy_screenWidth:10 pixels:WYBasisKitConfig.defaultScreenPixels];
    CGFloat topSpacing = [UIDevice wy_screenHeight:80 pixels:WYBasisKitConfig.defaultScreenPixels];
    CGFloat rowSpacing = [UIDevice wy_screenHeight:50 pixels:WYBasisKitConfig.defaultScreenPixels];
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scrollView];
    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:contentView];
    [NSLayoutConstraint activateConstraints:@[
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [contentView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [contentView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor]
    ]];
    UIViewContentMode contentMode = UIViewContentModeScaleAspectFit;
    
    UIImageView *oneGifView = [[UIImageView alloc] init];
    oneGifView.contentMode = contentMode;
    [contentView addSubview:oneGifView];
    [oneGifView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(contentView).offset(spacing);
        make.top.equalTo(contentView).offset(topSpacing);
        make.width.equalTo(contentView).multipliedBy(1.0 / 3).offset(-spacing * 4 / 3);
        make.height.equalTo(oneGifView.mas_width);
    }];
    
    UIImageView *animatedGifView = [[UIImageView alloc] init];
    animatedGifView.contentMode = contentMode;
    [contentView addSubview:animatedGifView];
    [animatedGifView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(contentView);
        make.top.equalTo(contentView).offset(topSpacing);
        make.width.equalTo(contentView).multipliedBy(1.0 / 3).offset(-spacing * 4 / 3);
        make.height.equalTo(animatedGifView.mas_width);
    }];
    
    UIImageView *customGifView = [[UIImageView alloc] init];
    customGifView.contentMode = contentMode;
    [contentView addSubview:customGifView];
    [customGifView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(contentView).offset(-spacing);
        make.top.equalTo(contentView).offset(topSpacing);
        make.width.equalTo(contentView).multipliedBy(1.0 / 3).offset(-spacing * 4 / 3);
        make.height.equalTo(customGifView.mas_width);
    }];
    
    UIImageView *oneApngView = [[UIImageView alloc] init];
    oneApngView.contentMode = contentMode;
    [contentView addSubview:oneApngView];
    [oneApngView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(contentView).offset(spacing);
        make.top.equalTo(oneGifView.mas_bottom).offset(rowSpacing);
        make.width.equalTo(contentView).multipliedBy(1.0 / 3).offset(-spacing * 4 / 3);
        make.height.equalTo(oneApngView.mas_width);
    }];
    
    UIImageView *animatedApngView = [[UIImageView alloc] init];
    animatedApngView.contentMode = contentMode;
    [contentView addSubview:animatedApngView];
    [animatedApngView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(contentView);
        make.top.equalTo(oneGifView.mas_bottom).offset(rowSpacing);
        make.width.equalTo(contentView).multipliedBy(1.0 / 3).offset(-spacing * 4 / 3);
        make.height.equalTo(animatedApngView.mas_width);
    }];
    
    UIImageView *customApngView = [[UIImageView alloc] init];
    customApngView.contentMode = contentMode;
    customApngView.layer.masksToBounds = YES;
    [contentView addSubview:customApngView];
    [customApngView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(contentView).offset(-spacing);
        make.top.equalTo(oneGifView.mas_bottom).offset(rowSpacing);
        make.width.equalTo(contentView).multipliedBy(1.0 / 3).offset(-spacing * 4 / 3);
        make.height.equalTo(customApngView.mas_width);
        make.bottom.equalTo(contentView).offset(-topSpacing);
    }];
    
    // 修复：三个 imageView 的 contentMode 都设置为 oneGifView 的问题
    animatedGifView.contentMode = contentMode;
    customGifView.contentMode = contentMode;
    
    WYGifInfo *apngInfo = [UIImage wy_animatedParse:WYAnimatedImageStyleAPNG imageName:@"连线主播"];
    
    WYGifInfo *gifInfo = [UIImage wy_animatedParse:WYAnimatedImageStyleGIF imageName:@"关注主播"];
    
    // 直接显示解析得到的图片(实际上就是无限循环播放)
    oneGifView.image = gifInfo.animatedImage;
    oneApngView.image = apngInfo.animatedImage;
    
    // 只播放一次解析得到的图片
    NSArray<UIImageView *> *animatedImageViews = @[animatedGifView, animatedApngView];
    for (UIImageView *imageView in animatedImageViews) {
        if (imageView == animatedGifView) {
            imageView.animationImages = gifInfo.animationImages;
            imageView.animationDuration = gifInfo.animationDuration;
        } else {
            imageView.animationImages = apngInfo.animationImages;
            imageView.animationDuration = apngInfo.animationDuration;
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
            imageView.animationImages = gifInfo.animationImages;
            imageView.animationDuration = gifInfo.animationDuration;
        } else {
            imageView.animationImages = apngInfo.animationImages;
            imageView.animationDuration = apngInfo.animationDuration;
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
    wy_print(@"release");
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
