//
//  WYTestAirBubbleController.m
//  ObjCVerify
//
//  Created by guanren on 2026/7/2.
//

#import "WYTestAirBubbleController.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>

// 分类声明，以便在实现中使用
@interface UIView (WYTestAccessibility)
- (UIView * _Nullable)viewWithAccessibilityIdentifier:(NSString *)identifier;
@end

@interface WYTestAirBubbleController ()

// 滚动容器
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

// 交互气泡
@property (nonatomic, strong) WYAirBubbleView *interactiveBubble;
@property (nonatomic, strong) NSLayoutConstraint *bubbleWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *bubbleHeightConstraint;
@property (nonatomic, strong) UILabel *statusLabel; // 状态显示

// 控件
@property (nonatomic, strong) UISegmentedControl *directionSegmented;
@property (nonatomic, strong) UISwitch *showArrowSwitch;
@property (nonatomic, strong) UISlider *radiusSlider;
@property (nonatomic, strong) UISlider *arrowWidthSlider;
@property (nonatomic, strong) UISlider *arrowHeightSlider;
@property (nonatomic, strong) UISlider *offsetSlider;
@property (nonatomic, strong) UISlider *tipRadiusSlider;
@property (nonatomic, strong) UISlider *borderWidthSlider;
@property (nonatomic, strong) UISlider *edgePaddingSlider;
@property (nonatomic, strong) UISegmentedControl *cornersSegmented;
@property (nonatomic, strong) UISlider *widthSlider;
@property (nonatomic, strong) UISlider *heightSlider;

// 边框颜色按钮组
@property (nonatomic, strong) NSMutableArray<UIButton *> *borderColorButtons;
@property (nonatomic, assign) NSInteger selectedBorderColorIndex;

// 滑块数值标签映射
@property (nonatomic, strong) NSMapTable<UISlider *, UILabel *> *valueLabelMap;

@end

@implementation WYTestAirBubbleController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    self.valueLabelMap = [NSMapTable strongToStrongObjectsMapTable];
    self.borderColorButtons = [NSMutableArray array];
    self.selectedBorderColorIndex = 0;

    [self setupScrollView];
    [self setupStaticExamples];
    [self setupInteractiveBubble];
    [self setupControls];
}

#pragma mark - 滚动容器

- (void)setupScrollView {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];

    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentView];

    [NSLayoutConstraint activateConstraints:@[
        [self.contentView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor]
    ]];
}

#pragma mark - 静态示例（与 Swift 版本一致）

- (void)setupStaticExamples {
    // 辅助：创建水平示例堆栈（气泡 + 描述）
    UIStackView * (^makeExampleStack)(void(^config)(WYAirBubbleView *), NSString *) = ^UIStackView *(void(^config)(WYAirBubbleView *), NSString *descText) {
        WYAirBubbleView *bubble = [[WYAirBubbleView alloc] init];
        bubble.translatesAutoresizingMaskIntoConstraints = NO;
        config(bubble);

        [NSLayoutConstraint activateConstraints:@[
            [bubble.widthAnchor constraintEqualToConstant:160],
            [bubble.heightAnchor constraintEqualToConstant:100]
        ]];

        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.text = descText;
        label.font = [UIFont systemFontOfSize:11];
        label.textColor = [UIColor darkGrayColor];
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentLeft;
        [label setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [label setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];

        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[bubble, label]];
        stack.translatesAutoresizingMaskIntoConstraints = NO;
        stack.axis = UILayoutConstraintAxisHorizontal;
        stack.spacing = 12;
        stack.alignment = UIStackViewAlignmentCenter;
        stack.distribution = UIStackViewDistributionFill;

        return stack;
    };

    // 示例配置及描述（共 7 个）
    NSArray<NSDictionary *> *examples = @[
        // 1. 默认底部箭头，蓝色
        @{
            @"config": ^(WYAirBubbleView *bubble) {
                bubble.fillColor = [UIColor systemBlueColor];
            },
            @"desc": @"方向: 下\n圆角: 全部 半径12\n箭头: 宽12高8\n偏移: 0 | 边距: 0\n尖端圆角: 0\n边框: 0pt (无)\n填充色: 蓝色"
        },
        // 2. 顶部箭头，红色填充，黑色边框
        @{
            @"config": ^(WYAirBubbleView *bubble) {
                bubble.arrowDirection = WYArrowDirectionTop;
                bubble.fillColor = [UIColor systemRedColor];
                bubble.borderColor = [UIColor blackColor];
                bubble.borderWidth = 2;
            },
            @"desc": @"方向: 上\n圆角: 全部 半径12\n箭头: 宽12高8\n偏移: 0 | 边距: 0\n尖端圆角: 0\n边框: 2pt (有)\n填充色: 红色\n边框颜色: 黑色"
        },
        // 3. 左侧箭头，绿色填充
        @{
            @"config": ^(WYAirBubbleView *bubble) {
                bubble.arrowDirection = WYArrowDirectionLeft;
                bubble.fillColor = [UIColor systemGreenColor];
            },
            @"desc": @"方向: 左\n圆角: 全部 半径12\n箭头: 宽12高8\n偏移: 0 | 边距: 0\n尖端圆角: 0\n边框: 0pt (无)\n填充色: 绿色"
        },
        // 4. 右侧箭头，紫色填充，无圆角，箭头尖圆角 6
        @{
            @"config": ^(WYAirBubbleView *bubble) {
                bubble.arrowDirection = WYArrowDirectionRight;
                bubble.fillColor = [UIColor systemPurpleColor];
                bubble.cornerRadius = 0;
                bubble.arrowTipRadius = 6;
            },
            @"desc": @"方向: 右\n圆角: 无 半径0\n箭头: 宽12高8\n偏移: 0 | 边距: 0\n尖端圆角: 6\n边框: 0pt (无)\n填充色: 紫色"
        },
        // 5. 底部箭头，橙色，偏移+30，箭头放大
        @{
            @"config": ^(WYAirBubbleView *bubble) {
                bubble.arrowDirection = WYArrowDirectionBottom;
                bubble.fillColor = [UIColor systemOrangeColor];
                bubble.arrowOffset = 30;
                bubble.arrowSize = CGSizeMake(20, 12);
            },
            @"desc": @"方向: 下\n圆角: 全部 半径12\n箭头: 宽20高12\n偏移: 30 | 边距: 0\n尖端圆角: 0\n边框: 0pt (无)\n填充色: 橙色\n偏移: +30, 箭头: 20x12"
        },
        // 6. 无箭头，粉色，仅左上/右下圆角
        @{
            @"config": ^(WYAirBubbleView *bubble) {
                bubble.showsArrow = NO;
                bubble.fillColor = [UIColor systemPinkColor];
                bubble.cornersPosition = UIRectCornerTopLeft | UIRectCornerBottomRight;
                bubble.cornerRadius = 20;
            },
            @"desc": @"无箭头\n圆角: 左上+右下 半径20\n填充色: 粉色"
        },
        // 7. 底部箭头，棕色，边框蓝色，边距15，展示 arrowEdgePadding
        @{
            @"config": ^(WYAirBubbleView *bubble) {
                bubble.arrowDirection = WYArrowDirectionBottom;
                bubble.fillColor = [UIColor systemBrownColor];
                bubble.borderColor = [UIColor blueColor];
                bubble.borderWidth = 2;
                bubble.arrowEdgePadding = 15;
                bubble.cornerRadius = 12;
            },
            @"desc": @"方向: 下\n圆角: 全部 半径12\n箭头: 宽12高8\n偏移: 0 | 边距: 15\n尖端圆角: 0\n边框: 2pt (有)\n填充色: 棕色\n边框颜色: 蓝色，边距: 15"
        }
    ];

    // 垂直堆栈管理所有示例
    UIStackView *verticalStack = [[UIStackView alloc] init];
    verticalStack.translatesAutoresizingMaskIntoConstraints = NO;
    verticalStack.axis = UILayoutConstraintAxisVertical;
    verticalStack.spacing = 20;
    verticalStack.alignment = UIStackViewAlignmentFill;
    [self.contentView addSubview:verticalStack];

    [NSLayoutConstraint activateConstraints:@[
        [verticalStack.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:20],
        [verticalStack.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [verticalStack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16]
    ]];

    for (NSDictionary *example in examples) {
        void(^config)(WYAirBubbleView *) = example[@"config"];
        NSString *desc = example[@"desc"];
        UIStackView *stack = makeExampleStack(config, desc);
        [verticalStack addArrangedSubview:stack];
    }

    // 标记最后一个示例
    UIView *lastExample = verticalStack.arrangedSubviews.lastObject;
    lastExample.accessibilityIdentifier = @"lastStaticExample";
}

#pragma mark - 交互气泡（动态调整）

- (void)setupInteractiveBubble {
    // 查找最后一个静态示例
    UIView *lastStatic = [self.contentView viewWithAccessibilityIdentifier:@"lastStaticExample"];

    self.interactiveBubble = [[WYAirBubbleView alloc] init];
    self.interactiveBubble.translatesAutoresizingMaskIntoConstraints = NO;
    self.interactiveBubble.fillColor = [UIColor systemTealColor];
    self.interactiveBubble.arrowDirection = WYArrowDirectionBottom;
    self.interactiveBubble.showsArrow = YES;
    [self.contentView addSubview:self.interactiveBubble];

    // 宽高约束，稍后可通过滑块调整
    self.bubbleWidthConstraint = [self.interactiveBubble.widthAnchor constraintEqualToConstant:200];
    self.bubbleHeightConstraint = [self.interactiveBubble.heightAnchor constraintEqualToConstant:120];
    self.bubbleWidthConstraint.active = YES;
    self.bubbleHeightConstraint.active = YES;

    // 描述标签（提示）
    UILabel *hintLabel = [[UILabel alloc] init];
    hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    hintLabel.text = @"⬇️ 下方操作区域可动态调整此气泡 ⬇️";
    hintLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    hintLabel.textColor = [UIColor systemBlueColor];
    hintLabel.textAlignment = NSTextAlignmentCenter;
    hintLabel.numberOfLines = 0;
    [self.contentView addSubview:hintLabel];

    // 状态标签
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.text = @"拖动下方滑块查看实时变化";
    self.statusLabel.font = [UIFont systemFontOfSize:11];
    self.statusLabel.textColor = [UIColor grayColor];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 0;
    [self.contentView addSubview:self.statusLabel];

    // 布局约束
    NSLayoutConstraint *topConstraint;
    if (lastStatic) {
        topConstraint = [self.interactiveBubble.topAnchor constraintEqualToAnchor:lastStatic.bottomAnchor constant:30];
    } else {
        topConstraint = [self.interactiveBubble.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:20];
    }

    [NSLayoutConstraint activateConstraints:@[
        topConstraint,
        [self.interactiveBubble.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],

        [hintLabel.topAnchor constraintEqualToAnchor:self.interactiveBubble.bottomAnchor constant:8],
        [hintLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:8],
        [hintLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-8],

        [self.statusLabel.topAnchor constraintEqualToAnchor:hintLabel.bottomAnchor constant:2],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:8],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-8],
        [self.statusLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-8]
    ]];

    // 初始更新状态
    [self updateStatusLabel];
}

#pragma mark - 控制控件（全部水平布局）

- (void)setupControls {
    UIStackView *verticalStack = [[UIStackView alloc] init];
    verticalStack.translatesAutoresizingMaskIntoConstraints = NO;
    verticalStack.axis = UILayoutConstraintAxisVertical;
    verticalStack.spacing = 12;
    verticalStack.alignment = UIStackViewAlignmentFill;
    [self.contentView addSubview:verticalStack];

    [NSLayoutConstraint activateConstraints:@[
        [verticalStack.topAnchor constraintEqualToAnchor:self.interactiveBubble.bottomAnchor constant:20],
        [verticalStack.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
        [verticalStack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
        [verticalStack.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-20]
    ]];

    // 辅助：创建水平控件行（标签左对齐，控件右侧）
    UIStackView * (^makeControlRow)(NSString *, UIView *, CGFloat) = ^UIStackView *(NSString *labelText, UIView *control, CGFloat labelWidth) {
        UIStackView *row = [[UIStackView alloc] init];
        row.axis = UILayoutConstraintAxisHorizontal;
        row.spacing = 10;
        row.alignment = UIStackViewAlignmentCenter;

        UILabel *label = [[UILabel alloc] init];
        label.text = labelText;
        label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        [label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [label.widthAnchor constraintEqualToConstant:labelWidth].active = YES;
        [row addArrangedSubview:label];

        [row addArrangedSubview:control];
        return row;
    };

    // 1. 箭头方向
    self.directionSegmented = [[UISegmentedControl alloc] initWithItems:@[@"上", @"下", @"左", @"右"]];
    self.directionSegmented.selectedSegmentIndex = 1;
    [self.directionSegmented addTarget:self action:@selector(directionChanged:) forControlEvents:UIControlEventValueChanged];
    [verticalStack addArrangedSubview:makeControlRow(@"箭头方向", self.directionSegmented, 80)];

    // 2. 显示箭头
    self.showArrowSwitch = [[UISwitch alloc] init];
    self.showArrowSwitch.on = YES;
    [self.showArrowSwitch addTarget:self action:@selector(showArrowToggled:) forControlEvents:UIControlEventValueChanged];
    [verticalStack addArrangedSubview:makeControlRow(@"显示箭头", self.showArrowSwitch, 80)];

    // 3. 圆角半径
    NSDictionary *radiusRow = [self makeSliderRowWithLabel:@"圆角半径" min:0 max:30 value:12 action:@selector(radiusChanged:)];
    self.radiusSlider = radiusRow[@"slider"];
    [verticalStack addArrangedSubview:radiusRow[@"view"]];

    // 4. 圆角位置
    self.cornersSegmented = [[UISegmentedControl alloc] initWithItems:@[@"全部", @"左上+右下", @"右上+左下", @"仅左上", @"仅右下"]];
    self.cornersSegmented.selectedSegmentIndex = 0;
    [self.cornersSegmented addTarget:self action:@selector(cornersChanged:) forControlEvents:UIControlEventValueChanged];
    [verticalStack addArrangedSubview:makeControlRow(@"圆角位置", self.cornersSegmented, 80)];

    // 5. 箭头宽度
    NSDictionary *widthRow = [self makeSliderRowWithLabel:@"箭头宽度" min:6 max:30 value:12 action:@selector(arrowWidthChanged:)];
    self.arrowWidthSlider = widthRow[@"slider"];
    [verticalStack addArrangedSubview:widthRow[@"view"]];

    // 6. 箭头高度
    NSDictionary *heightRow = [self makeSliderRowWithLabel:@"箭头高度" min:4 max:20 value:8 action:@selector(arrowHeightChanged:)];
    self.arrowHeightSlider = heightRow[@"slider"];
    [verticalStack addArrangedSubview:heightRow[@"view"]];

    // 7. 箭头偏移
    NSDictionary *offsetRow = [self makeSliderRowWithLabel:@"箭头偏移" min:-100 max:100 value:0 action:@selector(offsetChanged:)];
    self.offsetSlider = offsetRow[@"slider"];
    [verticalStack addArrangedSubview:offsetRow[@"view"]];

    // 8. 箭头边距
    NSDictionary *edgeRow = [self makeSliderRowWithLabel:@"箭头边距" min:0 max:30 value:0 action:@selector(edgePaddingChanged:)];
    self.edgePaddingSlider = edgeRow[@"slider"];
    [verticalStack addArrangedSubview:edgeRow[@"view"]];

    // 9. 尖端圆角
    NSDictionary *tipRow = [self makeSliderRowWithLabel:@"尖端圆角" min:0 max:12 value:0 action:@selector(tipRadiusChanged:)];
    self.tipRadiusSlider = tipRow[@"slider"];
    [verticalStack addArrangedSubview:tipRow[@"view"]];

    // 10. 边框宽度
    NSDictionary *borderRow = [self makeSliderRowWithLabel:@"边框宽度" min:0 max:5 value:0 action:@selector(borderWidthChanged:)];
    self.borderWidthSlider = borderRow[@"slider"];
    [verticalStack addArrangedSubview:borderRow[@"view"]];

    // 11. 边框颜色按钮组
    UIStackView *borderColorStack = [[UIStackView alloc] init];
    borderColorStack.axis = UILayoutConstraintAxisHorizontal;
    borderColorStack.spacing = 6;
    borderColorStack.alignment = UIStackViewAlignmentCenter;

    UILabel *borderColorLabel = [[UILabel alloc] init];
    borderColorLabel.text = @"边框颜色";
    borderColorLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [borderColorLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [borderColorLabel.widthAnchor constraintEqualToConstant:80].active = YES;
    [borderColorStack addArrangedSubview:borderColorLabel];

    NSArray<NSDictionary *> *colorOptions = @[
        @{@"color": [UIColor clearColor], @"title": @"清除"},
        @{@"color": [UIColor redColor], @"title": @"红"},
        @{@"color": [UIColor greenColor], @"title": @"绿"},
        @{@"color": [UIColor blueColor], @"title": @"蓝"},
        @{@"color": [UIColor blackColor], @"title": @"黑"},
        @{@"color": [UIColor orangeColor], @"title": @"橙"}
    ];

    for (NSDictionary *option in colorOptions) {
        UIColor *color = option[@"color"];
        NSString *title = option[@"title"];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setTitle:title forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:12];
        btn.backgroundColor = (color == [UIColor clearColor]) ? [UIColor lightGrayColor] : color;
        [btn setTitleColor:(color == [UIColor clearColor]) ? [UIColor darkGrayColor] : [UIColor whiteColor] forState:UIControlStateNormal];
        btn.layer.cornerRadius = 4;
        btn.clipsToBounds = YES;
        btn.contentEdgeInsets = UIEdgeInsetsMake(4, 8, 4, 8);
        btn.tag = self.borderColorButtons.count;
        [btn addTarget:self action:@selector(borderColorButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.borderColorButtons addObject:btn];
        [borderColorStack addArrangedSubview:btn];
    }

    // 默认选中“清除”
    self.borderColorButtons[0].layer.borderWidth = 2;
    self.borderColorButtons[0].layer.borderColor = [UIColor grayColor].CGColor;
    self.selectedBorderColorIndex = 0;

    [verticalStack addArrangedSubview:borderColorStack];

    // 12. 气泡宽度
    NSDictionary *widthSizeRow = [self makeSliderRowWithLabel:@"气泡宽度" min:100 max:300 value:200 action:@selector(widthChanged:)];
    self.widthSlider = widthSizeRow[@"slider"];
    [verticalStack addArrangedSubview:widthSizeRow[@"view"]];

    // 13. 气泡高度
    NSDictionary *heightSizeRow = [self makeSliderRowWithLabel:@"气泡高度" min:60 max:200 value:120 action:@selector(heightChanged:)];
    self.heightSlider = heightSizeRow[@"slider"];
    [verticalStack addArrangedSubview:heightSizeRow[@"view"]];

    // 14. 填充颜色
    UIButton *fillColorButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [fillColorButton setTitle:@"随机填充颜色" forState:UIControlStateNormal];
    [fillColorButton addTarget:self action:@selector(colorButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [verticalStack addArrangedSubview:makeControlRow(@"填充颜色", fillColorButton, 80)];

    // 15. 重置按钮
    UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [resetButton setTitle:@"重置所有属性" forState:UIControlStateNormal];
    resetButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    resetButton.backgroundColor = [UIColor systemGray5Color];
    resetButton.layer.cornerRadius = 8;
    resetButton.contentEdgeInsets = UIEdgeInsetsMake(8, 16, 8, 16);
    [resetButton addTarget:self action:@selector(resetButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [verticalStack addArrangedSubview:resetButton];
}

#pragma mark - 辅助：滑块行

- (NSDictionary *)makeSliderRowWithLabel:(NSString *)label min:(CGFloat)min max:(CGFloat)max value:(CGFloat)value action:(SEL)action {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.spacing = 8;
    stack.alignment = UIStackViewAlignmentCenter;

    UILabel *lbl = [[UILabel alloc] init];
    lbl.text = label;
    lbl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [lbl setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [lbl.widthAnchor constraintEqualToConstant:80].active = YES;
    [stack addArrangedSubview:lbl];

    UISlider *slider = [[UISlider alloc] init];
    slider.minimumValue = min;
    slider.maximumValue = max;
    slider.value = value;
    [slider addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:slider];

    UILabel *valueLabel = [[UILabel alloc] init];
    valueLabel.text = [NSString stringWithFormat:@"%d", (int)value];
    valueLabel.font = [UIFont systemFontOfSize:12];
    [valueLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [valueLabel.widthAnchor constraintEqualToConstant:30].active = YES;
    [stack addArrangedSubview:valueLabel];

    [self.valueLabelMap setObject:valueLabel forKey:slider];

    return @{@"view": stack, @"slider": slider};
}

- (void)updateLabelForSlider:(UISlider *)slider {
    UILabel *label = [self.valueLabelMap objectForKey:slider];
    if (label) {
        label.text = [NSString stringWithFormat:@"%d", (int)slider.value];
    }
}

#pragma mark - 控件响应

- (void)directionChanged:(UISegmentedControl *)sender {
    NSArray *directions = @[@(WYArrowDirectionTop), @(WYArrowDirectionBottom), @(WYArrowDirectionLeft), @(WYArrowDirectionRight)];
    self.interactiveBubble.arrowDirection = [directions[sender.selectedSegmentIndex] integerValue];
    [self updateStatusLabel];
}

- (void)showArrowToggled:(UISwitch *)sender {
    self.interactiveBubble.showsArrow = sender.on;
    [self updateStatusLabel];
}

- (void)radiusChanged:(UISlider *)sender {
    self.interactiveBubble.cornerRadius = sender.value;
    [self updateLabelForSlider:sender];
    [self updateStatusLabel];
}

- (void)cornersChanged:(UISegmentedControl *)sender {
    NSArray *corners = @[
        @(UIRectCornerAllCorners),
        @(UIRectCornerTopLeft | UIRectCornerBottomRight),
        @(UIRectCornerTopRight | UIRectCornerBottomLeft),
        @(UIRectCornerTopLeft),
        @(UIRectCornerBottomRight)
    ];
    self.interactiveBubble.cornersPosition = [corners[sender.selectedSegmentIndex] unsignedIntegerValue];
    [self updateStatusLabel];
}

- (void)arrowWidthChanged:(UISlider *)sender {
    CGFloat w = sender.value;
    CGFloat h = self.interactiveBubble.arrowSize.height;
    self.interactiveBubble.arrowSize = CGSizeMake(w, h);
    [self updateLabelForSlider:sender];
    [self updateStatusLabel];
}

- (void)arrowHeightChanged:(UISlider *)sender {
    CGFloat w = self.interactiveBubble.arrowSize.width;
    CGFloat h = sender.value;
    self.interactiveBubble.arrowSize = CGSizeMake(w, h);
    [self updateLabelForSlider:sender];
    [self updateStatusLabel];
}

- (void)offsetChanged:(UISlider *)sender {
    self.interactiveBubble.arrowOffset = sender.value;
    [self updateLabelForSlider:sender];
    [self updateStatusLabel];
}

- (void)edgePaddingChanged:(UISlider *)sender {
    self.interactiveBubble.arrowEdgePadding = sender.value;
    [self updateLabelForSlider:sender];
    [self updateStatusLabel];
}

- (void)tipRadiusChanged:(UISlider *)sender {
    self.interactiveBubble.arrowTipRadius = sender.value;
    [self updateLabelForSlider:sender];
    [self updateStatusLabel];
}

- (void)borderWidthChanged:(UISlider *)sender {
    self.interactiveBubble.borderWidth = sender.value;
    [self updateLabelForSlider:sender];
    [self updateStatusLabel];
}

- (void)borderColorButtonTapped:(UIButton *)sender {
    NSInteger index = sender.tag;
    // 取消之前选中高亮
    if (self.selectedBorderColorIndex < self.borderColorButtons.count) {
        self.borderColorButtons[self.selectedBorderColorIndex].layer.borderWidth = 0;
    }
    // 高亮当前
    sender.layer.borderWidth = 2;
    sender.layer.borderColor = [UIColor grayColor].CGColor;
    self.selectedBorderColorIndex = index;

    NSArray *colors = @[[UIColor clearColor], [UIColor redColor], [UIColor greenColor], [UIColor blueColor], [UIColor blackColor], [UIColor orangeColor]];
    self.interactiveBubble.borderColor = colors[index];
    [self updateStatusLabel];
}

- (void)widthChanged:(UISlider *)sender {
    self.bubbleWidthConstraint.constant = sender.value;
    [self updateLabelForSlider:sender];
    [self updateStatusLabel];
}

- (void)heightChanged:(UISlider *)sender {
    self.bubbleHeightConstraint.constant = sender.value;
    [self updateLabelForSlider:sender];
    [self updateStatusLabel];
}

- (void)colorButtonTapped {
    NSArray *colors = @[[UIColor systemBlueColor], [UIColor systemRedColor], [UIColor systemGreenColor],
                        [UIColor systemOrangeColor], [UIColor systemPinkColor], [UIColor systemTealColor],
                        [UIColor systemPurpleColor], [UIColor systemIndigoColor]];
    self.interactiveBubble.fillColor = colors[arc4random_uniform((uint32_t)colors.count)];
    [self updateStatusLabel];
}

- (void)resetButtonTapped {
    // 重置方向
    self.directionSegmented.selectedSegmentIndex = 1;
    self.interactiveBubble.arrowDirection = WYArrowDirectionBottom;

    // 显示箭头
    self.showArrowSwitch.on = YES;
    self.interactiveBubble.showsArrow = YES;

    // 圆角半径
    self.radiusSlider.value = 12;
    self.interactiveBubble.cornerRadius = 12;
    [self updateLabelForSlider:self.radiusSlider];

    // 圆角位置
    self.cornersSegmented.selectedSegmentIndex = 0;
    self.interactiveBubble.cornersPosition = UIRectCornerAllCorners;

    // 箭头尺寸
    self.arrowWidthSlider.value = 12;
    self.arrowHeightSlider.value = 8;
    self.interactiveBubble.arrowSize = CGSizeMake(12, 8);
    [self updateLabelForSlider:self.arrowWidthSlider];
    [self updateLabelForSlider:self.arrowHeightSlider];

    // 偏移 & 边距
    self.offsetSlider.value = 0;
    self.interactiveBubble.arrowOffset = 0;
    [self updateLabelForSlider:self.offsetSlider];

    self.edgePaddingSlider.value = 0;
    self.interactiveBubble.arrowEdgePadding = 0;
    [self updateLabelForSlider:self.edgePaddingSlider];

    // 尖端圆角
    self.tipRadiusSlider.value = 0;
    self.interactiveBubble.arrowTipRadius = 0;
    [self updateLabelForSlider:self.tipRadiusSlider];

    // 边框宽度
    self.borderWidthSlider.value = 0;
    self.interactiveBubble.borderWidth = 0;
    [self updateLabelForSlider:self.borderWidthSlider];

    // 边框颜色重置为清除
    if (self.selectedBorderColorIndex < self.borderColorButtons.count) {
        self.borderColorButtons[self.selectedBorderColorIndex].layer.borderWidth = 0;
    }
    self.borderColorButtons[0].layer.borderWidth = 2;
    self.borderColorButtons[0].layer.borderColor = [UIColor grayColor].CGColor;
    self.selectedBorderColorIndex = 0;
    self.interactiveBubble.borderColor = [UIColor clearColor];

    // 气泡尺寸
    self.widthSlider.value = 200;
    self.heightSlider.value = 120;
    self.bubbleWidthConstraint.constant = 200;
    self.bubbleHeightConstraint.constant = 120;
    [self updateLabelForSlider:self.widthSlider];
    [self updateLabelForSlider:self.heightSlider];

    // 填充颜色
    self.interactiveBubble.fillColor = [UIColor systemTealColor];

    [self updateStatusLabel];
}

#pragma mark - 状态更新

- (void)updateStatusLabel {
    if (!self.statusLabel) return;

    NSArray *dirNames = @[@"上", @"下", @"左", @"右"];
    NSString *dir = dirNames[self.directionSegmented.selectedSegmentIndex];
    NSArray *cornerNames = @[@"全部", @"左上+右下", @"右上+左下", @"仅左上", @"仅右下"];
    NSString *corner = cornerNames[self.cornersSegmented.selectedSegmentIndex];

    CGSize arrowSize = self.interactiveBubble.arrowSize;
    CGFloat offset = self.interactiveBubble.arrowOffset;
    CGFloat tipR = self.interactiveBubble.arrowTipRadius;
    CGFloat borderW = self.interactiveBubble.borderWidth;
    CGFloat edgePad = self.interactiveBubble.arrowEdgePadding;
    CGFloat w = self.bubbleWidthConstraint.constant;
    CGFloat h = self.bubbleHeightConstraint.constant;

    NSString *borderColorName;
    UIColor *borderColor = self.interactiveBubble.borderColor;
    if ([borderColor isEqual:[UIColor clearColor]]) borderColorName = @"清除";
    else if ([borderColor isEqual:[UIColor redColor]]) borderColorName = @"红";
    else if ([borderColor isEqual:[UIColor greenColor]]) borderColorName = @"绿";
    else if ([borderColor isEqual:[UIColor blueColor]]) borderColorName = @"蓝";
    else if ([borderColor isEqual:[UIColor blackColor]]) borderColorName = @"黑";
    else if ([borderColor isEqual:[UIColor orangeColor]]) borderColorName = @"橙";
    else borderColorName = @"自定义";

    self.statusLabel.text = [NSString stringWithFormat:
        @"方向: %@ | 箭头: %@\n"
        @"圆角: %@ 半径%d\n"
        @"箭头尺寸: %dx%d | 偏移: %d | 边距: %d\n"
        @"尖端圆角: %d | 边框: %dpt (%@)\n"
        @"气泡尺寸: %dx%d",
        dir,
        self.showArrowSwitch.on ? @"显示" : @"隐藏",
        corner,
        (int)self.interactiveBubble.cornerRadius,
        (int)arrowSize.width, (int)arrowSize.height,
        (int)offset, (int)edgePad,
        (int)tipR, (int)borderW, borderColorName,
        (int)w, (int)h
    ];
}

@end

// 实现 UIView 分类
@implementation UIView (WYTestAccessibility)

- (UIView *)viewWithAccessibilityIdentifier:(NSString *)identifier {
    if ([self.accessibilityIdentifier isEqualToString:identifier]) {
        return self;
    }
    for (UIView *subview in self.subviews) {
        UIView *found = [subview viewWithAccessibilityIdentifier:identifier];
        if (found) return found;
    }
    return nil;
}

@end
