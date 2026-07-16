//
//  WYTestAirBubbleController.m
//  ObjCVerify
//
//  Created by guanren on 2026/7/2.
//

#import "WYTestAirBubbleController.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface UIView (WYTestAccessibility)
- (UIView * _Nullable)viewWithAccessibilityIdentifier:(NSString *)identifier;
@end

@interface WYTestAirBubbleController ()

// 滚动容器
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

// 悬浮容器（气泡及其描述标签的父容器）
@property (nonatomic, strong) UIView *bubbleContainer;
@property (nonatomic, strong) NSLayoutConstraint *containerHeightConstraint;

// 交互气泡
@property (nonatomic, strong) WYAirBubbleView *interactiveBubble;
@property (nonatomic, strong) NSLayoutConstraint *bubbleWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *bubbleHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *bubbleCenterXConstraint;
@property (nonatomic, strong) NSLayoutConstraint *bubbleTopConstraint;
@property (nonatomic, strong) UILabel *bubbleDescriptionLabel;
@property (nonatomic, strong) UILabel *bubbleStatusLabel;

// 静态示例堆栈
@property (nonatomic, strong) UIStackView *staticVerticalStack;

// 动画状态
@property (nonatomic, assign) CGFloat initialX;
@property (nonatomic, assign) CGFloat initialY;
@property (nonatomic, assign) CGFloat initialWidth;
@property (nonatomic, assign) CGFloat initialHeight;
@property (nonatomic, assign) CGFloat finalX;
@property (nonatomic, assign) CGFloat finalY;
@property (nonatomic, assign) CGFloat finalWidth;
@property (nonatomic, assign) CGFloat finalHeight;
@property (nonatomic, assign) BOOL isAtInitial;
@property (nonatomic, assign) BOOL hasAppliedInitialState;

// 动画控制滑块
@property (nonatomic, strong) UISlider *initialXSlider;
@property (nonatomic, strong) UISlider *initialYSlider;
@property (nonatomic, strong) UISlider *initialWidthSlider;
@property (nonatomic, strong) UISlider *initialHeightSlider;
@property (nonatomic, strong) UISlider *finalXSlider;
@property (nonatomic, strong) UISlider *finalYSlider;
@property (nonatomic, strong) UISlider *finalWidthSlider;
@property (nonatomic, strong) UISlider *finalHeightSlider;
@property (nonatomic, strong) UISlider *animationDurationSlider;

// 原有控件
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

// 数值标签映射
@property (nonatomic, strong) NSMapTable<UISlider *, UILabel *> *valueLabelMap;

// 预估描述高度
@property (nonatomic, assign) CGFloat estimatedDescriptionHeight;

@end

@implementation WYTestAirBubbleController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.estimatedDescriptionHeight = 80;
    self.valueLabelMap = [NSMapTable strongToStrongObjectsMapTable];
    self.borderColorButtons = [NSMutableArray array];
    self.selectedBorderColorIndex = 0;

    // 初始化默认状态
    self.initialX = 0;
    self.initialY = 0;
    self.initialWidth = 160;
    self.initialHeight = 100;
    self.finalX = 80;
    self.finalY = 0;
    self.finalWidth = 200;
    self.finalHeight = 100;
    self.isAtInitial = YES;
    self.hasAppliedInitialState = NO;

    [self setupScrollView];
    [self setupStaticExamples];
    [self setupInteractiveBubble];
    [self setupControls];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // 仅在容器尺寸有效且尚未应用初始状态时，应用一次
    if (!self.hasAppliedInitialState &&
        self.bubbleContainer.bounds.size.width > 0 &&
        self.bubbleContainer.bounds.size.height > 0) {
        [self applyStateWithX:self.initialX
                            y:self.initialY
                        width:self.initialWidth
                       height:self.initialHeight
                     animated:NO
                     duration:0];
        self.hasAppliedInitialState = YES;
    }
}

#pragma mark - 滚动容器

- (void)setupScrollView {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];

    [NSLayoutConstraint activateConstraints:@[
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

#pragma mark - 静态示例

- (void)setupStaticExamples {
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

    NSArray<NSDictionary *> *examples = @[
        @{
            @"config": ^(WYAirBubbleView *bubble) {
                bubble.fillColor = [UIColor systemBlueColor];
            },
            @"desc": @"方向: 下\n圆角: 全部 半径12\n箭头: 宽12高8\n偏移: 0 | 边距: 0\n尖端圆角: 0\n边框: 0pt (无)\n填充色: 蓝色"
        },
        @{
            @"config": ^(WYAirBubbleView *bubble) {
                bubble.arrowDirection = WYArrowDirectionTop;
                bubble.fillColor = [UIColor systemRedColor];
                bubble.borderColor = [UIColor blackColor];
                bubble.borderWidth = 2;
            },
            @"desc": @"方向: 上\n圆角: 全部 半径12\n箭头: 宽12高8\n偏移: 0 | 边距: 0\n尖端圆角: 0\n边框: 2pt (有)\n填充色: 红色\n边框颜色: 黑色"
        },
        @{
            @"config": ^(WYAirBubbleView *bubble) {
                bubble.arrowDirection = WYArrowDirectionLeft;
                bubble.fillColor = [UIColor systemGreenColor];
            },
            @"desc": @"方向: 左\n圆角: 全部 半径12\n箭头: 宽12高8\n偏移: 0 | 边距: 0\n尖端圆角: 0\n边框: 0pt (无)\n填充色: 绿色"
        },
        @{
            @"config": ^(WYAirBubbleView *bubble) {
                bubble.arrowDirection = WYArrowDirectionRight;
                bubble.fillColor = [UIColor systemPurpleColor];
                bubble.cornerRadius = 0;
                bubble.arrowTipRadius = 6;
            },
            @"desc": @"方向: 右\n圆角: 无 半径0\n箭头: 宽12高8\n偏移: 0 | 边距: 0\n尖端圆角: 6\n边框: 0pt (无)\n填充色: 紫色"
        },
        @{
            @"config": ^(WYAirBubbleView *bubble) {
                bubble.arrowDirection = WYArrowDirectionBottom;
                bubble.fillColor = [UIColor systemOrangeColor];
                bubble.arrowOffset = 30;
                bubble.arrowSize = CGSizeMake(20, 12);
            },
            @"desc": @"方向: 下\n圆角: 全部 半径12\n箭头: 宽20高12\n偏移: 30 | 边距: 0\n尖端圆角: 0\n边框: 0pt (无)\n填充色: 橙色\n偏移: +30, 箭头: 20x12"
        },
        @{
            @"config": ^(WYAirBubbleView *bubble) {
                bubble.showsArrow = NO;
                bubble.fillColor = [UIColor systemPinkColor];
                bubble.cornersPosition = UIRectCornerTopLeft | UIRectCornerBottomRight;
                bubble.cornerRadius = 20;
            },
            @"desc": @"无箭头\n圆角: 左上+右下 半径20\n填充色: 粉色"
        },
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

    self.staticVerticalStack = [[UIStackView alloc] init];
    self.staticVerticalStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.staticVerticalStack.axis = UILayoutConstraintAxisVertical;
    self.staticVerticalStack.spacing = 20;
    self.staticVerticalStack.alignment = UIStackViewAlignmentFill;
    [self.contentView addSubview:self.staticVerticalStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.staticVerticalStack.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:20],
        [self.staticVerticalStack.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.staticVerticalStack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16]
    ]];

    for (NSDictionary *example in examples) {
        void(^config)(WYAirBubbleView *) = example[@"config"];
        NSString *desc = example[@"desc"];
        UIStackView *stack = makeExampleStack(config, desc);
        [self.staticVerticalStack addArrangedSubview:stack];
    }

    UIView *lastExample = self.staticVerticalStack.arrangedSubviews.lastObject;
    lastExample.accessibilityIdentifier = @"lastStaticExample";
}

#pragma mark - 交互气泡（悬浮区域）

- (void)setupInteractiveBubble {
    // 创建容器，高度为屏幕高度的 2/5
    self.bubbleContainer = [[UIView alloc] init];
    self.bubbleContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.bubbleContainer.backgroundColor = [UIColor systemGray6Color]; // 调试用，可注释
    [self.view addSubview:self.bubbleContainer];

    self.containerHeightConstraint = [self.bubbleContainer.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:2.0/5.0];
    [NSLayoutConstraint activateConstraints:@[
        [self.bubbleContainer.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [self.bubbleContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:8],
        [self.bubbleContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-8],
        self.containerHeightConstraint
    ]];

    // 气泡
    self.interactiveBubble = [[WYAirBubbleView alloc] init];
    self.interactiveBubble.translatesAutoresizingMaskIntoConstraints = NO;
    self.interactiveBubble.fillColor = [UIColor systemTealColor];
    self.interactiveBubble.arrowDirection = WYArrowDirectionBottom;
    self.interactiveBubble.showsArrow = YES;
    [self.bubbleContainer addSubview:self.interactiveBubble];

    // 尺寸约束
    self.bubbleWidthConstraint = [self.interactiveBubble.widthAnchor constraintEqualToConstant:160];
    self.bubbleHeightConstraint = [self.interactiveBubble.heightAnchor constraintEqualToConstant:100];
    // 位置约束
    self.bubbleCenterXConstraint = [self.interactiveBubble.centerXAnchor constraintEqualToAnchor:self.bubbleContainer.centerXAnchor constant:0];
    self.bubbleTopConstraint = [self.interactiveBubble.topAnchor constraintEqualToAnchor:self.bubbleContainer.topAnchor constant:0];
    [NSLayoutConstraint activateConstraints:@[
        self.bubbleCenterXConstraint,
        self.bubbleTopConstraint,
        self.bubbleWidthConstraint,
        self.bubbleHeightConstraint
    ]];

    // 描述标签
    self.bubbleDescriptionLabel = [[UILabel alloc] init];
    self.bubbleDescriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.bubbleDescriptionLabel.text = @"⬇️ 下方操作区域可动态调整此气泡 ⬇️";
    self.bubbleDescriptionLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.bubbleDescriptionLabel.textColor = [UIColor systemBlueColor];
    self.bubbleDescriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.bubbleDescriptionLabel.numberOfLines = 0;
    [self.bubbleContainer addSubview:self.bubbleDescriptionLabel];

    // 状态标签
    self.bubbleStatusLabel = [[UILabel alloc] init];
    self.bubbleStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.bubbleStatusLabel.text = @"拖动下方滑块查看实时变化";
    self.bubbleStatusLabel.font = [UIFont systemFontOfSize:11];
    self.bubbleStatusLabel.textColor = [UIColor grayColor];
    self.bubbleStatusLabel.textAlignment = NSTextAlignmentCenter;
    self.bubbleStatusLabel.numberOfLines = 0;
    [self.bubbleContainer addSubview:self.bubbleStatusLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.bubbleDescriptionLabel.topAnchor constraintEqualToAnchor:self.interactiveBubble.bottomAnchor constant:8],
        [self.bubbleDescriptionLabel.leadingAnchor constraintEqualToAnchor:self.bubbleContainer.leadingAnchor constant:8],
        [self.bubbleDescriptionLabel.trailingAnchor constraintEqualToAnchor:self.bubbleContainer.trailingAnchor constant:-8],

        [self.bubbleStatusLabel.topAnchor constraintEqualToAnchor:self.bubbleDescriptionLabel.bottomAnchor constant:2],
        [self.bubbleStatusLabel.leadingAnchor constraintEqualToAnchor:self.bubbleContainer.leadingAnchor constant:8],
        [self.bubbleStatusLabel.trailingAnchor constraintEqualToAnchor:self.bubbleContainer.trailingAnchor constant:-8],
        [self.bubbleStatusLabel.bottomAnchor constraintEqualToAnchor:self.bubbleContainer.bottomAnchor constant:-4]
    ]];

    // 滚动视图顶部约束到容器底部
    if (self.scrollView) {
        [NSLayoutConstraint activateConstraints:@[
            [self.scrollView.topAnchor constraintEqualToAnchor:self.bubbleContainer.bottomAnchor constant:12]
        ]];
    }
}

#pragma mark - 控制控件

- (void)setupControls {
    UIStackView *verticalStack = [[UIStackView alloc] init];
    verticalStack.translatesAutoresizingMaskIntoConstraints = NO;
    verticalStack.axis = UILayoutConstraintAxisVertical;
    verticalStack.spacing = 12;
    verticalStack.alignment = UIStackViewAlignmentFill;
    [self.contentView addSubview:verticalStack];

    // 修正：顶部约束连接到静态示例堆栈底部
    [NSLayoutConstraint activateConstraints:@[
        [verticalStack.topAnchor constraintEqualToAnchor:self.staticVerticalStack.bottomAnchor constant:30],
        [verticalStack.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
        [verticalStack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
        [verticalStack.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-20]
    ]];

    // 辅助：水平控件行
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

    // ---- 原有控件 ----
    self.directionSegmented = [[UISegmentedControl alloc] initWithItems:@[@"上", @"下", @"左", @"右"]];
    self.directionSegmented.selectedSegmentIndex = 1;
    [self.directionSegmented addTarget:self action:@selector(directionChanged:) forControlEvents:UIControlEventValueChanged];
    [verticalStack addArrangedSubview:makeControlRow(@"箭头方向", self.directionSegmented, 80)];

    self.showArrowSwitch = [[UISwitch alloc] init];
    self.showArrowSwitch.on = YES;
    [self.showArrowSwitch addTarget:self action:@selector(showArrowToggled:) forControlEvents:UIControlEventValueChanged];
    [verticalStack addArrangedSubview:makeControlRow(@"显示箭头", self.showArrowSwitch, 80)];

    NSDictionary *radiusRow = [self makeSliderRowWithLabel:@"圆角半径" min:0 max:30 value:12 action:@selector(radiusChanged:)];
    self.radiusSlider = radiusRow[@"slider"];
    [verticalStack addArrangedSubview:radiusRow[@"view"]];

    self.cornersSegmented = [[UISegmentedControl alloc] initWithItems:@[@"全部", @"左上+右下", @"右上+左下", @"仅左上", @"仅右下"]];
    self.cornersSegmented.selectedSegmentIndex = 0;
    [self.cornersSegmented addTarget:self action:@selector(cornersChanged:) forControlEvents:UIControlEventValueChanged];
    [verticalStack addArrangedSubview:makeControlRow(@"圆角位置", self.cornersSegmented, 80)];

    NSDictionary *widthRow = [self makeSliderRowWithLabel:@"箭头宽度" min:6 max:30 value:12 action:@selector(arrowWidthChanged:)];
    self.arrowWidthSlider = widthRow[@"slider"];
    [verticalStack addArrangedSubview:widthRow[@"view"]];

    NSDictionary *heightRow = [self makeSliderRowWithLabel:@"箭头高度" min:4 max:20 value:8 action:@selector(arrowHeightChanged:)];
    self.arrowHeightSlider = heightRow[@"slider"];
    [verticalStack addArrangedSubview:heightRow[@"view"]];

    NSDictionary *offsetRow = [self makeSliderRowWithLabel:@"箭头偏移" min:-100 max:100 value:0 action:@selector(offsetChanged:)];
    self.offsetSlider = offsetRow[@"slider"];
    [verticalStack addArrangedSubview:offsetRow[@"view"]];

    NSDictionary *edgeRow = [self makeSliderRowWithLabel:@"箭头边距" min:0 max:30 value:0 action:@selector(edgePaddingChanged:)];
    self.edgePaddingSlider = edgeRow[@"slider"];
    [verticalStack addArrangedSubview:edgeRow[@"view"]];

    NSDictionary *tipRow = [self makeSliderRowWithLabel:@"尖端圆角" min:0 max:30 value:0 action:@selector(tipRadiusChanged:)];
    self.tipRadiusSlider = tipRow[@"slider"];
    [verticalStack addArrangedSubview:tipRow[@"view"]];

    NSDictionary *borderRow = [self makeSliderRowWithLabel:@"边框宽度" min:0 max:5 value:0 action:@selector(borderWidthChanged:)];
    self.borderWidthSlider = borderRow[@"slider"];
    [verticalStack addArrangedSubview:borderRow[@"view"]];

    // 边框颜色按钮
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

    self.borderColorButtons[0].layer.borderWidth = 2;
    self.borderColorButtons[0].layer.borderColor = [UIColor grayColor].CGColor;
    self.selectedBorderColorIndex = 0;
    [verticalStack addArrangedSubview:borderColorStack];

    // 气泡宽度/高度滑块（直接调整当前状态）
    NSDictionary *widthSizeRow = [self makeSliderRowWithLabel:@"气泡宽度" min:20 max:300 value:160 action:@selector(widthChanged:)];
    self.widthSlider = widthSizeRow[@"slider"];
    [verticalStack addArrangedSubview:widthSizeRow[@"view"]];

    NSDictionary *heightSizeRow = [self makeSliderRowWithLabel:@"气泡高度" min:20 max:200 value:100 action:@selector(heightChanged:)];
    self.heightSlider = heightSizeRow[@"slider"];
    [verticalStack addArrangedSubview:heightSizeRow[@"view"]];

    UIButton *fillColorButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [fillColorButton setTitle:@"随机填充颜色" forState:UIControlStateNormal];
    [fillColorButton addTarget:self action:@selector(colorButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [verticalStack addArrangedSubview:makeControlRow(@"填充颜色", fillColorButton, 80)];

    // ===== 自定义动画控制面板 =====
    UILabel *panelTitle = [[UILabel alloc] init];
    panelTitle.text = @"--- 自定义动画控制 ---";
    panelTitle.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    panelTitle.textAlignment = NSTextAlignmentCenter;
    [verticalStack addArrangedSubview:panelTitle];

    // 初始状态分组
    UILabel *initialGroupLabel = [[UILabel alloc] init];
    initialGroupLabel.text = @"初始状态";
    initialGroupLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    initialGroupLabel.textColor = [UIColor systemBlueColor];
    [verticalStack addArrangedSubview:initialGroupLabel];

    NSDictionary *initXRow = [self makeSliderRowWithLabel:@"X偏移" min:-150 max:150 value:self.initialX action:@selector(initialXChanged:)];
    self.initialXSlider = initXRow[@"slider"];
    [verticalStack addArrangedSubview:initXRow[@"view"]];

    NSDictionary *initYRow = [self makeSliderRowWithLabel:@"Y偏移" min:-100 max:100 value:self.initialY action:@selector(initialYChanged:)];
    self.initialYSlider = initYRow[@"slider"];
    [verticalStack addArrangedSubview:initYRow[@"view"]];

    NSDictionary *initWRow = [self makeSliderRowWithLabel:@"宽度" min:20 max:300 value:self.initialWidth action:@selector(initialWidthChanged:)];
    self.initialWidthSlider = initWRow[@"slider"];
    [verticalStack addArrangedSubview:initWRow[@"view"]];

    NSDictionary *initHRow = [self makeSliderRowWithLabel:@"高度" min:20 max:200 value:self.initialHeight action:@selector(initialHeightChanged:)];
    self.initialHeightSlider = initHRow[@"slider"];
    [verticalStack addArrangedSubview:initHRow[@"view"]];

    // 最终状态分组
    UILabel *finalGroupLabel = [[UILabel alloc] init];
    finalGroupLabel.text = @"最终状态";
    finalGroupLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    finalGroupLabel.textColor = [UIColor systemGreenColor];
    [verticalStack addArrangedSubview:finalGroupLabel];

    NSDictionary *finXRow = [self makeSliderRowWithLabel:@"X偏移" min:-150 max:150 value:self.finalX action:@selector(finalXChanged:)];
    self.finalXSlider = finXRow[@"slider"];
    [verticalStack addArrangedSubview:finXRow[@"view"]];

    NSDictionary *finYRow = [self makeSliderRowWithLabel:@"Y偏移" min:-100 max:100 value:self.finalY action:@selector(finalYChanged:)];
    self.finalYSlider = finYRow[@"slider"];
    [verticalStack addArrangedSubview:finYRow[@"view"]];

    NSDictionary *finWRow = [self makeSliderRowWithLabel:@"宽度" min:20 max:300 value:self.finalWidth action:@selector(finalWidthChanged:)];
    self.finalWidthSlider = finWRow[@"slider"];
    [verticalStack addArrangedSubview:finWRow[@"view"]];

    NSDictionary *finHRow = [self makeSliderRowWithLabel:@"高度" min:20 max:200 value:self.finalHeight action:@selector(finalHeightChanged:)];
    self.finalHeightSlider = finHRow[@"slider"];
    [verticalStack addArrangedSubview:finHRow[@"view"]];

    // 动画时长
    NSDictionary *durationRow = [self makeSliderRowWithLabel:@"动画时长(s)" min:0 max:10 value:1.0 action:@selector(animationDurationChanged:)];
    self.animationDurationSlider = durationRow[@"slider"];
    [verticalStack addArrangedSubview:durationRow[@"view"]];

    // 操作按钮
    UIStackView *actionStack = [[UIStackView alloc] init];
    actionStack.axis = UILayoutConstraintAxisHorizontal;
    actionStack.spacing = 12;
    actionStack.distribution = UIStackViewDistributionFillEqually;

    UIButton *startBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [startBtn setTitle:@"开始动画" forState:UIControlStateNormal];
    [startBtn addTarget:self action:@selector(startAnimation) forControlEvents:UIControlEventTouchUpInside];
    startBtn.backgroundColor = [UIColor systemGray5Color];
    startBtn.layer.cornerRadius = 6;
    [actionStack addArrangedSubview:startBtn];

    UIButton *resetBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [resetBtn setTitle:@"重置到初始" forState:UIControlStateNormal];
    [resetBtn addTarget:self action:@selector(resetToInitial) forControlEvents:UIControlEventTouchUpInside];
    resetBtn.backgroundColor = [UIColor systemGray5Color];
    resetBtn.layer.cornerRadius = 6;
    [actionStack addArrangedSubview:resetBtn];

    [verticalStack addArrangedSubview:actionStack];

    // 重置所有属性
    UIButton *resetAllButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [resetAllButton setTitle:@"重置所有属性" forState:UIControlStateNormal];
    resetAllButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    resetAllButton.backgroundColor = [UIColor systemGray5Color];
    resetAllButton.layer.cornerRadius = 8;
    resetAllButton.contentEdgeInsets = UIEdgeInsetsMake(8, 16, 8, 16);
    [resetAllButton addTarget:self action:@selector(resetAllTapped) forControlEvents:UIControlEventTouchUpInside];
    [verticalStack addArrangedSubview:resetAllButton];
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
    valueLabel.text = [NSString stringWithFormat:@"%.1f", value];
    valueLabel.font = [UIFont systemFontOfSize:12];
    [valueLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [valueLabel.widthAnchor constraintEqualToConstant:40].active = YES;
    [stack addArrangedSubview:valueLabel];

    [self.valueLabelMap setObject:valueLabel forKey:slider];

    return @{@"view": stack, @"slider": slider};
}

- (void)updateLabelForSlider:(UISlider *)slider {
    UILabel *label = [self.valueLabelMap objectForKey:slider];
    if (label) {
        if (slider == self.animationDurationSlider) {
            label.text = [NSString stringWithFormat:@"%.1f", slider.value];
        } else {
            label.text = [NSString stringWithFormat:@"%d", (int)slider.value];
        }
    }
}

#pragma mark - 边界限制

- (NSDictionary *)clampStateWithX:(CGFloat)x y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height {
    if (!self.bubbleContainer) {
        return @{@"x": @(x), @"y": @(y), @"width": @(width), @"height": @(height)};
    }
    CGFloat containerWidth = self.bubbleContainer.bounds.size.width;
    CGFloat containerHeight = self.bubbleContainer.bounds.size.height;

    // 容器尺寸为零时直接返回原值
    if (containerWidth <= 0 || containerHeight <= 0) {
        return @{@"x": @(x), @"y": @(y), @"width": @(width), @"height": @(height)};
    }

    CGFloat margin = 10;
    CGFloat maxWidth = containerWidth - margin * 2;
    CGFloat clampedWidth = MAX(20, MIN(width, maxWidth));

    CGFloat maxHeight = containerHeight - self.estimatedDescriptionHeight - margin * 2;
    CGFloat clampedHeight = MAX(20, MIN(height, maxHeight));

    CGFloat halfWidth = clampedWidth / 2;
    CGFloat minX = -containerWidth / 2 + halfWidth + margin;
    CGFloat maxX = containerWidth / 2 - halfWidth - margin;
    CGFloat clampedX = MAX(minX, MIN(x, maxX));

    CGFloat minY = margin;
    CGFloat maxY = containerHeight - clampedHeight - margin - self.estimatedDescriptionHeight;
    CGFloat clampedY = MAX(minY, MIN(y, maxY));

    return @{@"x": @(clampedX), @"y": @(clampedY), @"width": @(clampedWidth), @"height": @(clampedHeight)};
}

#pragma mark - 状态应用

- (void)applyStateWithX:(CGFloat)x y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height
               animated:(BOOL)animated duration:(NSTimeInterval)duration {
    NSDictionary *clamped = [self clampStateWithX:x y:y width:width height:height];
    CGFloat clampedX = [clamped[@"x"] floatValue];
    CGFloat clampedY = [clamped[@"y"] floatValue];
    CGFloat clampedWidth = [clamped[@"width"] floatValue];
    CGFloat clampedHeight = [clamped[@"height"] floatValue];

    self.bubbleCenterXConstraint.constant = clampedX;
    self.bubbleTopConstraint.constant = clampedY;
    self.bubbleWidthConstraint.constant = clampedWidth;
    self.bubbleHeightConstraint.constant = clampedHeight;

    void (^applyBlock)(void) = ^{
        [self.view layoutIfNeeded];
    };

    if (animated && duration > 0.01) {
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:applyBlock completion:nil];
    } else {
        [UIView performWithoutAnimation:applyBlock];
    }
}

#pragma mark - 滑块回调（初始状态）

- (void)initialXChanged:(UISlider *)sender {
    self.initialX = sender.value;
    [self updateLabelForSlider:sender];
    if (self.isAtInitial) {
        [self applyStateWithX:self.initialX y:self.initialY width:self.initialWidth height:self.initialHeight animated:NO duration:0];
    }
}

- (void)initialYChanged:(UISlider *)sender {
    self.initialY = sender.value;
    [self updateLabelForSlider:sender];
    if (self.isAtInitial) {
        [self applyStateWithX:self.initialX y:self.initialY width:self.initialWidth height:self.initialHeight animated:NO duration:0];
    }
}

- (void)initialWidthChanged:(UISlider *)sender {
    self.initialWidth = sender.value;
    [self updateLabelForSlider:sender];
    if (self.isAtInitial) {
        [self applyStateWithX:self.initialX y:self.initialY width:self.initialWidth height:self.initialHeight animated:NO duration:0];
    }
}

- (void)initialHeightChanged:(UISlider *)sender {
    self.initialHeight = sender.value;
    [self updateLabelForSlider:sender];
    if (self.isAtInitial) {
        [self applyStateWithX:self.initialX y:self.initialY width:self.initialWidth height:self.initialHeight animated:NO duration:0];
    }
}

#pragma mark - 滑块回调（最终状态）

- (void)finalXChanged:(UISlider *)sender {
    self.finalX = sender.value;
    [self updateLabelForSlider:sender];
    if (!self.isAtInitial) {
        [self applyStateWithX:self.finalX y:self.finalY width:self.finalWidth height:self.finalHeight animated:NO duration:0];
    }
}

- (void)finalYChanged:(UISlider *)sender {
    self.finalY = sender.value;
    [self updateLabelForSlider:sender];
    if (!self.isAtInitial) {
        [self applyStateWithX:self.finalX y:self.finalY width:self.finalWidth height:self.finalHeight animated:NO duration:0];
    }
}

- (void)finalWidthChanged:(UISlider *)sender {
    self.finalWidth = sender.value;
    [self updateLabelForSlider:sender];
    if (!self.isAtInitial) {
        [self applyStateWithX:self.finalX y:self.finalY width:self.finalWidth height:self.finalHeight animated:NO duration:0];
    }
}

- (void)finalHeightChanged:(UISlider *)sender {
    self.finalHeight = sender.value;
    [self updateLabelForSlider:sender];
    if (!self.isAtInitial) {
        [self applyStateWithX:self.finalX y:self.finalY width:self.finalWidth height:self.finalHeight animated:NO duration:0];
    }
}

- (void)animationDurationChanged:(UISlider *)sender {
    [self updateLabelForSlider:sender];
}

#pragma mark - 动画操作

- (void)startAnimation {
    // 取消当前动画
    [self.interactiveBubble.layer removeAllAnimations];
    [self.view.layer removeAllAnimations];

    NSTimeInterval duration = self.animationDurationSlider.value;

    if (self.isAtInitial) {
        [self applyStateWithX:self.finalX y:self.finalY width:self.finalWidth height:self.finalHeight animated:YES duration:duration];
        self.isAtInitial = NO;
    } else {
        [self applyStateWithX:self.initialX y:self.initialY width:self.initialWidth height:self.initialHeight animated:YES duration:duration];
        self.isAtInitial = YES;
    }
    [self updateStatusLabel];
}

- (void)resetToInitial {
    [self.interactiveBubble.layer removeAllAnimations];
    [self.view.layer removeAllAnimations];
    [self applyStateWithX:self.initialX y:self.initialY width:self.initialWidth height:self.initialHeight animated:NO duration:0];
    self.isAtInitial = YES;
    // 同步初始滑块
    self.initialXSlider.value = self.initialX;
    self.initialYSlider.value = self.initialY;
    self.initialWidthSlider.value = self.initialWidth;
    self.initialHeightSlider.value = self.initialHeight;
    for (UISlider *slider in @[self.initialXSlider, self.initialYSlider, self.initialWidthSlider, self.initialHeightSlider]) {
        [self updateLabelForSlider:slider];
    }
    [self updateStatusLabel];
}

#pragma mark - 原有控件响应

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
    if (self.selectedBorderColorIndex < self.borderColorButtons.count) {
        self.borderColorButtons[self.selectedBorderColorIndex].layer.borderWidth = 0;
    }
    sender.layer.borderWidth = 2;
    sender.layer.borderColor = [UIColor grayColor].CGColor;
    self.selectedBorderColorIndex = index;

    NSArray *colors = @[[UIColor clearColor], [UIColor redColor], [UIColor greenColor], [UIColor blueColor], [UIColor blackColor], [UIColor orangeColor]];
    self.interactiveBubble.borderColor = colors[index];
    [self updateStatusLabel];
}

- (void)widthChanged:(UISlider *)sender {
    CGFloat newWidth = sender.value;
    if (self.isAtInitial) {
        self.initialWidth = newWidth;
        [self applyStateWithX:self.initialX y:self.initialY width:self.initialWidth height:self.initialHeight animated:NO duration:0];
    } else {
        self.finalWidth = newWidth;
        [self applyStateWithX:self.finalX y:self.finalY width:self.finalWidth height:self.finalHeight animated:NO duration:0];
    }
    [self updateLabelForSlider:sender];
    [self updateStatusLabel];
}

- (void)heightChanged:(UISlider *)sender {
    CGFloat newHeight = sender.value;
    if (self.isAtInitial) {
        self.initialHeight = newHeight;
        [self applyStateWithX:self.initialX y:self.initialY width:self.initialWidth height:self.initialHeight animated:NO duration:0];
    } else {
        self.finalHeight = newHeight;
        [self applyStateWithX:self.finalX y:self.finalY width:self.finalWidth height:self.finalHeight animated:NO duration:0];
    }
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

#pragma mark - 重置所有

- (void)resetAllTapped {
    [self.interactiveBubble.layer removeAllAnimations];
    [self.view.layer removeAllAnimations];

    // 重置原有控件
    self.directionSegmented.selectedSegmentIndex = 1;
    self.interactiveBubble.arrowDirection = WYArrowDirectionBottom;

    self.showArrowSwitch.on = YES;
    self.interactiveBubble.showsArrow = YES;

    self.radiusSlider.value = 12;
    self.interactiveBubble.cornerRadius = 12;
    [self updateLabelForSlider:self.radiusSlider];

    self.cornersSegmented.selectedSegmentIndex = 0;
    self.interactiveBubble.cornersPosition = UIRectCornerAllCorners;

    self.arrowWidthSlider.value = 12;
    self.arrowHeightSlider.value = 8;
    self.interactiveBubble.arrowSize = CGSizeMake(12, 8);
    [self updateLabelForSlider:self.arrowWidthSlider];
    [self updateLabelForSlider:self.arrowHeightSlider];

    self.offsetSlider.value = 0;
    self.interactiveBubble.arrowOffset = 0;
    [self updateLabelForSlider:self.offsetSlider];

    self.edgePaddingSlider.value = 0;
    self.interactiveBubble.arrowEdgePadding = 0;
    [self updateLabelForSlider:self.edgePaddingSlider];

    self.tipRadiusSlider.value = 0;
    self.interactiveBubble.arrowTipRadius = 0;
    [self updateLabelForSlider:self.tipRadiusSlider];

    self.borderWidthSlider.value = 0;
    self.interactiveBubble.borderWidth = 0;
    [self updateLabelForSlider:self.borderWidthSlider];

    if (self.selectedBorderColorIndex < self.borderColorButtons.count) {
        self.borderColorButtons[self.selectedBorderColorIndex].layer.borderWidth = 0;
    }
    self.borderColorButtons[0].layer.borderWidth = 2;
    self.borderColorButtons[0].layer.borderColor = [UIColor grayColor].CGColor;
    self.selectedBorderColorIndex = 0;
    self.interactiveBubble.borderColor = [UIColor clearColor];

    // 重置动画状态
    self.initialX = 0;
    self.initialY = 0;
    self.initialWidth = 160;
    self.initialHeight = 100;
    self.finalX = 80;
    self.finalY = 0;
    self.finalWidth = 200;
    self.finalHeight = 100;
    self.isAtInitial = YES;
    self.hasAppliedInitialState = NO; // 将在 viewDidLayoutSubviews 重新应用

    // 同步滑块
    self.initialXSlider.value = 0;
    self.initialYSlider.value = 0;
    self.initialWidthSlider.value = 160;
    self.initialHeightSlider.value = 100;
    self.finalXSlider.value = 80;
    self.finalYSlider.value = 0;
    self.finalWidthSlider.value = 200;
    self.finalHeightSlider.value = 100;
    self.animationDurationSlider.value = 1.0;
    for (UISlider *slider in @[self.initialXSlider, self.initialYSlider, self.initialWidthSlider, self.initialHeightSlider,
                               self.finalXSlider, self.finalYSlider, self.finalWidthSlider, self.finalHeightSlider,
                               self.animationDurationSlider]) {
        [self updateLabelForSlider:slider];
    }

    // 应用初始状态
    [self applyStateWithX:self.initialX y:self.initialY width:self.initialWidth height:self.initialHeight animated:NO duration:0];
    self.hasAppliedInitialState = YES;

    self.interactiveBubble.fillColor = [UIColor systemTealColor];

    [self.view layoutIfNeeded];
    [self updateStatusLabel];
}

#pragma mark - 状态更新

- (void)updateStatusLabel {
    if (!self.bubbleStatusLabel) return;

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

    NSString *currentState = self.isAtInitial ? @"初始" : @"最终";
    CGFloat tx = self.bubbleCenterXConstraint.constant;
    CGFloat ty = self.bubbleTopConstraint.constant;
    CGFloat duration = self.animationDurationSlider.value;

    self.bubbleStatusLabel.text = [NSString stringWithFormat:
        @"方向: %@ | 箭头: %@\n"
        @"圆角: %@ 半径%d\n"
        @"箭头尺寸: %dx%d | 偏移: %d | 边距: %d\n"
        @"尖端圆角: %d | 边框: %dpt (%@)\n"
        @"气泡尺寸: %dx%d | 位置偏移(tx,ty): (%d,%d)\n"
        @"状态: %@ | 动画时长: %.1fs",
        dir,
        self.showArrowSwitch.on ? @"显示" : @"隐藏",
        corner,
        (int)self.interactiveBubble.cornerRadius,
        (int)arrowSize.width, (int)arrowSize.height,
        (int)offset, (int)edgePad,
        (int)tipR, (int)borderW, borderColorName,
        (int)w, (int)h,
        (int)tx, (int)ty,
        currentState,
        duration
    ];
}

@end

// UIView 分类实现
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
