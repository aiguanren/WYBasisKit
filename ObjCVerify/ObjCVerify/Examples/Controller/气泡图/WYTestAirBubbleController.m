//
//  WYTestAirBubbleController.m
//  ObjCVerify
//
//  Created by guanren on 2026/7/2.
//

#import "WYTestAirBubbleController.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>

// 提前声明分类方法，以便调用处可见
@interface UIView (WYTestAccessibility)
- (UIView * _Nullable)viewWithAccessibilityIdentifier:(NSString *)identifier;
@end

@interface WYTestAirBubbleController ()

// 滚动容器
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

// 交互气泡
@property (nonatomic, strong) WYAirBubbleView *interactiveBubble;

// 控件
@property (nonatomic, strong) UISegmentedControl *directionSegmented;
@property (nonatomic, strong) UISwitch *showArrowSwitch;
@property (nonatomic, strong) UISlider *radiusSlider;
@property (nonatomic, strong) UISlider *arrowWidthSlider;
@property (nonatomic, strong) UISlider *arrowHeightSlider;
@property (nonatomic, strong) UISlider *offsetSlider;
@property (nonatomic, strong) UISlider *tipRadiusSlider;
@property (nonatomic, strong) UISlider *borderWidthSlider;

// 存储滑块与其数值标签的映射
@property (nonatomic, strong) NSMapTable<UISlider *, UILabel *> *valueLabelMap;

// 边框颜色循环索引
@property (nonatomic, assign) NSInteger borderColorIndex;

@end

@implementation WYTestAirBubbleController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.valueLabelMap = [NSMapTable strongToStrongObjectsMapTable];
    self.borderColorIndex = 0;
    
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

#pragma mark - 静态示例

- (void)setupStaticExamples {
    // 辅助方法：创建带标签的气泡容器
    UIView * (^makeBubble)(void(^config)(WYAirBubbleView *), NSString *) = ^UIView *(void(^config)(WYAirBubbleView *), NSString *labelText) {
        UIView *container = [[UIView alloc] init];
        container.translatesAutoresizingMaskIntoConstraints = NO;
        
        WYAirBubbleView *bubble = [[WYAirBubbleView alloc] init];
        bubble.translatesAutoresizingMaskIntoConstraints = NO;
        config(bubble);
        [container addSubview:bubble];
        
        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.text = labelText;
        label.font = [UIFont systemFontOfSize:12];
        label.textColor = [UIColor darkGrayColor];
        label.numberOfLines = 0;
        [container addSubview:label];
        
        [NSLayoutConstraint activateConstraints:@[
            [bubble.topAnchor constraintEqualToAnchor:container.topAnchor],
            [bubble.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
            [bubble.widthAnchor constraintEqualToConstant:160],
            [bubble.heightAnchor constraintEqualToConstant:100],
            
            [label.topAnchor constraintEqualToAnchor:bubble.bottomAnchor constant:8],
            [label.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:8],
            [label.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-8],
            [label.bottomAnchor constraintEqualToAnchor:container.bottomAnchor]
        ]];
        
        return container;
    };
    
    // 示例1
    UIView *ex1 = makeBubble(^(WYAirBubbleView *bubble) {
        bubble.fillColor = [UIColor systemBlueColor];
    }, @"默认底部箭头\n蓝色填充");
    
    // 示例2
    UIView *ex2 = makeBubble(^(WYAirBubbleView *bubble) {
        bubble.arrowDirection = WYArrowDirectionTop;
        bubble.fillColor = [UIColor systemRedColor];
        bubble.borderColor = [UIColor blackColor];
        bubble.borderWidth = 2;
    }, @"顶部箭头\n红色填充 + 黑边框");
    
    // 示例3
    UIView *ex3 = makeBubble(^(WYAirBubbleView *bubble) {
        bubble.arrowDirection = WYArrowDirectionLeft;
        bubble.fillColor = [UIColor systemGreenColor];
        bubble.arrowColor = [UIColor yellowColor];
    }, @"左侧箭头\n绿色填充，黄色箭头");
    
    // 示例4
    UIView *ex4 = makeBubble(^(WYAirBubbleView *bubble) {
        bubble.arrowDirection = WYArrowDirectionRight;
        bubble.fillColor = [UIColor systemPurpleColor];
        bubble.cornerRadius = 0;
        bubble.arrowTipRadius = 6;
    }, @"右侧箭头\n无圆角，箭头尖圆角");
    
    // 示例5
    UIView *ex5 = makeBubble(^(WYAirBubbleView *bubble) {
        bubble.arrowDirection = WYArrowDirectionBottom;
        bubble.fillColor = [UIColor systemOrangeColor];
        bubble.arrowOffset = 30;
        bubble.arrowSize = CGSizeMake(20, 12);
    }, @"底部箭头\n偏移 +30，箭头更大");
    
    // 示例6
    UIView *ex6 = makeBubble(^(WYAirBubbleView *bubble) {
        bubble.showsArrow = NO;
        bubble.fillColor = [UIColor systemPinkColor];
        bubble.cornersPosition = UIRectCornerTopLeft | UIRectCornerBottomRight;
        bubble.cornerRadius = 20;
    }, @"无箭头\n仅左上/右下圆角");
    
    NSArray *examples = @[ex1, ex2, ex3, ex4, ex5, ex6];
    UIView *previous = nil;
    for (UIView *view in examples) {
        [self.contentView addSubview:view];
        [NSLayoutConstraint activateConstraints:@[
            [view.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [view.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16]
        ]];
        if (previous) {
            [view.topAnchor constraintEqualToAnchor:previous.bottomAnchor constant:20].active = YES;
        } else {
            [view.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:20].active = YES;
        }
        previous = view;
    }
    // 标记最后一个静态示例
    previous.accessibilityIdentifier = @"lastStaticExample";
}

#pragma mark - 交互气泡

- (void)setupInteractiveBubble {
    self.interactiveBubble = [[WYAirBubbleView alloc] init];
    self.interactiveBubble.translatesAutoresizingMaskIntoConstraints = NO;
    self.interactiveBubble.fillColor = [UIColor systemTealColor];
    self.interactiveBubble.arrowDirection = WYArrowDirectionBottom;
    self.interactiveBubble.showsArrow = YES;
    [self.contentView addSubview:self.interactiveBubble];
    
    // 使用分类方法查找
    UIView *lastStatic = [self.contentView viewWithAccessibilityIdentifier:@"lastStaticExample"];
    if (lastStatic) {
        [NSLayoutConstraint activateConstraints:@[
            [self.interactiveBubble.topAnchor constraintEqualToAnchor:lastStatic.bottomAnchor constant:30],
            [self.interactiveBubble.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
            [self.interactiveBubble.widthAnchor constraintEqualToConstant:200],
            [self.interactiveBubble.heightAnchor constraintEqualToConstant:120]
        ]];
    } else {
        [NSLayoutConstraint activateConstraints:@[
            [self.interactiveBubble.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:20],
            [self.interactiveBubble.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
            [self.interactiveBubble.widthAnchor constraintEqualToConstant:200],
            [self.interactiveBubble.heightAnchor constraintEqualToConstant:120]
        ]];
    }
}

#pragma mark - 控制控件

- (void)setupControls {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 10;
    stack.alignment = UIStackViewAlignmentFill;
    [self.contentView addSubview:stack];
    
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:self.interactiveBubble.bottomAnchor constant:20],
        [stack.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
        [stack.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-20]
    ]];
    
    // 1. 方向分段
    UILabel *dirLabel = [[UILabel alloc] init];
    dirLabel.text = @"箭头方向：";
    dirLabel.font = [UIFont systemFontOfSize:14];
    [stack addArrangedSubview:dirLabel];
    
    self.directionSegmented = [[UISegmentedControl alloc] initWithItems:@[@"上", @"下", @"左", @"右"]];
    self.directionSegmented.selectedSegmentIndex = 1;
    [self.directionSegmented addTarget:self action:@selector(directionChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:self.directionSegmented];
    
    // 2. 显示箭头开关
    UIStackView *showRow = [[UIStackView alloc] init];
    showRow.axis = UILayoutConstraintAxisHorizontal;
    showRow.spacing = 10;
    UILabel *showLabel = [[UILabel alloc] init];
    showLabel.text = @"显示箭头";
    showLabel.font = [UIFont systemFontOfSize:14];
    self.showArrowSwitch = [[UISwitch alloc] init];
    self.showArrowSwitch.on = YES;
    [self.showArrowSwitch addTarget:self action:@selector(showArrowToggled:) forControlEvents:UIControlEventValueChanged];
    [showRow addArrangedSubview:showLabel];
    [showRow addArrangedSubview:self.showArrowSwitch];
    [showRow addArrangedSubview:[[UIView alloc] init]]; // 撑开
    [stack addArrangedSubview:showRow];
    
    // 3-8. 滑块
    NSDictionary *sliderConfigs = @{
        @"圆角半径": @[@0, @30, @12, NSStringFromSelector(@selector(radiusChanged:))],
        @"箭头宽度": @[@6, @30, @12, NSStringFromSelector(@selector(arrowWidthChanged:))],
        @"箭头高度": @[@4, @20, @8, NSStringFromSelector(@selector(arrowHeightChanged:))],
        @"偏移量": @[@-50, @50, @0, NSStringFromSelector(@selector(offsetChanged:))],
        @"尖端圆角": @[@0, @12, @0, NSStringFromSelector(@selector(tipRadiusChanged:))],
        @"边框宽度": @[@0, @5, @0, NSStringFromSelector(@selector(borderWidthChanged:))]
    };
    for (NSString *label in sliderConfigs) {
        NSArray *config = sliderConfigs[label];
        CGFloat min = [config[0] floatValue];
        CGFloat max = [config[1] floatValue];
        CGFloat value = [config[2] floatValue];
        SEL action = NSSelectorFromString(config[3]);
        NSDictionary *result = [self makeSliderRowWithLabel:label min:min max:max value:value action:action];
        UIStackView *row = result[@"view"];
        UISlider *slider = result[@"slider"];
        // 保存特定滑块属性
        if ([label isEqualToString:@"圆角半径"]) self.radiusSlider = slider;
        else if ([label isEqualToString:@"箭头宽度"]) self.arrowWidthSlider = slider;
        else if ([label isEqualToString:@"箭头高度"]) self.arrowHeightSlider = slider;
        else if ([label isEqualToString:@"偏移量"]) self.offsetSlider = slider;
        else if ([label isEqualToString:@"尖端圆角"]) self.tipRadiusSlider = slider;
        else if ([label isEqualToString:@"边框宽度"]) self.borderWidthSlider = slider;
        [stack addArrangedSubview:row];
    }
    
    // 9. 边框颜色切换按钮
    UIButton *borderColorButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [borderColorButton setTitle:@"切换边框颜色" forState:UIControlStateNormal];
    [borderColorButton addTarget:self action:@selector(borderColorButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:borderColorButton];
    
    // 填充颜色切换
    UIButton *colorButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [colorButton setTitle:@"切换填充颜色" forState:UIControlStateNormal];
    [colorButton addTarget:self action:@selector(colorButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:colorButton];
    
    // 箭头颜色切换
    UIButton *arrowColorButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [arrowColorButton setTitle:@"切换箭头颜色" forState:UIControlStateNormal];
    [arrowColorButton addTarget:self action:@selector(arrowColorButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:arrowColorButton];
}

// 辅助：创建滑块行，返回字典包含view和slider
- (NSDictionary *)makeSliderRowWithLabel:(NSString *)label min:(CGFloat)min max:(CGFloat)max value:(CGFloat)value action:(SEL)action {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.spacing = 8;
    stack.alignment = UIStackViewAlignmentCenter;
    
    UILabel *lbl = [[UILabel alloc] init];
    lbl.text = label;
    lbl.font = [UIFont systemFontOfSize:13];
    [lbl setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
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
    [stack addArrangedSubview:valueLabel];
    
    // 存储映射
    [self.valueLabelMap setObject:valueLabel forKey:slider];
    
    return @{@"view": stack, @"slider": slider};
}

#pragma mark - 控件响应

- (void)directionChanged:(UISegmentedControl *)sender {
    NSArray *directions = @[@(WYArrowDirectionTop), @(WYArrowDirectionBottom), @(WYArrowDirectionLeft), @(WYArrowDirectionRight)];
    self.interactiveBubble.arrowDirection = [directions[sender.selectedSegmentIndex] integerValue];
}

- (void)showArrowToggled:(UISwitch *)sender {
    self.interactiveBubble.showsArrow = sender.on;
}

- (void)radiusChanged:(UISlider *)sender {
    self.interactiveBubble.cornerRadius = sender.value;
    [self updateLabelForSlider:sender];
}

- (void)arrowWidthChanged:(UISlider *)sender {
    CGFloat w = sender.value;
    CGFloat h = self.interactiveBubble.arrowSize.height;
    self.interactiveBubble.arrowSize = CGSizeMake(w, h);
    [self updateLabelForSlider:sender];
}

- (void)arrowHeightChanged:(UISlider *)sender {
    CGFloat w = self.interactiveBubble.arrowSize.width;
    CGFloat h = sender.value;
    self.interactiveBubble.arrowSize = CGSizeMake(w, h);
    [self updateLabelForSlider:sender];
}

- (void)offsetChanged:(UISlider *)sender {
    self.interactiveBubble.arrowOffset = sender.value;
    [self updateLabelForSlider:sender];
}

- (void)tipRadiusChanged:(UISlider *)sender {
    self.interactiveBubble.arrowTipRadius = sender.value;
    [self updateLabelForSlider:sender];
}

- (void)borderWidthChanged:(UISlider *)sender {
    self.interactiveBubble.borderWidth = sender.value;
    [self updateLabelForSlider:sender];
}

- (void)updateLabelForSlider:(UISlider *)slider {
    UILabel *label = [self.valueLabelMap objectForKey:slider];
    if (label) {
        label.text = [NSString stringWithFormat:@"%d", (int)slider.value];
    }
}

- (void)borderColorButtonTapped {
    NSArray *colors = @[[UIColor clearColor], [UIColor redColor], [UIColor greenColor], [UIColor blueColor], [UIColor blackColor], [UIColor orangeColor]];
    self.borderColorIndex = (self.borderColorIndex + 1) % colors.count;
    self.interactiveBubble.borderColor = colors[self.borderColorIndex];
}

- (void)colorButtonTapped {
    NSArray *colors = @[[UIColor systemBlueColor], [UIColor systemRedColor], [UIColor systemGreenColor], [UIColor systemOrangeColor], [UIColor systemPinkColor], [UIColor systemTealColor]];
    self.interactiveBubble.fillColor = colors[arc4random_uniform((uint32_t)colors.count)];
}

- (void)arrowColorButtonTapped {
    NSArray *colors = @[[UIColor yellowColor], [UIColor whiteColor], [UIColor blackColor], [UIColor cyanColor], [UIColor magentaColor], [UIColor brownColor]];
    self.interactiveBubble.arrowColor = colors[arc4random_uniform((uint32_t)colors.count)];
}

#pragma mark - 保留的 Navigation 注释

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

// 实现 UIView 分类，使 viewWithAccessibilityIdentifier: 可用
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
