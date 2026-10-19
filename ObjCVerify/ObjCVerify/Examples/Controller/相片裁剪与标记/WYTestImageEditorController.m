//
//  WYTestImageEditorController.m
//  ObjCVerify
//
//  Created by guanren on 2026/10/15.
//

#import "WYTestImageEditorController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

/// 结果展示cell(标题加说明加结果图预览)
@interface WYTestImageEditorResultCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIImageView *resultImageView;

- (void)configureWithTitle:(NSString *)title detail:(nullable NSString *)detail image:(nullable UIImage *)image;

@end

@interface WYTestImageEditorController () <UITableViewDelegate, UITableViewDataSource, WYImageEditorViewControllerDelegate>

/// 裁剪形状(矩形或圆形)
@property (nonatomic, assign) WYImageCropShape cropShape;

/// 是否有固定裁剪尺寸(false表示自由裁剪)
@property (nonatomic, assign) BOOL hasFixedCropSize;

/// 固定裁剪尺寸(hasFixedCropSize为true时生效)
@property (nonatomic, assign) CGSize fixedCropSize;

/// 是否允许标记
@property (nonatomic, assign) BOOL allowsMarking;

/// 是否允许裁剪
@property (nonatomic, assign) BOOL allowsCropping;

/// 裁剪页图片是否支持捏合缩放
@property (nonatomic, assign) BOOL allowsCropZoom;

/// 进入裁剪页时图片初始缩放倍数(1为适配)
@property (nonatomic, assign) CGFloat initialCropZoomScale;

/// 标记页画布是否支持捏合缩放
@property (nonatomic, assign) BOOL allowsMarkZoom;

/// 进入标记页时画布初始缩放倍数(1为适配)
@property (nonatomic, assign) CGFloat initialMarkZoomScale;

/// 界面是否显示粗细字号选择行
@property (nonatomic, assign) BOOL showsStyleOptions;

/// 界面是否显示颜色选择条
@property (nonatomic, assign) BOOL showsColorOptions;

/// 测试图片名字(nil表示用生成的标尺图)
@property (nonatomic, copy, nullable) NSString *testImageName;

/// 水印logo图(nil表示不预置)
@property (nonatomic, strong, nullable) UIImage *watermarkLogoImage;

/// 水印预填文案(nil表示用编辑器默认)
@property (nonatomic, copy, nullable) NSString *watermarkText;

/// 水印倾斜角(度)
@property (nonatomic, assign) CGFloat watermarkRotation;

/// 标尺图下标(0横图 1竖图 2方图，testImageName为nil时生效)
@property (nonatomic, assign) NSInteger rulerImageIndex;

/// 编辑成品图
@property (nonatomic, strong, nullable) UIImage *resultImage;

/// 结果来源说明
@property (nonatomic, copy) NSString *resultSource;

/// delegate方式用的编辑器入口对象(持有它保证回调不丢)
@property (nonatomic, strong) WYImageEditor *editorBridge;

@property (nonatomic, strong, nullable) UITableView *tableView;

@end

@implementation WYTestImageEditorController

- (void)viewDidLoad {
    [super viewDidLoad];

    _cropShape = WYImageCropShapeRectangle;
    _allowsCropping = YES;
    _allowsCropZoom = YES;
    _initialCropZoomScale = 1;
    _allowsMarkZoom = YES;
    _initialMarkZoomScale = 1;
    _allowsMarking = YES;
    _showsStyleOptions = YES;
    _showsColorOptions = YES;
    _watermarkRotation = -30;
    _resultSource = @"暂无结果";

    UIView *contentView = [[UIView alloc] init];
    contentView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:contentView];
    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(UIDevice.wy_navViewHeight + 20);
        make.centerX.equalTo(self.view);
    }];

    UIButton *shapeButton = [self createButtonWithTitle:@"裁剪形状(矩形)"
                                               selector:@selector(shapeButtonTapped:)
                                              superView:contentView
                                               leftView:nil
                                                topView:nil
                                                 isRight:NO
                                                  isLast:NO];
    [shapeButton setTitle:@"裁剪形状(圆形)" forState:UIControlStateSelected];

    UIButton *sizeButton = [self createButtonWithTitle:@"裁剪尺寸(自由)"
                                              selector:@selector(sizeButtonTapped:)
                                             superView:contentView
                                              leftView:shapeButton
                                               topView:nil
                                                isRight:NO
                                                 isLast:NO];

    UIButton *markingButton = [self createButtonWithTitle:@"(已允许)标记"
                                                 selector:@selector(markingButtonTapped:)
                                                superView:contentView
                                                 leftView:sizeButton
                                                  topView:nil
                                                   isRight:YES
                                                    isLast:NO];
    [markingButton setTitle:@"(已关闭)标记" forState:UIControlStateSelected];

    UIButton *croppingButton = [self createButtonWithTitle:@"(已允许)裁剪"
                                                 selector:@selector(croppingButtonTapped:)
                                                superView:contentView
                                                 leftView:nil
                                                  topView:shapeButton
                                                   isRight:NO
                                                    isLast:NO];
    [croppingButton setTitle:@"(已关闭)裁剪" forState:UIControlStateSelected];

    UIButton *styleRowButton = [self createButtonWithTitle:@"(显示)粗细字号行"
                                                  selector:@selector(styleRowButtonTapped:)
                                                 superView:contentView
                                                  leftView:croppingButton
                                                   topView:shapeButton
                                                    isRight:NO
                                                     isLast:NO];
    [styleRowButton setTitle:@"(隐藏)粗细字号行" forState:UIControlStateSelected];

    UIButton *colorRowButton = [self createButtonWithTitle:@"(显示)颜色条"
                                                 selector:@selector(colorRowButtonTapped:)
                                                superView:contentView
                                                 leftView:styleRowButton
                                                  topView:shapeButton
                                                   isRight:YES
                                                    isLast:NO];
    [colorRowButton setTitle:@"(隐藏)颜色条" forState:UIControlStateSelected];

    UIButton *cropZoomButton = [self createButtonWithTitle:@"(可缩放)裁剪页"
                                                 selector:@selector(cropZoomButtonTapped:)
                                                superView:contentView
                                                 leftView:nil
                                                  topView:colorRowButton
                                                   isRight:NO
                                                    isLast:NO];
    [cropZoomButton setTitle:@"(禁缩放)裁剪页" forState:UIControlStateSelected];

    UIButton *markZoomButton = [self createButtonWithTitle:@"(可缩放)标记页"
                                                 selector:@selector(markZoomButtonTapped:)
                                                superView:contentView
                                                 leftView:cropZoomButton
                                                  topView:colorRowButton
                                                   isRight:YES
                                                    isLast:NO];
    [markZoomButton setTitle:@"(禁缩放)标记页" forState:UIControlStateSelected];

    [self createButtonWithTitle:@"测试图片(标尺横图)"
                       selector:@selector(imageButtonTapped:)
                      superView:contentView
                       leftView:markZoomButton
                        topView:colorRowButton
                         isRight:YES
                          isLast:NO];

    UIButton *initialCropZoomButton = [self createButtonWithTitle:@"裁剪初始缩放(1倍)"
                                                        selector:@selector(initialCropZoomButtonTapped:)
                                                       superView:contentView
                                                        leftView:nil
                                                         topView:cropZoomButton
                                                          isRight:NO
                                                           isLast:NO];

    UIButton *initialMarkZoomButton = [self createButtonWithTitle:@"标记初始缩放(1倍)"
                                                        selector:@selector(initialMarkZoomButtonTapped:)
                                                       superView:contentView
                                                        leftView:initialCropZoomButton
                                                         topView:cropZoomButton
                                                          isRight:NO
                                                           isLast:NO];

    [self createButtonWithTitle:@"清除结果"
                       selector:@selector(clearButtonTapped)
                      superView:contentView
                       leftView:initialMarkZoomButton
                        topView:cropZoomButton
                         isRight:YES
                          isLast:NO];

    UIButton *watermarkImageButton = [self createButtonWithTitle:@"水印图片(无)"
                                                        selector:@selector(watermarkImageButtonTapped:)
                                                       superView:contentView
                                                        leftView:nil
                                                         topView:initialCropZoomButton
                                                          isRight:NO
                                                           isLast:NO];
    [watermarkImageButton setTitle:@"水印图片(窗花)" forState:UIControlStateSelected];

    UIButton *watermarkTextButton = [self createButtonWithTitle:@"水印文字(默认)"
                                                       selector:@selector(watermarkTextButtonTapped:)
                                                      superView:contentView
                                                       leftView:watermarkImageButton
                                                        topView:initialCropZoomButton
                                                         isRight:NO
                                                          isLast:NO];
    [watermarkTextButton setTitle:@"水印文字(官方水印)" forState:UIControlStateSelected];

    [self createButtonWithTitle:@"水印角度(-30°)"
                       selector:@selector(watermarkAngleButtonTapped:)
                      superView:contentView
                       leftView:watermarkTextButton
                        topView:initialCropZoomButton
                         isRight:YES
                          isLast:NO];

    UIButton *blockButton = [self createButtonWithTitle:@"Block方式\n打开编辑器"
                                               selector:@selector(blockButtonTapped)
                                              superView:contentView
                                               leftView:nil
                                                topView:watermarkImageButton
                                                 isRight:NO
                                                  isLast:NO];

    UIButton *delegateButton = [self createButtonWithTitle:@"Delegate方式\n打开编辑器"
                                                 selector:@selector(delegateButtonTapped)
                                                superView:contentView
                                                 leftView:blockButton
                                                  topView:watermarkImageButton
                                                   isRight:NO
                                                    isLast:NO];

    [self createButtonWithTitle:@"静态方法\n一行打开"
                       selector:@selector(staticButtonTapped)
                      superView:contentView
                       leftView:delegateButton
                        topView:watermarkImageButton
                         isRight:YES
                          isLast:YES];


    self.tableView = [UITableView wy_sharedWithStyle:UITableViewStylePlain separatorStyle:UITableViewCellSeparatorStyleSingleLine delegate:self dataSource:self backgroundColor:[UIColor whiteColor] superView:self.view];
    [self.tableView wy_register:[WYTestImageEditorResultCell class] style:WYTableViewRegisterStyleCell];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentView.mas_bottom).offset(20);
        make.left.right.bottom.equalTo(self.view);
    }];
}

- (UIButton *)createButtonWithTitle:(NSString *)title
                           selector:(SEL)selector
                          superView:(UIView *)superView
                           leftView:(nullable UIView *)leftView
                            topView:(nullable UIView *)topView
                             isRight:(BOOL)isRight
                              isLast:(BOOL)isLast {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.numberOfLines = 0;
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    [button setTitleColor:[UIColor wy_random] forState:UIControlStateNormal];
    [button wy_addBorder:UIRectEdgeAll color:[UIColor wy_random] thickness:1];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    [superView addSubview:button];
    [button mas_makeConstraints:^(MASConstraintMaker *make) {

        if (leftView != nil) {
            make.left.equalTo(leftView.mas_right).offset(15);
        }else {
            make.left.equalTo(superView);
        }

        if (isRight) {
            make.right.equalTo(superView);
        }

        if (topView != nil) {
            make.top.equalTo(topView.mas_bottom).offset(20);
        }else {
            make.top.equalTo(superView);
        }

        if (isLast) {
            make.bottom.equalTo(superView);
        }

        make.size.mas_equalTo(CGSizeMake((UIDevice.wy_screenWidth - 60) / 3, 50));
    }];

    return button;
}

/// 生成当前配置的编辑器配置对象
- (WYImageEditorConfigurationObjC *)buildConfiguration {
    WYImageEditorConfigurationObjC *configuration = [[WYImageEditorConfigurationObjC alloc] init];
    configuration.cropShape = self.cropShape;
    configuration.cropSize = self.hasFixedCropSize ? self.fixedCropSize : CGSizeZero;
    configuration.allowsCropping = self.allowsCropping;
    configuration.allowsMarking = self.allowsMarking;
    configuration.allowsCropZoom = self.allowsCropZoom;
    configuration.initialCropZoomScale = self.initialCropZoomScale;
    configuration.allowsMarkZoom = self.allowsMarkZoom;
    configuration.initialMarkZoomScale = self.initialMarkZoomScale;
    configuration.showsStyleOptions = self.showsStyleOptions;
    configuration.showsColorOptions = self.showsColorOptions;
    configuration.watermarkImage = self.watermarkLogoImage;
    configuration.watermarkText = self.watermarkText;
    configuration.watermarkRotation = self.watermarkRotation;
    return configuration;
}

/// 生成当前选中的测试图(真实图片直接取Resource目录，标尺图现场绘制)
- (UIImage *)buildTestImage {
    if (self.testImageName.length > 0) {
        UIImage *loaded = [UIImage imageNamed:self.testImageName];
        if (loaded != nil) { return loaded; }
    }
    CGSize sizes[3] = { CGSizeMake(800, 600), CGSizeMake(600, 800), CGSizeMake(700, 700) };
    CGSize imageSize = sizes[self.rulerImageIndex];

    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = 1;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:imageSize format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *rendererContext) {
        CGContextRef context = rendererContext.CGContext;

        NSArray *colors = @[(id)[UIColor colorWithRed:0.25 green:0.5 blue:0.92 alpha:1].CGColor, (id)[UIColor colorWithRed:0.98 green:0.78 blue:0.18 alpha:1].CGColor];
        CGGradientRef gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), (__bridge CFArrayRef)colors, NULL);
        CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(imageSize.width, imageSize.height), 0);
        CGGradientRelease(gradient);

        NSArray *cornerColors = @[[UIColor colorWithRed:1 green:0.27 blue:0.23 alpha:0.75], [UIColor colorWithRed:0.22 green:0.8 blue:0.35 alpha:0.75], [UIColor colorWithRed:0.04 green:0.52 blue:1 alpha:0.75], [UIColor colorWithRed:0.69 green:0.33 blue:0.87 alpha:0.75]];
        CGFloat cornerLength = 60;
        NSArray *cornerRects = @[[NSValue valueWithCGRect:CGRectMake(0, 0, cornerLength, cornerLength)],
                                [NSValue valueWithCGRect:CGRectMake(imageSize.width - cornerLength, 0, cornerLength, cornerLength)],
                                [NSValue valueWithCGRect:CGRectMake(0, imageSize.height - cornerLength, cornerLength, cornerLength)],
                                [NSValue valueWithCGRect:CGRectMake(imageSize.width - cornerLength, imageSize.height - cornerLength, cornerLength, cornerLength)]];
        for (NSUInteger index = 0; index < cornerRects.count; index++) {
            CGContextSetFillColorWithColor(context, [cornerColors[index] CGColor]);
            CGContextFillRect(context, [cornerRects[index] CGRectValue]);
        }

        CGContextSetStrokeColorWithColor(context, [UIColor.whiteColor colorWithAlphaComponent:0.7].CGColor);
        CGContextSetLineWidth(context, 1);
        CGFloat position = 100;
        while (position < imageSize.width) {
            CGContextMoveToPoint(context, position, 0);
            CGContextAddLineToPoint(context, position, imageSize.height);
            position += 100;
        }
        position = 100;
        while (position < imageSize.height) {
            CGContextMoveToPoint(context, 0, position);
            CGContextAddLineToPoint(context, imageSize.width, position);
            position += 100;
        }
        CGContextStrokePath(context);

        NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold], NSForegroundColorAttributeName: UIColor.whiteColor};
        CGFloat xLabel = 0;
        while (xLabel < imageSize.width) {
            [[NSString stringWithFormat:@"%.0f", xLabel] drawAtPoint:CGPointMake(xLabel + 3, 3) withAttributes:attributes];
            xLabel += 100;
        }
        CGFloat yLabel = 100;
        while (yLabel < imageSize.height) {
            [[NSString stringWithFormat:@"%.0f", yLabel] drawAtPoint:CGPointMake(3, yLabel + 3) withAttributes:attributes];
            yLabel += 100;
        }
    }];
}

/// 打开前打印一遍当前配置与原图信息(三种打开方式共用)
- (void)printOpenLog:(NSString *)source image:(UIImage *)image {
    NSString *shapeText = self.cropShape == WYImageCropShapeCircle ? @"圆形" : @"矩形";
    NSString *sizeText = self.hasFixedCropSize ? [NSString stringWithFormat:@"固定%.0f×%.0f", self.fixedCropSize.width, self.fixedCropSize.height] : @"自由";
    NSString *markingText = self.allowsMarking ? @"允许" : @"关闭";
    NSString *styleRowText = self.showsStyleOptions ? @"显示" : @"隐藏";
    NSString *colorRowText = self.showsColorOptions ? @"显示" : @"隐藏";
    NSString *imageSourceText = self.testImageName.length > 0 ? self.testImageName : @"标尺图";
    NSString *croppingText = self.allowsCropping ? @"允许" : @"关闭";
    NSString *cropZoomText = self.allowsCropZoom ? @"可缩放" : @"禁缩放";
    NSString *markZoomText = self.allowsMarkZoom ? @"可缩放" : @"禁缩放";
    NSString *watermarkLogoText = self.watermarkLogoImage == nil ? @"无logo" : @"有logo";
    NSString *watermarkText = self.watermarkText == nil ? @"默认" : self.watermarkText;
    wy_print(@"[%@] 打开编辑器 图片=%@ 原图%.0f×%.0f 配置=形状%@ 尺寸%@ 裁剪%@ 标记%@ 粗细字号行%@ 颜色条%@ 裁剪缩放%@ 标记缩放%@ 水印=%@预填%@角度%.0f度", source, imageSourceText, image.size.width, image.size.height, shapeText, sizeText, croppingText, markingText, styleRowText, colorRowText, cropZoomText, markZoomText, watermarkLogoText, watermarkText, self.watermarkRotation);
}

/// 记录编辑结果并刷新表格(三种打开方式共用)
- (void)handleResult:(nullable UIImage *)image source:(NSString *)source {
    if (image != nil) {
        self.resultImage = image;
        self.resultSource = source;
        wy_print(@"[%@] 编辑完成 成品图%.0f×%.0f scale=%f", source, image.size.width, image.size.height, image.scale);
    } else {
        self.resultSource = [source stringByAppendingString:@"(取消了)"];
        wy_print(@"[%@] 已取消编辑", source);
    }
    [self.tableView reloadData];
}

- (void)shapeButtonTapped:(UIButton *)sender {
    [UIAlertController wy_showStyle:UIAlertControllerStyleAlert title:@"裁剪形状" message:nil actions:@[@"矩形", @"圆形"] handler:^(NSString *action, NSArray<NSString *> *inputTexts) {
        self.cropShape = [action isEqualToString:@"圆形"] ? WYImageCropShapeCircle : WYImageCropShapeRectangle;
        sender.selected = self.cropShape == WYImageCropShapeCircle;
        [sender setTitle:[NSString stringWithFormat:@"裁剪形状(%@)", action] forState:UIControlStateNormal];
    }];
}

- (void)sizeButtonTapped:(UIButton *)sender {
    [UIAlertController wy_showStyle:UIAlertControllerStyleAlert title:@"裁剪尺寸(留空两项为自由裁剪)" message:nil duration:0 actionSheetNeedCancel:NO textFieldPlaceholders:@[@"宽(像素)", @"高(像素)"] actions:@[@"确定"] handler:^(NSString *action, NSArray<NSString *> *inputTexts) {
        if (![action isEqualToString:@"确定"]) { return; }
        double width = [inputTexts.firstObject doubleValue];
        double height = [inputTexts.lastObject doubleValue];
        if (width > 0 && height > 0) {
            self.hasFixedCropSize = YES;
            self.fixedCropSize = CGSizeMake(width, height);
            [sender setTitle:[NSString stringWithFormat:@"裁剪尺寸(固定%.0f×%.0f)", width, height] forState:UIControlStateNormal];
        } else {
            self.hasFixedCropSize = NO;
            [sender setTitle:@"裁剪尺寸(自由)" forState:UIControlStateNormal];
        }
    }];
}

- (void)markingButtonTapped:(UIButton *)sender {
    self.allowsMarking = !self.allowsMarking;
    sender.selected = !self.allowsMarking;
}

/// 允许裁剪开关(关掉后编辑器只有标记功能)
- (void)croppingButtonTapped:(UIButton *)sender {
    self.allowsCropping = !self.allowsCropping;
    sender.selected = !self.allowsCropping;
}

/// 裁剪页缩放开关(关掉后裁剪页不能捏合缩放图片)
- (void)cropZoomButtonTapped:(UIButton *)sender {
    self.allowsCropZoom = !self.allowsCropZoom;
    sender.selected = !self.allowsCropZoom;
}

/// 标记页缩放开关(关掉后标记页不能捏合缩放画布)
- (void)markZoomButtonTapped:(UIButton *)sender {
    self.allowsMarkZoom = !self.allowsMarkZoom;
    sender.selected = !self.allowsMarkZoom;
}

/// 裁剪页初始缩放倍数(输入相对适配大小的倍数)
- (void)initialCropZoomButtonTapped:(UIButton *)sender {
    [UIAlertController wy_showStyle:UIAlertControllerStyleAlert title:@"进入裁剪页时图片初始缩放倍数(1为适配显示)" message:nil duration:0 actionSheetNeedCancel:NO textFieldPlaceholders:@[@"倍数"] actions:@[@"确定"] handler:^(NSString *action, NSArray<NSString *> *inputTexts) {
        if (![action isEqualToString:@"确定"]) { return; }
        double scale = [inputTexts.firstObject doubleValue];
        self.initialCropZoomScale = scale > 0 ? scale : 1;
        if (self.initialCropZoomScale == 1) {
            [sender setTitle:@"裁剪初始缩放(1倍)" forState:UIControlStateNormal];
        } else {
            [sender setTitle:[NSString stringWithFormat:@"裁剪初始缩放(%.1f倍)", self.initialCropZoomScale] forState:UIControlStateNormal];
        }
    }];
}

/// 标记页初始缩放倍数(输入相对适配大小的倍数)
- (void)initialMarkZoomButtonTapped:(UIButton *)sender {
    [UIAlertController wy_showStyle:UIAlertControllerStyleAlert title:@"进入标记页时画布初始缩放倍数(1为适配显示)" message:nil duration:0 actionSheetNeedCancel:NO textFieldPlaceholders:@[@"倍数"] actions:@[@"确定"] handler:^(NSString *action, NSArray<NSString *> *inputTexts) {
        if (![action isEqualToString:@"确定"]) { return; }
        double scale = [inputTexts.firstObject doubleValue];
        self.initialMarkZoomScale = scale > 0 ? scale : 1;
        if (self.initialMarkZoomScale == 1) {
            [sender setTitle:@"标记初始缩放(1倍)" forState:UIControlStateNormal];
        } else {
            [sender setTitle:[NSString stringWithFormat:@"标记初始缩放(%.1f倍)", self.initialMarkZoomScale] forState:UIControlStateNormal];
        }
    }];
}

- (void)imageButtonTapped:(UIButton *)sender {
    NSArray *realImageNames = @[@"窗花", @"帆船", @"红色爱心", @"红色花", @"蓝色小屋", @"蓝天下的红色花", @"蓝天下的花", @"啤酒"];
    NSArray *rulerTitles = @[@"标尺横图(800×600)", @"标尺竖图(600×800)", @"标尺方图(700×700)"];
    [UIAlertController wy_showStyle:UIAlertControllerStyleAlert title:@"测试图片(前八项为Resource里的真实图片)" message:nil actions:[realImageNames arrayByAddingObjectsFromArray:rulerTitles] handler:^(NSString *action, NSArray<NSString *> *inputTexts) {
        NSUInteger realIndex = [realImageNames indexOfObject:action];
        if (realIndex != NSNotFound) {
            self.testImageName = realImageNames[realIndex];
            [sender setTitle:[NSString stringWithFormat:@"测试图片(%@)", realImageNames[realIndex]] forState:UIControlStateNormal];
            return;
        }
        NSUInteger rulerIndex = [rulerTitles indexOfObject:action];
        if (rulerIndex != NSNotFound) {
            self.testImageName = nil;
            self.rulerImageIndex = rulerIndex;
            NSArray *shortNames = @[@"横图", @"竖图", @"方图"];
            [sender setTitle:[NSString stringWithFormat:@"测试图片(标尺%@)", shortNames[rulerIndex]] forState:UIControlStateNormal];
        }
    }];
}

/// 水印logo图开关(开时编辑器水印语境出图片钮)
- (void)watermarkImageButtonTapped:(UIButton *)sender {
    self.watermarkLogoImage = self.watermarkLogoImage == nil ? [UIImage imageNamed:@"窗花"] : nil;
    sender.selected = self.watermarkLogoImage != nil;
}

/// 水印预填文案开关(开时落水印弹窗预填官方水印)
- (void)watermarkTextButtonTapped:(UIButton *)sender {
    self.watermarkText = self.watermarkText == nil ? @"官方水印" : nil;
    sender.selected = self.watermarkText != nil;
}

/// 水印倾斜角切换(-30度与0度水平两态)
- (void)watermarkAngleButtonTapped:(UIButton *)sender {
    self.watermarkRotation = self.watermarkRotation == -30 ? 0 : -30;
    [sender setTitle:self.watermarkRotation == -30 ? @"水印角度(-30°)" : @"水印角度(0°)" forState:UIControlStateNormal];
}

/// 界面粗细字号选择行显示开关
- (void)styleRowButtonTapped:(UIButton *)sender {
    self.showsStyleOptions = !self.showsStyleOptions;
    sender.selected = !self.showsStyleOptions;
}

/// 界面颜色选择条显示开关
- (void)colorRowButtonTapped:(UIButton *)sender {
    self.showsColorOptions = !self.showsColorOptions;
    sender.selected = !self.showsColorOptions;
}

/// Block回调方式(静态方法一行打开，handler里拿结果)
- (void)blockButtonTapped {
    UIImage *image = [self buildTestImage];
    [self printOpenLog:@"Block方式" image:image];
    [WYImageEditor showEditorWithImage:image from:self configuration:[self buildConfiguration] handler:^(UIImage *resultImage) {
        [self handleResult:resultImage source:@"Block方式"];
    }];
}

/// Delegate回调方式(持有入口对象设delegate)
- (void)delegateButtonTapped {
    UIImage *image = [self buildTestImage];
    [self printOpenLog:@"Delegate方式" image:image];
    self.editorBridge = [[WYImageEditor alloc] init];
    self.editorBridge.delegate = self;
    [self.editorBridge showEditorWithImage:image from:self configuration:[self buildConfiguration]];
}

/// editHandler方式(入口对象设Block再打开，验证editHandler属性)
- (void)staticButtonTapped {
    UIImage *image = [self buildTestImage];
    [self printOpenLog:@"editHandler方式" image:image];
    self.editorBridge = [[WYImageEditor alloc] init];
    __weak typeof(self) weakSelf = self;
    self.editorBridge.editHandler = ^(UIImage *resultImage) {
        [weakSelf handleResult:resultImage source:@"editHandler方式"];
    };
    [self.editorBridge showEditorWithImage:image from:self configuration:[self buildConfiguration]];
}

- (void)clearButtonTapped {
    self.resultImage = nil;
    self.resultSource = @"暂无结果";
    wy_print(@"已清除结果");
    [self.tableView reloadData];
}

#pragma mark - WYImageEditorDelegate

- (void)wy_imageEditorViewController:(WYImageEditorViewController *)editor didFinishEditingImage:(UIImage *)image {
    [self handleResult:image source:@"Delegate方式"];
}

- (void)wy_imageEditorViewControllerDidCancel:(WYImageEditorViewController *)editor {
    [self handleResult:nil source:@"Delegate方式"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WYTestImageEditorResultCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WYTestImageEditorResultCell" forIndexPath:indexPath];
    if (indexPath.row == 0) {
        [cell configureWithTitle:@"原图信息" detail:@"宽×高见打开日志(渐变标尺图)" image:nil];
    } else if (indexPath.row == 1) {
        [cell configureWithTitle:@"结果来源" detail:self.resultSource image:nil];
    } else {
        [cell configureWithTitle:@"结果预览" detail:nil image:self.resultImage];
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 2 && self.resultImage != nil) {
        CGFloat maxWidth = tableView.bounds.size.width - 32;
        CGFloat height = self.resultImage.size.height * maxWidth / MAX(self.resultImage.size.width, 1);
        return MAX(44, MIN(320, height) + 30);
    }
    return 60;
}

@end

@implementation WYTestImageEditorResultCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
        [self.contentView addSubview:_titleLabel];

        _detailLabel = [[UILabel alloc] init];
        _detailLabel.font = [UIFont systemFontOfSize:13];
        _detailLabel.textColor = [UIColor grayColor];
        _detailLabel.numberOfLines = 0;
        [self.contentView addSubview:_detailLabel];

        _resultImageView = [[UIImageView alloc] init];
        _resultImageView.contentMode = UIViewContentModeScaleAspectFit;
        _resultImageView.backgroundColor = [UIColor blackColor];
        _resultImageView.layer.cornerRadius = 8;
        _resultImageView.layer.masksToBounds = YES;
        [self.contentView addSubview:_resultImageView];

        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(16);
            make.top.equalTo(self.contentView).offset(10);
        }];
        [_detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_titleLabel.mas_right).offset(12);
            make.right.equalTo(self.contentView).offset(-16);
            make.top.equalTo(self.contentView).offset(12);
        }];
        [_resultImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(16);
            make.right.equalTo(self.contentView).offset(-16);
            make.top.equalTo(_titleLabel.mas_bottom).offset(10);
            make.bottom.equalTo(self.contentView).offset(-10);
        }];
    }
    return self;
}

/// 填充内容(有图显图没图隐藏)
- (void)configureWithTitle:(NSString *)title detail:(nullable NSString *)detail image:(nullable UIImage *)image {
    self.titleLabel.text = title;
    self.detailLabel.text = detail;
    self.detailLabel.hidden = detail == nil;
    self.resultImageView.image = image;
    self.resultImageView.hidden = image == nil;
}

@end
