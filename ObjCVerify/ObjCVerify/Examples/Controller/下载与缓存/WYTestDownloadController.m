//
//  WYTestDownloadController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/12.
//

#import "WYTestDownloadController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestDownloadController ()

@end

@implementation WYTestDownloadController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    WYStorageData *memoryData = [WYStorage takeOutForKey:@"AAAAA"];
    UIImage *localImage = nil;
    if (memoryData.userData != nil) {
        localImage = [UIImage imageWithData:memoryData.userData];
    } else {
        WYLog(@"%@", memoryData.error);
    }
    
    UIImageView *localImageView = [[UIImageView alloc] init];
    localImageView.backgroundColor = [UIColor orangeColor];
    localImageView.image = localImage;
    [self.view addSubview:localImageView];
    [localImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(self.view);
        make.height.equalTo(@([UIDevice wy_screenHeight] / 2));
    }];
    
    UIImageView *downloadImageView = [[UIImageView alloc] init];
    downloadImageView.backgroundColor = [UIColor orangeColor];
    [self.view addSubview:downloadImageView];
    [downloadImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.equalTo(@([UIDevice wy_screenHeight] / 2));
    }];
    
    [WYActivity showLoadingIn:self.view];
    [self downloadImage:NO downloadImageView:downloadImageView localImageView:localImageView];
}

- (void)downloadImage:(BOOL)sdWebImage downloadImageView:(UIImageView *)downloadImageView localImageView:(UIImageView *)localImageView {
    
    NSString *imageUrl = @"https://pic1.zhimg.com/v2-fc20b20ea15bfd6190ddeabf5ed2b5ba_1440w.jpg";
    
    if (sdWebImage) {
        
        NSURL *cacheDirectoryURL = [WYStorage createDirectoryWithDirectory:NSCachesDirectory subDirectory:@"WYBasisKit/Download"];
        
        SDImageCache *cache = [[SDImageCache alloc] initWithNamespace:@"hahaxiazai"
                                                   diskCacheDirectory:cacheDirectoryURL.path];
        
        SDWebImageContext *context = @{
            SDWebImageContextImageCache: cache
        };
        
        [localImageView sd_setImageWithURL:[NSURL URLWithString:imageUrl] placeholderImage:[UIImage wy_createImageFromColor:[UIColor wy_random]] options:SDWebImageRetryFailed context:context progress:nil completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            
            [WYActivity dismissLoadingIn:self.view];
            
            if (image) {
                downloadImageView.image = [image wy_blurWithLevel:20];
                NSString *cacheKey = [[SDWebImageManager sharedManager] cacheKeyForURL:imageURL];
                // 缓存路径
                NSString *cachePath = [cache cachePathForKey:cacheKey];
                WYLog(@"cacheKey = %@, \nmd5 = %@, \n缓存路径 = %@", cacheKey, [imageUrl wy_sha256WithUppercase:NO], cachePath);
            } else if (error) {
                WYLog(@"%@", error);
                [WYActivity dismissLoadingIn:self.view];
            }
        }];
    } else {
        
        [WYNetworkManager downloadWithPath:imageUrl parameter:nil assetName:@"AAAAA" config:nil handler:^(WYHandler * _Nonnull result) {
            
            if (result.progress) {
                
                WYLog(@"%f", result.progress.progress);
                
            }else if (result.success) {
                
                [WYActivity dismissLoadingIn:self.view];
                
                NSError *codableError = nil;
                
                WYDownloadModel *assetObj = [WYCodable decode:result.success.origin modelClass:WYDownloadModel.class error:&codableError];
                if (codableError != nil) {
                    WYLog(@"解码失败: %@", codableError);
                    return;
                }
                
                WYLog(@"assetObj = %@", assetObj);
                
                NSString *imagePath = assetObj.assetPath ?: @"";
                UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
                downloadImageView.image = [image wy_blurWithLevel:20];
                
                NSString *diskCachePath = assetObj.diskPath ?: @"";
                NSString *asset = [NSString stringWithFormat:@"%@.%@", assetObj.assetName ?: @"", assetObj.mimeType ?: @""];
                
                WYStorageData *memoryData = [WYStorage storageForKey:@"AAAAA" data:UIImageJPEGRepresentation(image, 1.0) durable:WYStorageDurableMinute interval:2];
                if (memoryData.error == nil) {
                    WYLog(@"缓存成功 = %@", memoryData);
                    localImageView.image = [UIImage imageWithData:memoryData.userData];
                } else {
                    WYLog(@"缓存失败 = %@", memoryData.error ?: @"");
                }
                
                [WYNetworkManager clearDiskCacheWithPath:diskCachePath asset:asset completion:^(NSString * _Nullable error) {
                    if (error != nil) {
                        WYLog(@"error = %@", error);
                    } else {
                        WYLog(@"移除成功");
                    }
                }];
                
//                [WYNetworkManager clearDiskCacheWithPath:WYNetworkConfig.defaultConfig.downloadSavePath.path asset:asset completion:^(NSString * _Nullable error) {
//                    if (error != nil) {
//                        WYLog(@"error = %@", error);
//                    } else {
//                        WYLog(@"下载缓存全部移除成功");
//                    }
//                }];
                
            }else if (result.error) {
                
                WYLog(@"%@", result.error);
                [WYActivity dismissLoadingIn:self.view];
            }
        }];
    }
}

- (void)dealloc {
    WYLog(@"WYTestDownloadController released");
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
