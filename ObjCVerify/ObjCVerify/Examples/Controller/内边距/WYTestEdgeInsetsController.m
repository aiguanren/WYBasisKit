//
//  WYTestEdgeInsetsController.m
//  ObjCVerify
//
//  Created by guanren on 2025/10/17.
//

#import "WYTestEdgeInsetsController.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>
#import <Masonry/Masonry.h>

@interface WYTestEdgeInsetsController ()

@end

@implementation WYTestEdgeInsetsController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = [NSString wy_randomWithMinimum:5 maximum:26];
    label.font = [UIFont boldSystemFontOfSize:15];
    label.numberOfLines = 0;
    label.backgroundColor = [UIColor wy_random];
    label.wy_contentInsets = UIEdgeInsetsMake(10, 10, 20, 30);
    label.textColor = [UIColor wy_random];
    [self.view addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.width.mas_lessThanOrEqualTo(UIDevice.wy_screenWidth - 50);
        make.top.equalTo(self.view).mas_offset(UIDevice.wy_navViewHeight + 20);
    }];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.wy_nTitle = @"wy_adjust";
    button.wy_nImage = [UIImage wy_find:@"tabbar_right_selected"];
    [button wy_makeVisual:^(UIView * _Nonnull make) {
        make.wy_cornerRadius(5);
        make.wy_borderWidth(1);
        make.wy_borderColor([UIColor wy_random]);
    }];
    button.wy_title_nColor = [UIColor redColor];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [self.view addSubview:button];
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(10);
        make.right.equalTo(self.view).offset(-10);
        make.height.equalTo(@100);
        make.top.equalTo(label.mas_bottom).mas_offset(20);
    }];
    [button wy_adjustPosition:WYButtonPositionImageRightTitleLeft spacing:5];
    
    UIButton *itemButton = [UIButton buttonWithType:UIButtonTypeCustom];
    itemButton.backgroundColor = [UIColor wy_random];
    itemButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    itemButton.imageView.backgroundColor = [UIColor wy_random];
    itemButton.titleLabel.backgroundColor = [UIColor wy_random];
    itemButton.wy_titleRect = CGRectMake(10, 10, 80, 30);
    itemButton.wy_imageRect = CGRectMake(100, 10, 80, 80);
    itemButton.wy_nTitle = @"frame";
    itemButton.wy_nImage = [UIImage wy_find:@"tabbar_right_selected"];
    itemButton.wy_cornerRadius(5).wy_borderWidth(1).wy_borderColor(UIColor.wy_random).wy_showVisual();
    itemButton.wy_title_nColor = [UIColor orangeColor];
    [self.view addSubview:itemButton];
    [itemButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(10);
        make.right.equalTo(self.view).offset(-10);
        make.height.equalTo(@100);
        make.centerY.equalTo(button.mas_bottom).offset(100);
    }];
    
    if (@available(iOS 15.0, *)) {
        
        UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
        
        config.title = @"config按钮";
        config.image = [UIImage wy_find:@"tabbar_right_selected"];
        config.imagePlacement = NSDirectionalRectEdgeTop;        // 图片在上，文字在下
        config.imagePadding = 5;
        config.contentInsets = NSDirectionalEdgeInsetsMake(20, 30, 20, 30);
        
        UIButton *configButton = [UIButton buttonWithConfiguration:config primaryAction:nil];
        
        configButton.backgroundColor = [UIColor wy_random];
        
        configButton.titleLabel.backgroundColor = [UIColor wy_random];
        configButton.imageView.backgroundColor = [UIColor wy_random];
        
        configButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        
        [self.view addSubview:configButton];
        
        [configButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.view).offset(10);
            make.centerY.equalTo(itemButton.mas_bottom).offset(100);
        }];
        
        [configButton wy_adjustPosition:WYButtonPositionImageTopTitleBottom spacing:10];
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
