//
//  WYTestCombineImagesController.m
//  ObjCVerify
//
//  Created by guanren on 2026/2/11.
//

#import "WYTestCombineImagesController.h"
#import <WYBasisKitObjC.h>
#import <Masonry/Masonry.h>

@interface WYTestCombineImagesController () <UIColorPickerViewControllerDelegate>

// UI
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *resultImageView;

// 默认图片
@property (nonatomic, strong) UIImage *standardImage;
@property (nonatomic, strong) UIImage *stitchingImage;

// 参数
@property (nonatomic, assign) CGPoint stitchingCenterPoint;
@property (nonatomic, assign) CGFloat overlapControl;
@property (nonatomic, assign) CGFloat alphaValue;
@property (nonatomic, assign) CGBlendMode blendMode;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat rotationAngle;
@property (nonatomic, assign) BOOL flipHorizontal;
@property (nonatomic, assign) BOOL flipVertical;
@property (nonatomic, assign) CGFloat scaleValue;
@property (nonatomic, strong) UIColor *shadowColor;
@property (nonatomic, assign) CGFloat shadowBlur;
@property (nonatomic, assign) CGSize shadowOffset;
@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, assign) CGFloat strokeWidth;
@property (nonatomic, strong, nullable) UIImage *maskImage;

@end

@implementation WYTestCombineImagesController

// 关联对象 Key
static char kValueChangedKey;
static char kValueLabelKey;
static char kValueFormatKey;
static char kColorViewKey;
static char kPickerValueChangedKey;
static char kPickerColorViewKey;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"图片合成测试";
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    
    // 初始化参数
    self.stitchingCenterPoint = CGPointMake(150, 150);
    self.overlapControl = 0;
    self.alphaValue = 1.0;
    self.blendMode = kCGBlendModeNormal;
    self.backgroundColor = [UIColor clearColor];
    self.cornerRadius = 0;
    self.rotationAngle = 0;
    self.flipHorizontal = NO;
    self.flipVertical = NO;
    self.scaleValue = 1.0;
    self.shadowColor = [UIColor clearColor];
    self.shadowBlur = 0;
    self.shadowOffset = CGSizeZero;
    self.strokeColor = [UIColor clearColor];
    self.strokeWidth = 0;
    self.maskImage = nil;
    
    // 默认图片（假设 UIImage 有 wy_createImageFromColor:size: 方法）
    CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
    self.standardImage = [UIImage wy_createImageFromColor:[UIColor purpleColor] size:CGSizeMake(screenWidth - 40, 200)];
    self.stitchingImage = [UIImage imageNamed:@"test_stitching"] ?: [UIImage systemImageNamed:@"star.fill"];
    
    [self setupUI];
    [self setupParametersUI];
    [self combineImages];
}

#pragma mark - UI Setup

- (void)setupUI {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"合成"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(combineImages)];
    
    // 结果图片 - 固定在顶部
    self.resultImageView = [[UIImageView alloc] init];
    self.resultImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.resultImageView.backgroundColor = UIColor.secondarySystemBackgroundColor;
    self.resultImageView.layer.borderWidth = 1.0;
    self.resultImageView.layer.borderColor = UIColor.separatorColor.CGColor;
    self.resultImageView.layer.cornerRadius = 8.0;
    self.resultImageView.clipsToBounds = YES;
    [self.view addSubview:self.resultImageView];
    
    [self.resultImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(20 + UIDevice.wy_navViewHeight);
        make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 20, 0, 20));
        make.height.mas_equalTo(300);
    }];
    
    // ScrollView - 参数区
    self.scrollView = [[UIScrollView alloc] init];
    [self.view addSubview:self.scrollView];
    
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.resultImageView.mas_bottom).offset(20);
        make.left.right.bottom.equalTo(self.view);
    }];
    
    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];
    
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];
}

- (void)setupParametersUI {
    __block UIView *lastView = nil;
    
    // 1. 拼接中心点
    UIView *pointGroup = [self createPointControlWithTitle:@"拼接中心点"
                                                   xValue:self.stitchingCenterPoint.x
                                                   yValue:self.stitchingCenterPoint.y
                                                     xMin:0 xMax:300
                                                     yMin:0 yMax:300
                                                 xChanged:^(CGFloat value) {
        self.stitchingCenterPoint = CGPointMake(value, self.stitchingCenterPoint.y);
        [self combineImages];
    } yChanged:^(CGFloat value) {
        self.stitchingCenterPoint = CGPointMake(self.stitchingCenterPoint.x, value);
        [self combineImages];
    }];
    [self.contentView addSubview:pointGroup];
    [pointGroup mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(0);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
    }];
    lastView = pointGroup;
    
    // 2. 重叠控制
    UIView *overlapSlider = [self createSliderControlWithTitle:@"重叠控制"
                                                         value:(float)self.overlapControl
                                                           min:-50 max:50
                                                  valueChanged:^(float value) {
        self.overlapControl = value;
        [self combineImages];
    }];
    [self.contentView addSubview:overlapSlider];
    [overlapSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastView.mas_bottom).offset(15);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
    }];
    lastView = overlapSlider;
    
    // 3. 透明度
    UIView *alphaSlider = [self createSliderControlWithTitle:@"透明度"
                                                       value:(float)self.alphaValue
                                                         min:0 max:1
                                                valueChanged:^(float value) {
        self.alphaValue = value;
        [self combineImages];
    }];
    [self.contentView addSubview:alphaSlider];
    [alphaSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastView.mas_bottom).offset(15);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
    }];
    lastView = alphaSlider;
    
    // 4. 混合模式
    UIView *blendModeControl = [self createSegmentedControlWithTitle:@"混合模式"
                                                               items:@[@"Normal", @"Multiply", @"Screen", @"Overlay", @"Darken", @"Lighten", @"ColorDodge", @"ColorBurn"]
                                                       selectedIndex:0
                                                        valueChanged:^(NSInteger index) {
        CGBlendMode modes[] = {kCGBlendModeNormal, kCGBlendModeMultiply, kCGBlendModeScreen, kCGBlendModeOverlay,
                               kCGBlendModeDarken, kCGBlendModeLighten, kCGBlendModeColorDodge, kCGBlendModeColorBurn};
        self.blendMode = modes[index];
        [self combineImages];
    }];
    [self.contentView addSubview:blendModeControl];
    [blendModeControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastView.mas_bottom).offset(15);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
    }];
    lastView = blendModeControl;
    
    // 5. 背景颜色
    UIView *bgColorControl = [self createColorControlWithTitle:@"背景颜色"
                                                         color:self.backgroundColor
                                                  valueChanged:^(UIColor *color) {
        self.backgroundColor = color;
        [self combineImages];
    }];
    [self.contentView addSubview:bgColorControl];
    [bgColorControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastView.mas_bottom).offset(15);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
        make.height.mas_equalTo(44);
    }];
    lastView = bgColorControl;
    
    // 6. 圆角半径
    UIView *cornerSlider = [self createSliderControlWithTitle:@"圆角半径"
                                                        value:(float)self.cornerRadius
                                                          min:0 max:50
                                                 valueChanged:^(float value) {
        self.cornerRadius = value;
        [self combineImages];
    }];
    [self.contentView addSubview:cornerSlider];
    [cornerSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastView.mas_bottom).offset(15);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
    }];
    lastView = cornerSlider;
    
    // 7. 旋转角度
    UIView *rotationSlider = [self createSliderControlWithTitle:@"旋转角度"
                                                          value:(float)self.rotationAngle
                                                            min:0 max:(float)(2 * M_PI)
                                                   valueFormat:@"%.2f rad"
                                                   valueChanged:^(float value) {
        self.rotationAngle = value;
        [self combineImages];
    }];
    [self.contentView addSubview:rotationSlider];
    [rotationSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastView.mas_bottom).offset(15);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
    }];
    lastView = rotationSlider;
    
    // 8. 翻转控制
    UIView *flipControl = [self createSwitchGroupControlWithTitle:@"翻转控制"
                                                         switches:@[
        @{@"title": @"水平翻转", @"isOn": @(self.flipHorizontal), @"changed": ^(BOOL isOn) {
            self.flipHorizontal = isOn;
            [self combineImages];
        }},
        @{@"title": @"垂直翻转", @"isOn": @(self.flipVertical), @"changed": ^(BOOL isOn) {
            self.flipVertical = isOn;
            [self combineImages];
        }}
    ]];
    [self.contentView addSubview:flipControl];
    [flipControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastView.mas_bottom).offset(15);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
    }];
    lastView = flipControl;
    
    // 9. 缩放比例
    UIView *scaleSlider = [self createSliderControlWithTitle:@"缩放比例"
                                                       value:(float)self.scaleValue
                                                         min:0.1 max:3.0
                                                valueChanged:^(float value) {
        self.scaleValue = value;
        [self combineImages];
    }];
    [self.contentView addSubview:scaleSlider];
    [scaleSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastView.mas_bottom).offset(15);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
    }];
    lastView = scaleSlider;
    
    // 10. 阴影颜色
    UIView *shadowColorControl = [self createColorControlWithTitle:@"阴影颜色"
                                                             color:self.shadowColor
                                                      valueChanged:^(UIColor *color) {
        self.shadowColor = color;
        [self combineImages];
    }];
    [self.contentView addSubview:shadowColorControl];
    [shadowColorControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastView.mas_bottom).offset(15);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
        make.height.mas_equalTo(44);
    }];
    lastView = shadowColorControl;
    
    // 11. 阴影模糊
    UIView *shadowBlurSlider = [self createSliderControlWithTitle:@"阴影模糊"
                                                            value:(float)self.shadowBlur
                                                              min:0 max:20
                                                     valueChanged:^(float value) {
        self.shadowBlur = value;
        [self combineImages];
    }];
    [self.contentView addSubview:shadowBlurSlider];
    [shadowBlurSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastView.mas_bottom).offset(15);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
    }];
    lastView = shadowBlurSlider;
    
    // 12. 阴影偏移
    UIView *shadowOffsetGroup = [self createPointControlWithTitle:@"阴影偏移"
                                                          xValue:self.shadowOffset.width
                                                          yValue:self.shadowOffset.height
                                                            xMin:-20 xMax:20
                                                            yMin:-20 yMax:20
                                                        xChanged:^(CGFloat value) {
        self.shadowOffset = CGSizeMake(value, self.shadowOffset.height);
        [self combineImages];
    } yChanged:^(CGFloat value) {
        self.shadowOffset = CGSizeMake(self.shadowOffset.width, value);
        [self combineImages];
    }];
    [self.contentView addSubview:shadowOffsetGroup];
    [shadowOffsetGroup mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastView.mas_bottom).offset(15);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
    }];
    lastView = shadowOffsetGroup;
    
    // 13. 描边颜色
    UIView *strokeColorControl = [self createColorControlWithTitle:@"描边颜色"
                                                             color:self.strokeColor
                                                      valueChanged:^(UIColor *color) {
        self.strokeColor = color;
        [self combineImages];
    }];
    [self.contentView addSubview:strokeColorControl];
    [strokeColorControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastView.mas_bottom).offset(15);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
        make.height.mas_equalTo(44);
    }];
    lastView = strokeColorControl;
    
    // 14. 描边宽度
    UIView *strokeWidthSlider = [self createSliderControlWithTitle:@"描边宽度"
                                                             value:(float)self.strokeWidth
                                                               min:0 max:10
                                                      valueChanged:^(float value) {
        self.strokeWidth = value;
        [self combineImages];
    }];
    [self.contentView addSubview:strokeWidthSlider];
    [strokeWidthSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastView.mas_bottom).offset(15);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 20, 0, 20));
    }];
    lastView = strokeWidthSlider;
    
    // 底部约束
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(lastView.mas_bottom).offset(30);
    }];
}

#pragma mark - UI Creation Helpers

- (UILabel *)createLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    label.textColor = UIColor.secondaryLabelColor;
    return label;
}

- (UILabel *)createValueLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont monospacedDigitSystemFontOfSize:14 weight:UIFontWeightRegular];
    label.textColor = UIColor.labelColor;
    return label;
}

- (UIView *)createPointControlWithTitle:(NSString *)title
                                xValue:(CGFloat)xValue
                                yValue:(CGFloat)yValue
                                  xMin:(CGFloat)xMin xMax:(CGFloat)xMax
                                  yMin:(CGFloat)yMin yMax:(CGFloat)yMax
                              xChanged:(void (^)(CGFloat))xChanged
                              yChanged:(void (^)(CGFloat))yChanged {
    
    UIView *container = [[UIView alloc] init];
    
    UILabel *titleLabel = [self createLabelWithText:title];
    
    UILabel *xLabel = [self createLabelWithText:@"X:"];
    UILabel *xValueLabel = [self createValueLabelWithText:[NSString stringWithFormat:@"%.1f", xValue]];
    UISlider *xSlider = [[UISlider alloc] init];
    xSlider.minimumValue = (float)xMin;
    xSlider.maximumValue = (float)xMax;
    xSlider.value = (float)xValue;
    
    UILabel *yLabel = [self createLabelWithText:@"Y:"];
    UILabel *yValueLabel = [self createValueLabelWithText:[NSString stringWithFormat:@"%.1f", yValue]];
    UISlider *ySlider = [[UISlider alloc] init];
    ySlider.minimumValue = (float)yMin;
    ySlider.maximumValue = (float)yMax;
    ySlider.value = (float)yValue;
    
    objc_setAssociatedObject(xSlider, &kValueChangedKey, xChanged, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(ySlider, &kValueChangedKey, yChanged, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(xSlider, &kValueLabelKey, xValueLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(ySlider, &kValueLabelKey, yValueLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [xSlider addTarget:self action:@selector(pointSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [ySlider addTarget:self action:@selector(pointSliderChanged:) forControlEvents:UIControlEventValueChanged];
    
    UIStackView *xStack = [[UIStackView alloc] initWithArrangedSubviews:@[xLabel, xValueLabel, xSlider]];
    xStack.axis = UILayoutConstraintAxisHorizontal;
    xStack.spacing = 10;
    xStack.alignment = UIStackViewAlignmentCenter;
    
    UIStackView *yStack = [[UIStackView alloc] initWithArrangedSubviews:@[yLabel, yValueLabel, ySlider]];
    yStack.axis = UILayoutConstraintAxisHorizontal;
    yStack.spacing = 10;
    yStack.alignment = UIStackViewAlignmentCenter;
    
    UIStackView *vStack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, xStack, yStack]];
    vStack.axis = UILayoutConstraintAxisVertical;
    vStack.spacing = 8;
    
    [container addSubview:vStack];
    [vStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(container);
    }];
    
    [xSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(150);
    }];
    
    return container;
}

- (UIView *)createSliderControlWithTitle:(NSString *)title
                                   value:(float)value
                                     min:(float)min
                                     max:(float)max
                            valueFormat:(nullable NSString *)format
                           valueChanged:(void (^)(float))valueChanged {
    
    if (!format) format = @"%.2f";
    
    UIView *container = [[UIView alloc] init];
    
    UILabel *titleLabel = [self createLabelWithText:title];
    UILabel *valueLabel = [self createValueLabelWithText:[NSString stringWithFormat:format, value]];
    
    UISlider *slider = [[UISlider alloc] init];
    slider.minimumValue = min;
    slider.maximumValue = max;
    slider.value = value;
    
    objc_setAssociatedObject(slider, &kValueChangedKey, valueChanged, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(slider, &kValueLabelKey, valueLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(slider, &kValueFormatKey, [format copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [slider addTarget:self action:@selector(simpleSliderChanged:) forControlEvents:UIControlEventValueChanged];
    
    UIStackView *topStack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, valueLabel]];
    topStack.axis = UILayoutConstraintAxisHorizontal;
    topStack.distribution = UIStackViewDistributionFill;
    topStack.alignment = UIStackViewAlignmentCenter;
    
    [container addSubview:topStack];
    [container addSubview:slider];
    
    [topStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(container);
    }];
    
    [slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(topStack.mas_bottom).offset(8);
        make.left.right.bottom.equalTo(container);
    }];
    
    return container;
}

// valueFormat 默认 "%.2f" 的重载
- (UIView *)createSliderControlWithTitle:(NSString *)title
                                   value:(float)value
                                     min:(float)min
                                     max:(float)max
                            valueChanged:(void (^)(float))valueChanged {
    return [self createSliderControlWithTitle:title value:value min:min max:max valueFormat:nil valueChanged:valueChanged];
}

- (UIView *)createSegmentedControlWithTitle:(NSString *)title
                                      items:(NSArray<NSString *> *)items
                              selectedIndex:(NSInteger)selectedIndex
                               valueChanged:(void (^)(NSInteger))valueChanged {
    
    UIView *container = [[UIView alloc] init];
    
    UILabel *titleLabel = [self createLabelWithText:title];
    
    UIScrollView *scrollContainer = [[UIScrollView alloc] init];
    scrollContainer.showsHorizontalScrollIndicator = NO;
    
    UISegmentedControl *segmented = [[UISegmentedControl alloc] initWithItems:items];
    segmented.selectedSegmentIndex = selectedIndex;
    segmented.apportionsSegmentWidthsByContent = YES;
    
    objc_setAssociatedObject(segmented, &kValueChangedKey, valueChanged, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    [segmented addTarget:self action:@selector(segmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
    
    [scrollContainer addSubview:segmented];
    [segmented mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(scrollContainer);
        make.height.mas_equalTo(32);
    }];
    
    [container addSubview:titleLabel];
    [container addSubview:scrollContainer];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(container);
    }];
    
    [scrollContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(8);
        make.left.right.bottom.equalTo(container);
        make.height.mas_equalTo(32);
    }];
    
    return container;
}

- (UIView *)createColorControlWithTitle:(NSString *)title
                                  color:(UIColor *)color
                           valueChanged:(void (^)(UIColor *))valueChanged {
    
    UIView *container = [[UIView alloc] init];
    
    UILabel *titleLabel = [self createLabelWithText:title];
    
    UIView *colorView = [[UIView alloc] init];
    colorView.backgroundColor = color;
    colorView.layer.borderWidth = 1.0;
    colorView.layer.borderColor = UIColor.separatorColor.CGColor;
    colorView.layer.cornerRadius = 4.0;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"选择颜色" forState:UIControlStateNormal];
    
    objc_setAssociatedObject(button, &kColorViewKey, colorView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(button, &kValueChangedKey, valueChanged, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    [button addTarget:self action:@selector(colorButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [container addSubview:titleLabel];
    [container addSubview:colorView];
    [container addSubview:button];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.centerY.equalTo(container);
    }];
    
    [colorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleLabel.mas_right).offset(20);
        make.centerY.equalTo(container);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];
    
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.centerY.equalTo(container);
    }];
    
    return container;
}

- (UIView *)createSwitchGroupControlWithTitle:(NSString *)title
                                     switches:(NSArray<NSDictionary *> *)switches {
    
    UIView *container = [[UIView alloc] init];
    
    UILabel *titleLabel = [self createLabelWithText:title];
    [container addSubview:titleLabel];
    
    __block UIView *lastSwitchView = titleLabel;
    
    for (NSDictionary *item in switches) {
        NSString *switchTitle = item[@"title"];
        BOOL isOn = [item[@"isOn"] boolValue];
        void (^changed)(BOOL) = item[@"changed"];
        
        UISwitch *switchCtrl = [[UISwitch alloc] init];
        switchCtrl.on = isOn;
        
        UILabel *label = [self createLabelWithText:switchTitle];
        
        objc_setAssociatedObject(switchCtrl, &kValueChangedKey, changed, OBJC_ASSOCIATION_COPY_NONATOMIC);
        
        [switchCtrl addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        
        [container addSubview:switchCtrl];
        [container addSubview:label];
        
        [switchCtrl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(lastSwitchView.mas_bottom).offset(10);
            make.left.equalTo(container);
        }];
        
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(switchCtrl.mas_right).offset(10);
            make.centerY.equalTo(switchCtrl);
        }];
        
        lastSwitchView = switchCtrl;
    }
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(container);
    }];
    
    [container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(lastSwitchView.mas_bottom);
    }];
    
    return container;
}

#pragma mark - Control Actions

- (void)pointSliderChanged:(UISlider *)slider {
    UILabel *valueLabel = objc_getAssociatedObject(slider, &kValueLabelKey);
    if (valueLabel) {
        valueLabel.text = [NSString stringWithFormat:@"%.1f", slider.value];
    }
    
    void (^changed)(CGFloat) = objc_getAssociatedObject(slider, &kValueChangedKey);
    if (changed) {
        changed((CGFloat)slider.value);
    }
}

- (void)simpleSliderChanged:(UISlider *)slider {
    UILabel *valueLabel = objc_getAssociatedObject(slider, &kValueLabelKey);
    NSString *format = objc_getAssociatedObject(slider, &kValueFormatKey);
    if (valueLabel && format) {
        valueLabel.text = [NSString stringWithFormat:format, slider.value];
    }
    
    void (^changed)(float) = objc_getAssociatedObject(slider, &kValueChangedKey);
    if (changed) {
        changed(slider.value);
    }
}

- (void)segmentedControlChanged:(UISegmentedControl *)control {
    void (^changed)(NSInteger) = objc_getAssociatedObject(control, &kValueChangedKey);
    if (changed) {
        changed(control.selectedSegmentIndex);
    }
}

- (void)colorButtonTapped:(UIButton *)button {
    UIView *colorView = objc_getAssociatedObject(button, &kColorViewKey);
    void (^valueChanged)(UIColor *) = objc_getAssociatedObject(button, &kValueChangedKey);
    
    if (!colorView || !valueChanged) return;
    
    if (@available(iOS 14.0, *)) {
        UIColorPickerViewController *picker = [[UIColorPickerViewController alloc] init];
        picker.supportsAlpha = YES;
        picker.selectedColor = colorView.backgroundColor ?: [UIColor clearColor];
        picker.delegate = self;
        
        objc_setAssociatedObject(picker, &kPickerColorViewKey, colorView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(picker, &kPickerValueChangedKey, valueChanged, OBJC_ASSOCIATION_COPY_NONATOMIC);
        
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)switchChanged:(UISwitch *)switchCtrl {
    void (^changed)(BOOL) = objc_getAssociatedObject(switchCtrl, &kValueChangedKey);
    if (changed) {
        changed(switchCtrl.isOn);
    }
}

#pragma mark - Image Combination

- (void)combineImages {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __weak typeof(self) weakSelf = self;
        
        WYCombineImagesConfig *config = [WYCombineImagesConfig sharedDefaultConfig];
        config.overlapControl = weakSelf.overlapControl;
        config.alpha = weakSelf.alphaValue;
        config.blendMode = weakSelf.blendMode;
        config.backgroundColor = weakSelf.backgroundColor;
        config.cornerRadius = weakSelf.cornerRadius;
        config.rotationAngle = weakSelf.rotationAngle;
        config.flipHorizontal = weakSelf.flipHorizontal;
        config.flipVertical = weakSelf.flipVertical;
        config.qualityScale = 0; // 或根据需要设置
        config.scale = weakSelf.scaleValue;
        config.shadowColor = weakSelf.shadowColor;
        config.shadowBlur = weakSelf.shadowBlur;
        config.shadowOffset = weakSelf.shadowOffset;
        config.strokeColor = weakSelf.strokeColor;
        config.strokeWidth = weakSelf.strokeWidth;
        config.maskImage = weakSelf.maskImage;
        
        UIImage *result = [UIImage wy_combineImagesWithStandardImage:weakSelf.standardImage
                                                     stitchingImage:weakSelf.stitchingImage
                                             stitchingCenterPoint:weakSelf.stitchingCenterPoint
                                                           config:config];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result) {
                weakSelf.resultImageView.image = result;
                NSLog(@"图片合成成功，尺寸: %@", NSStringFromCGSize(result.size));
            } else {
                weakSelf.resultImageView.image = nil;
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"合成失败"
                                                                               message:@"参数错误或图片处理失败"
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
                [alert addAction:ok];
                [weakSelf presentViewController:alert animated:YES completion:nil];
            }
        });
    });
}

#pragma mark - UIColorPickerViewControllerDelegate

- (void)colorPickerViewController:(UIColorPickerViewController *)viewController didSelectColor:(UIColor *)color continuously:(BOOL)continuously API_AVAILABLE(ios(14.0)) {
    UIView *colorView = objc_getAssociatedObject(viewController, &kPickerColorViewKey);
    if (colorView) {
        colorView.backgroundColor = color;
    }
    
    if (!continuously) {
        void (^valueChanged)(UIColor *) = objc_getAssociatedObject(viewController, &kPickerValueChangedKey);
        if (valueChanged) {
            valueChanged(color);
        }
    }
}

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController API_AVAILABLE(ios(14.0)) {
    [self dismissViewControllerAnimated:YES completion:^{
        UIView *colorView = objc_getAssociatedObject(viewController, &kPickerColorViewKey);
        UIColor *color = colorView.backgroundColor;
        void (^valueChanged)(UIColor *) = objc_getAssociatedObject(viewController, &kPickerValueChangedKey);
        if (color && valueChanged) {
            valueChanged(color);
        }
    }];
}

@end
