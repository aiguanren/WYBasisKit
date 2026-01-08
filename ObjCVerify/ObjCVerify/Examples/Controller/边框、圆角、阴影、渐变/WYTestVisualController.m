//
//  WYTestVisualController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/8.
//

#import "WYTestVisualController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestVisualController ()

@end

@implementation WYTestVisualController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIView *lineView1 = [self createLineView];
    [lineView1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@1);
        make.top.equalTo(self.view).offset(UIDevice.wy_navViewHeight);
        make.bottom.equalTo(self.view);
        make.right.equalTo(self.view).offset(-20);
    }];
    
    UIView *lineView2 = [self createLineView];
    [lineView2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.top.bottom.equalTo(lineView1);
        make.right.equalTo(self.view).offset(-220);
    }];
    
    UIView *lineView3 = [self createLineView];
    [lineView3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view).offset(200);
        make.height.equalTo(@1);
    }];
    
    UIView *lineView4 = [self createLineView];
    [lineView4 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.height.equalTo(lineView3);
        make.top.equalTo(self.view).offset(300);
    }];
    
    UIView *lineView5 = [self createLineView];
    [lineView5 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.height.equalTo(lineView3);
        make.top.equalTo(self.view).offset(350);
    }];
    
    UIView *lineView6 = [self createLineView];
    [lineView6 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.top.bottom.equalTo(lineView1);
        make.right.equalTo(self.view).offset(-120);
    }];
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:button1];
    [button1 wy_backgroundColor:[UIColor orangeColor] forState:UIControlStateNormal];
    button1.titleLabel.numberOfLines = 0;
    [button1 setTitle:@"frame控件" forState:UIControlStateNormal];
    button1.wy_borderWidth(5).wy_borderColor([UIColor yellowColor]).wy_rectCorner(UIRectCornerBottomLeft | UIRectCornerTopRight).wy_cornerRadius(10).wy_shadowRadius(20).wy_shadowColor([UIColor greenColor]).wy_shadowOpacity(0.5).wy_showVisual();
    button1.frame = CGRectMake(20, 200, 100, 100);
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self action:@selector(updateButtonConstraints:) forControlEvents:UIControlEventTouchUpInside];
    button.titleLabel.numberOfLines = 0;
    [button setTitle:@"约束控件" forState:UIControlStateNormal];
    [button wy_addBorder:UIRectEdgeTop | UIRectEdgeRight color:[UIColor magentaColor] thickness:20];
    [self.view addSubview:button];
    [button wy_makeVisual:^(UIView *make) {
        make.wy_gradualColors(@[[UIColor yellowColor], [UIColor purpleColor]]);
        make.wy_gradientDirection(WYGradientDirectionLeftToLowRight);
        make.wy_borderWidth(5);
        make.wy_borderColor([UIColor blackColor]);
        make.wy_rectCorner(UIRectCornerTopRight);
        make.wy_cornerRadius(20);
        make.wy_shadowRadius(30);
        make.wy_shadowColor([UIColor greenColor]);
        make.wy_shadowOffset(CGSizeZero);
        make.wy_shadowOpacity(0.5);
        //make.wy_bezierPath([UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 100, 50)]);
    }];
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-20);
        make.top.equalTo(self.view).offset(200);
        make.size.equalTo([NSValue valueWithCGSize:CGSizeMake(100, 100)]);
    }];
    
    UIView *gradualView = [[UIView alloc] init];
    gradualView.backgroundColor = [UIColor orangeColor];
    [self.view addSubview:gradualView];
    [gradualView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20);
        make.top.equalTo(self.view).offset(500);
        make.size.equalTo([NSValue valueWithCGSize:CGSizeMake(100, 100)]);
    }];
    gradualView.wy_rectCorner(UIRectCornerAllCorners);
    gradualView.wy_cornerRadius(10);
    gradualView.wy_borderColor([UIColor blackColor]);
    gradualView.wy_borderWidth(5);
    gradualView.wy_gradualColors(@[[UIColor orangeColor],
                                   [UIColor redColor]]);
    gradualView.wy_gradientDirection(WYGradientDirectionLeftToRight);
    gradualView.wy_showVisual();
}

- (void)updateButtonConstraints:(UIButton *)button {
    [button mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-20);
        make.top.equalTo(self.view).offset(200);
        make.size.equalTo([NSValue valueWithCGSize:CGSizeMake(200, 150)]);
    }];
    button.wy_gradualColors(@[[UIColor orangeColor], [UIColor redColor]]);
    button.wy_gradientDirection(WYGradientDirectionTopToBottom);
    button.wy_borderWidth(10);
    button.wy_borderColor([UIColor purpleColor]);
    button.wy_rectCorner(UIRectCornerTopLeft);
    button.wy_cornerRadius(30);
    button.wy_shadowRadius(10);
    button.wy_shadowColor([UIColor redColor]);
    button.wy_shadowOffset(CGSizeZero);
    button.wy_shadowOpacity(0.5);
    button.wy_showVisual();
    
    [button wy_addBorder:UIRectEdgeBottom | UIRectEdgeLeft color:[UIColor magentaColor] thickness:25];
    
    [self performSelector:@selector(removeBorder:) withObject:button afterDelay:5];
}

- (void)removeBorder:(UIButton *)sender {
    [sender wy_removeBorder:UIRectEdgeTop | UIRectEdgeRight thickness:20];
}

- (UIView *)createLineView {
    UIView *lineView = [[UIView alloc] init];
    lineView.backgroundColor = [UIColor wy_random];
    [self.view addSubview:lineView];
    return lineView;
}

- (void)dealloc {
    WYLog(@"WYTestVisualController release");
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
