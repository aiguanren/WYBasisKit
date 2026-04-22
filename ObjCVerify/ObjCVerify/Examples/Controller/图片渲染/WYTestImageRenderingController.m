//
//  WYTestImageRenderingController.m
//  ObjCVerify
//
//  Created by guanren on 2026/3/24.
//

#import "WYTestImageRenderingController.h"
#import <SDWebImage/SDWebImage.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestImageRenderingController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView1;

@property (weak, nonatomic) IBOutlet UIImageView *imageView2;

@property (weak, nonatomic) IBOutlet UIImageView *imageView3;

@property (weak, nonatomic) IBOutlet UIImageView *imageView4;

@property (weak, nonatomic) IBOutlet UIImageView *imageView5;

@property (weak, nonatomic) IBOutlet UIImageView *imageView6;

@property (weak, nonatomic) IBOutlet UIImageView *imageView7;

@end

@implementation WYTestImageRenderingController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSString *webpPath = [[NSBundle mainBundle] pathForResource:@"彩色花" ofType:@"webp"];
    NSURL *webpUrl = [NSURL fileURLWithPath:webpPath];
    [_imageView3 sd_setImageWithURL:webpUrl];
    
    _imageView4.image = [_imageView4.image wy_renderingColor:[UIColor wy_hex:@"969696"]];
    _imageView5.image = [_imageView5.image wy_renderingColor:[UIColor wy_hex:@"969696"]];
    
    UIColor *renderingColor = [UIColor redColor];
    
    SDImageCache *cache = [SDImageCache sharedImageCache];
    
    NSString *urlString = @"https://img2.baidu.com/it/u=1992834630,4261363621&fm=253&fmt=auto&app=138&f=JPEG.webp";
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *urlCacheKey = [NSString stringWithFormat:@"%@_%@", urlString, @(renderingColor.hash)];
    NSString *urlTaskId = [[NSUUID UUID] UUIDString];
    self.imageView6.accessibilityIdentifier = urlTaskId;
    [self.imageView6 sd_setImageWithURL:url
                       placeholderImage:nil
                                options:SDWebImageAvoidAutoSetImage
                              completed:^(UIImage * _Nullable image,
                                          NSError * _Nullable error,
                                          SDImageCacheType cacheType,
                                          NSURL * _Nullable imageURL) {
        if (!image || error) {
            WYLogManager.output([NSString stringWithFormat:@"加载失败：%@", error.localizedDescription]);
            return;
        }
        
        UIImage *sourceImage = image;
        
        // 查询缓存
        [cache queryImageForKey:urlCacheKey
                        options:SDImageCacheQueryMemoryDataSync | SDImageCacheQueryDiskDataSync
                        context:nil
                      cacheType:SDImageCacheTypeAll
                     completion:^(UIImage * _Nullable cacheImage,
                                  NSData * _Nullable data,
                                  SDImageCacheType cacheType) {
            
            // 执行渲染操作
            void (^render)(void) = ^{
                [sourceImage wy_renderingColor:renderingColor completion:^(UIImage * _Nonnull renderingImage) {
                    
                    // 校验任务
                    if (![self.imageView6.accessibilityIdentifier isEqualToString:urlTaskId]) return;
                    
                    // 写入缓存并更新显示图片
                    [cache storeImage:renderingImage forKey:urlCacheKey completion:nil];
                    self.imageView6.image = renderingImage;
                }];
            };
            
            if (cacheImage && [self.imageView6.accessibilityIdentifier isEqualToString:urlTaskId]) {
                // 命中缓存 + 校验任务
                self.imageView6.image = cacheImage;
            } else {
                // 未命中 or 查询失败
                render();
            }
        }];
    }];
    
    
    NSString *pathCacheKey = [NSString stringWithFormat:@"%@_%@", webpPath, @(renderingColor.hash)];
    NSString *pathTaskId = [[NSUUID UUID] UUIDString];
    self.imageView7.accessibilityIdentifier = pathTaskId;
    UIImage *sourceImage = [UIImage imageWithContentsOfFile:webpUrl.path];
    
    // 查询缓存
    [cache queryImageForKey:pathCacheKey
                    options:SDImageCacheQueryMemoryDataSync | SDImageCacheQueryDiskDataSync
                    context:nil
                  cacheType:SDImageCacheTypeAll
                 completion:^(UIImage * _Nullable cacheImage,
                              NSData * _Nullable data,
                              SDImageCacheType cacheType) {
        
        // 执行渲染操作
        void (^render)(void) = ^{
            UIImage *renderingImage = [sourceImage wy_renderingColor:renderingColor];
            
            // 校验任务
            if (![self.imageView7.accessibilityIdentifier isEqualToString:pathTaskId]) return;
            
            // 写入缓存并更新显示图片
            [cache storeImage:renderingImage forKey:pathCacheKey completion:nil];
            self.imageView7.image = renderingImage;
        };
        
        if (cacheImage && [self.imageView7.accessibilityIdentifier isEqualToString:pathTaskId]) {
            
            // 命中缓存 + 校验任务
            self.imageView7.image = cacheImage;
        } else {
            // 未命中 or 查询失败
            render();
        }
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
