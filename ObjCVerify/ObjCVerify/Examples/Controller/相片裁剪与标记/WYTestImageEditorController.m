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

/// 是否用自定义外观(一组覆盖多项外观属性的示例值)
@property (nonatomic, assign) BOOL useCustomAppearance;

/// 编辑时图片是否支持捏合缩放
@property (nonatomic, assign) BOOL allowsImageZoom;

/// 进入页面时图片初始缩放倍数(1为适配)
@property (nonatomic, assign) CGFloat initialImageZoomScale;

/// 标记颜色
@property (nonatomic, strong) UIColor *markerColor;

/// 标记线宽(0表示自动)
@property (nonatomic, assign) CGFloat markerLineWidth;

/// 文本字号(0表示自动)
@property (nonatomic, assign) CGFloat markerTextFontSize;

/// 划线默认形态(true为直线)
@property (nonatomic, assign) BOOL lineDrawsStraight;

/// 界面是否显示粗细字号选择行
@property (nonatomic, assign) BOOL showsStyleOptions;

/// 界面是否显示颜色选择条
@property (nonatomic, assign) BOOL showsColorOptions;

/// 测试图片名字(nil表示用生成的标尺图)
@property (nonatomic, copy, nullable) NSString *testImageName;

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
    _allowsImageZoom = YES;
    _initialImageZoomScale = 1;
    _allowsMarking = YES;
    _showsStyleOptions = YES;
    _showsColorOptions = YES;
    _markerColor = [UIColor whiteColor];
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

    UIButton *colorButton = [self createButtonWithTitle:@"标记颜色(白)"
                                               selector:@selector(colorButtonTapped:)
                                              superView:contentView
                                               leftView:croppingButton
                                                topView:shapeButton
                                                 isRight:NO
                                                  isLast:NO];

    [self createButtonWithTitle:@"线条宽度(自动)"
                       selector:@selector(lineWidthButtonTapped:)
                      superView:contentView
                       leftView:colorButton
                        topView:shapeButton
                         isRight:YES
                          isLast:NO];

    UIButton *fontSizeButton = [self createButtonWithTitle:@"文本字号(自动)"
                                                  selector:@selector(fontSizeButtonTapped:)
                                                 superView:contentView
                                                  leftView:nil
                                                   topView:croppingButton
                                                    isRight:NO
                                                     isLast:NO];

    UIButton *lineShapeButton = [self createButtonWithTitle:@"划线形态(自由)"
                                                   selector:@selector(lineShapeButtonTapped:)
                                                  superView:contentView
                                                   leftView:fontSizeButton
                                                    topView:croppingButton
                                                     isRight:NO
                                                      isLast:NO];
    [lineShapeButton setTitle:@"划线形态(直线)" forState:UIControlStateSelected];

    [self createButtonWithTitle:@"(显示)粗细字号行"
                       selector:@selector(styleRowButtonTapped:)
                      superView:contentView
                       leftView:lineShapeButton
                        topView:croppingButton
                         isRight:YES
                          isLast:NO];

    UIButton *colorRowButton = [self createButtonWithTitle:@"(显示)颜色条"
                                                 selector:@selector(colorRowButtonTapped:)
                                                superView:contentView
                                                 leftView:nil
                                                  topView:fontSizeButton
                                                   isRight:NO
                                                    isLast:NO];
    [colorRowButton setTitle:@"(隐藏)颜色条" forState:UIControlStateSelected];

    UIButton *imageButton = [self createButtonWithTitle:@"测试图片(标尺横图)"
                                               selector:@selector(imageButtonTapped:)
                                              superView:contentView
                                               leftView:colorRowButton
                                                topView:fontSizeButton
                                                 isRight:NO
                                                  isLast:NO];

    UIButton *appearanceButton = [self createButtonWithTitle:@"外观(默认)"
                                                   selector:@selector(appearanceButtonTapped:)
                                                  superView:contentView
                                                   leftView:imageButton
                                                    topView:fontSizeButton
                                                     isRight:YES
                                                      isLast:NO];
    [appearanceButton setTitle:@"外观(自定义)" forState:UIControlStateSelected];

    UIButton *blockButton = [self createButtonWithTitle:@"Block方式\n打开编辑器"
                                               selector:@selector(blockButtonTapped)
                                              superView:contentView
                                               leftView:nil
                                                topView:colorRowButton
                                                 isRight:NO
                                                  isLast:NO];

    UIButton *delegateButton = [self createButtonWithTitle:@"Delegate方式\n打开编辑器"
                                                 selector:@selector(delegateButtonTapped)
                                                superView:contentView
                                                 leftView:blockButton
                                                  topView:colorRowButton
                                                   isRight:NO
                                                    isLast:NO];

    [self createButtonWithTitle:@"静态方法\n一行打开"
                       selector:@selector(staticButtonTapped)
                      superView:contentView
                       leftView:delegateButton
                        topView:colorRowButton
                         isRight:YES
                          isLast:NO];

    UIButton *clearButton = [self createButtonWithTitle:@"清除结果"
                                                selector:@selector(clearButtonTapped)
                                               superView:contentView
                                                leftView:nil
                                                 topView:blockButton
                                                  isRight:NO
                                                   isLast:YES];

    UIButton *zoomButton = [self createButtonWithTitle:@"(可缩放)图片"
                                              selector:@selector(zoomButtonTapped:)
                                             superView:contentView
                                              leftView:clearButton
                                               topView:blockButton
                                                isRight:NO
                                                 isLast:NO];
    [zoomButton setTitle:@"(禁用)缩放" forState:UIControlStateSelected];

    [self createButtonWithTitle:@"初始缩放(1倍)"
                       selector:@selector(initialZoomButtonTapped:)
                      superView:contentView
                       leftView:zoomButton
                        topView:blockButton
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
    if (self.useCustomAppearance) {
        WYImageEditorAppearanceObjC *appearance = [[WYImageEditorAppearanceObjC alloc] init];
        appearance.topBarCropButtonColor = UIColor.systemYellowColor;
        appearance.selectionDashColor = UIColor.systemRedColor;
        appearance.selectionDashWidth = 2.5;
        appearance.selectionInset = 10;
        appearance.handleColor = UIColor.systemYellowColor;
        appearance.maskDimmingAmount = 0.8;
        appearance.accentColor = UIColor.systemGreenColor;
        appearance.segmentedSelectedBackgroundColor = UIColor.systemGreenColor;
        appearance.segmentedSelectedTextColor = UIColor.whiteColor;
        appearance.markerPalette = @[UIColor.whiteColor, UIColor.redColor, UIColor.yellowColor];
        appearance.lineWidthRatios = @[@0.5, @2, @4];
        appearance.canvasBackgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
        appearance.iconButtonColor = UIColor.whiteColor;
        appearance.iconButtonHighlightedColor = UIColor.systemYellowColor;
        appearance.lineWidthHintText = @"笔刷\n宽度";
        appearance.fontSizeHintText = @"字体\n大小";
        configuration.appearance = appearance;
    }
    configuration.allowsImageZoom = self.allowsImageZoom;
    configuration.initialImageZoomScale = self.initialImageZoomScale;
    configuration.markerColor = self.markerColor;
    configuration.markerLineWidth = self.markerLineWidth;
    configuration.markerTextFontSize = self.markerTextFontSize;
    configuration.lineDrawsStraight = self.lineDrawsStraight;
    configuration.showsStyleOptions = self.showsStyleOptions;
    configuration.showsColorOptions = self.showsColorOptions;
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
    NSString *lineWidthText = self.markerLineWidth == 0 ? @"自动" : [NSString stringWithFormat:@"%.0f", self.markerLineWidth];
    NSString *fontSizeText = self.markerTextFontSize == 0 ? @"自动" : [NSString stringWithFormat:@"%.0f", self.markerTextFontSize];
    NSString *lineShapeText = self.lineDrawsStraight ? @"直线" : @"自由";
    NSString *styleRowText = self.showsStyleOptions ? @"显示" : @"隐藏";
    NSString *colorRowText = self.showsColorOptions ? @"显示" : @"隐藏";
    NSString *imageSourceText = self.testImageName.length > 0 ? self.testImageName : @"标尺图";
    NSString *croppingText = self.allowsCropping ? @"允许" : @"关闭";
    NSString *appearanceText = self.useCustomAppearance ? @"自定义" : @"默认";
    NSString *zoomText = self.allowsImageZoom ? @"可缩放" : @"禁缩放";
    wy_print(@"[%@] 打开编辑器 图片=%@ 原图%.0f×%.0f 配置=形状%@ 尺寸%@ 裁剪%@ 标记%@ 线宽%@ 字号%@ 划线%@ 粗细字号行%@ 颜色条%@ 外观%@ 缩放%@", source, imageSourceText, image.size.width, image.size.height, shapeText, sizeText, croppingText, markingText, lineWidthText, fontSizeText, lineShapeText, styleRowText, colorRowText, appearanceText, zoomText);
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

/// 外观样式切换(自定义为覆盖多项外观属性的示例值)
- (void)appearanceButtonTapped:(UIButton *)sender {
    self.useCustomAppearance = !self.useCustomAppearance;
    sender.selected = self.useCustomAppearance;
}

/// 编辑时图片缩放开关(关掉后编辑器里不能捏合缩放)
- (void)zoomButtonTapped:(UIButton *)sender {
    self.allowsImageZoom = !self.allowsImageZoom;
    sender.selected = !self.allowsImageZoom;
}

/// 初始缩放倍数(输入相对适配大小的倍数)
- (void)initialZoomButtonTapped:(UIButton *)sender {
    [UIAlertController wy_showStyle:UIAlertControllerStyleAlert title:@"进入页面时图片初始缩放倍数(1为适配显示)" message:nil duration:0 actionSheetNeedCancel:NO textFieldPlaceholders:@[@"倍数"] actions:@[@"确定"] handler:^(NSString *action, NSArray<NSString *> *inputTexts) {
        if (![action isEqualToString:@"确定"]) { return; }
        double scale = [inputTexts.firstObject doubleValue];
        self.initialImageZoomScale = scale > 0 ? scale : 1;
        if (self.initialImageZoomScale == 1) {
            [sender setTitle:@"初始缩放(1倍)" forState:UIControlStateNormal];
        } else {
            [sender setTitle:[NSString stringWithFormat:@"初始缩放(%.1f倍)", self.initialImageZoomScale] forState:UIControlStateNormal];
        }
    }];
}

- (void)colorButtonTapped:(UIButton *)sender {
    NSArray *colorNames = @[@"白", @"黑", @"黄", @"红", @"绿", @"蓝", @"紫"];
    [UIAlertController wy_showStyle:UIAlertControllerStyleAlert title:@"标记颜色" message:nil actions:colorNames handler:^(NSString *action, NSArray<NSString *> *inputTexts) {
        NSUInteger index = [colorNames indexOfObject:action];
        if (index == NSNotFound) { return; }
        NSArray *colors = @[UIColor.whiteColor, UIColor.blackColor,
                            [UIColor colorWithRed:1 green:0.84 blue:0.03 alpha:1],
                            [UIColor colorWithRed:1 green:0.27 blue:0.23 alpha:1],
                            [UIColor colorWithRed:0.22 green:0.8 blue:0.35 alpha:1],
                            [UIColor colorWithRed:0.04 green:0.52 blue:1 alpha:1],
                            [UIColor colorWithRed:0.69 green:0.33 blue:0.87 alpha:1]];
        self.markerColor = colors[index];
        [sender setTitle:[NSString stringWithFormat:@"标记颜色(%@)", action] forState:UIControlStateNormal];
    }];
}

- (void)lineWidthButtonTapped:(UIButton *)sender {
    [UIAlertController wy_showStyle:UIAlertControllerStyleAlert title:@"标记线条宽度(0为按图片宽度自动)" message:nil duration:0 actionSheetNeedCancel:NO textFieldPlaceholders:@[@"线宽(像素)"] actions:@[@"确定"] handler:^(NSString *action, NSArray<NSString *> *inputTexts) {
        if (![action isEqualToString:@"确定"]) { return; }
        self.markerLineWidth = [inputTexts.firstObject doubleValue];
        [sender setTitle:self.markerLineWidth == 0 ? @"线条宽度(自动)" : [NSString stringWithFormat:@"线条宽度(%.0f)", self.markerLineWidth] forState:UIControlStateNormal];
    }];
}

- (void)fontSizeButtonTapped:(UIButton *)sender {
    [UIAlertController wy_showStyle:UIAlertControllerStyleAlert title:@"文本字号(0为按图片宽度自动)" message:nil duration:0 actionSheetNeedCancel:NO textFieldPlaceholders:@[@"字号(像素)"] actions:@[@"确定"] handler:^(NSString *action, NSArray<NSString *> *inputTexts) {
        if (![action isEqualToString:@"确定"]) { return; }
        self.markerTextFontSize = [inputTexts.firstObject doubleValue];
        [sender setTitle:self.markerTextFontSize == 0 ? @"文本字号(自动)" : [NSString stringWithFormat:@"文本字号(%.0f)", self.markerTextFontSize] forState:UIControlStateNormal];
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

/// 划线默认形态切换(自由与直线两态)
- (void)lineShapeButtonTapped:(UIButton *)sender {
    self.lineDrawsStraight = !self.lineDrawsStraight;
    sender.selected = self.lineDrawsStraight;
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
