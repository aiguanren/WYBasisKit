//
//  WYTestButtonEdgeInsetsController.m
//  ObjCVerify
//
//  Created by guanren on 2025/10/17.
//

#import "WYTestButtonEdgeInsetsController.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>
#import <Masonry/Masonry.h>

@interface WYTestButtonEdgeInsetsController ()

@end

@implementation WYTestButtonEdgeInsetsController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.wy_nTitle = @"wy_adjust";
    button.wy_nImage = [UIImage wy_find:@"tabbar_right_selected"];
    [button wy_makeVisual:^(UIView * _Nonnull make) {
        make.wy_cornerRadius(5);
        make.wy_borderWidth(1);
        make.wy_borderColor([UIColor wy_random]);
    }];
    button.wy_title_nColor = [UIColor redColor];
    [self.view addSubview:button];
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(10);
        make.right.equalTo(self.view).offset(-10);
        make.height.equalTo(@200);
        make.centerY.equalTo(self.view);
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
        make.height.equalTo(@200);
        make.centerY.equalTo(button.mas_bottom).offset(100);
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
