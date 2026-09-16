//
//  WYTestVisualController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/8.
//

#import "WYTestVisualController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

typedef void(^WYVisualMakeBlock)(UIView *make);

@interface WYTestVisualController ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIButton *bigButton;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIView *shadowBlock;
@property (nonatomic, strong) UIView *shadowBlockChild;
@property (nonatomic, strong) UIView *lateMountSlot;
@property (nonatomic, assign) NSInteger applyCount;
@property (nonatomic, assign) NSInteger borderIndex;
@property (nonatomic, assign) BOOL edgeBorderRemoved;
@property (nonatomic, assign) BOOL isBigSize;
@property (nonatomic, assign) BOOL isOffset;
@property (nonatomic, assign) BOOL isRotated;
@property (nonatomic, assign) BOOL isScaled;
@property (nonatomic, assign) BOOL isNarrow;
@property (nonatomic, assign) BOOL shadowBlockHasRadius;
@property (nonatomic, assign) BOOL shadowBlockBig;
@property (nonatomic, assign) BOOL shadowBlockHasChild;
@property (nonatomic, assign) BOOL sameFrameThick;
@property (nonatomic, assign) BOOL midFlightThick;
@property (nonatomic, assign) NSInteger extremeIndex;

@end

@implementation WYTestVisualController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"边框、圆角、阴影、渐变";

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    UIStackView *contentStack = [[UIStackView alloc] init];
    contentStack.axis = UILayoutConstraintAxisVertical;
    contentStack.spacing = 16;
    [scrollView addSubview:contentStack];
    [contentStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(scrollView).insets(UIEdgeInsetsMake(16, 16, 30, 16));
        make.width.equalTo(scrollView).offset(-32);
    }];

    [contentStack addArrangedSubview:[self makeHintLabel]];

    // 静态组合矩阵，两个一行，每项固定半列宽(防fillEqually把奇数行压扁导致固定路径的椭圆等视觉溢出越界)
    NSArray<NSDictionary *> *visualItems = [self visualItems];
    NSMutableArray<NSDictionary *> *rowItems = [NSMutableArray array];
    for (NSDictionary *item in visualItems) {
        [rowItems addObject:item];
        if (rowItems.count == 2) {
            [contentStack addArrangedSubview:[self makeRowWithItems:rowItems]];
            [rowItems removeAllObjects];
        }
    }
    if (rowItems.count > 0) {
        [contentStack addArrangedSubview:[self makeRowWithItems:rowItems]];
    }

    // viewBounds场景：控件还没布局(bounds为0)时先应用视觉，靠传入的固定bounds出效果
    UIView *viewBoundsDemoView = nil;
    UIView *viewBoundsContainer = [self makeDemoItemWithTitle:@"viewBounds(100x70)优先" demoView:&viewBoundsDemoView];
    [contentStack addArrangedSubview:[self makeRowWithItems:@[@{@"title": @"viewBounds"}] containers:@[viewBoundsContainer] demoViews:@[viewBoundsDemoView]]];
    viewBoundsDemoView.wy_cornerRadius(18).wy_borderWidth(4).wy_borderColor([UIColor systemGreenColor]).wy_gradualColors(@[[UIColor yellowColor], [UIColor purpleColor]]).wy_viewBounds(CGRectMake(0, 0, 100, 70)).wy_showVisual();

    [contentStack addArrangedSubview:[self makeDynamicArea]];
    [self applyBigButtonVisual];
    [self applyShadowBlockVisual];
    [self.bigButton wy_addBorder:UIRectEdgeAll color:[UIColor magentaColor] thickness:[self currentEdgeThickness]];
    [self refreshStatus];
}

/// 每个静态组合的标题和链式配置(标题显示在视觉区下方的外部标签上，不会被边框、圆角、阴影挡住)
- (NSArray<NSDictionary *> *)visualItems {
    return @[
        @{@"title": @"radius 10", @"make": ^(UIView *make) { make.wy_cornerRadius(10); }},
        @{@"title": @"radius 15 topRight", @"make": ^(UIView *make) { make.wy_cornerRadius(15).wy_rectCorner(UIRectCornerTopRight); }},
        @{@"title": @"border 5", @"make": ^(UIView *make) { make.wy_borderWidth(5).wy_borderColor([UIColor blackColor]); }},
        @{@"title": @"radius 10 + border 5", @"make": ^(UIView *make) { make.wy_cornerRadius(10).wy_borderWidth(5).wy_borderColor([UIColor blackColor]); }},
        @{@"title": @"radius 10 + border 20 (宽边框吃圆角场景)", @"make": ^(UIView *make) { make.wy_cornerRadius(10).wy_borderWidth(20).wy_borderColor([UIColor systemRedColor]); }},
        @{@"title": @"radius 30 + border 10 topLeft", @"make": ^(UIView *make) { make.wy_cornerRadius(30).wy_borderWidth(10).wy_rectCorner(UIRectCornerTopLeft).wy_borderColor([UIColor systemBlueColor]); }},
        @{@"title": @"渐变→", @"make": ^(UIView *make) { make.wy_gradualColors(@[[UIColor orangeColor], [UIColor redColor]]); }},
        @{@"title": @"渐变↓", @"make": ^(UIView *make) { make.wy_gradualColors(@[[UIColor orangeColor], [UIColor redColor]]).wy_gradientDirection(WYGradientDirectionTopToBottom); }},
        @{@"title": @"渐变↘", @"make": ^(UIView *make) { make.wy_gradualColors(@[[UIColor orangeColor], [UIColor redColor]]).wy_gradientDirection(WYGradientDirectionLeftToLowRight); }},
        @{@"title": @"渐变↙", @"make": ^(UIView *make) { make.wy_gradualColors(@[[UIColor orangeColor], [UIColor redColor]]).wy_gradientDirection(WYGradientDirectionRightToLowLeft); }},
        @{@"title": @"渐变 + radius 15", @"make": ^(UIView *make) { make.wy_gradualColors(@[[UIColor orangeColor], [UIColor redColor]]).wy_cornerRadius(15); }},
        @{@"title": @"渐变 + radius 15 + border 5", @"make": ^(UIView *make) { make.wy_gradualColors(@[[UIColor orangeColor], [UIColor redColor]]).wy_cornerRadius(15).wy_borderWidth(5).wy_borderColor([UIColor blackColor]); }},
        @{@"title": @"阴影(无路径)", @"make": ^(UIView *make) { make.wy_shadowColor([UIColor blackColor]).wy_shadowRadius(8).wy_shadowOpacity(0.6); }},
        @{@"title": @"阴影 + radius 15", @"make": ^(UIView *make) { make.wy_shadowColor([UIColor blackColor]).wy_shadowRadius(8).wy_shadowOpacity(0.6).wy_cornerRadius(15); }},
        @{@"title": @"阴影 + radius + border", @"make": ^(UIView *make) { make.wy_shadowColor([UIColor blackColor]).wy_shadowRadius(8).wy_shadowOpacity(0.6).wy_cornerRadius(15).wy_borderWidth(5).wy_borderColor([UIColor blackColor]); }},
        @{@"title": @"全叠加(渐变+圆角+边框+阴影)", @"make": ^(UIView *make) { make.wy_gradualColors(@[[UIColor orangeColor], [UIColor redColor]]).wy_cornerRadius(15).wy_borderWidth(5).wy_borderColor([UIColor blackColor]).wy_shadowColor([UIColor blackColor]).wy_shadowRadius(8).wy_shadowOpacity(0.6); }},
        @{@"title": @"椭圆路径 + border 5 + 阴影", @"make": ^(UIView *make) { make.wy_bezierPath([UIBezierPath bezierPathWithOvalInRect:CGRectMake(8, 5, 155, 100)]).wy_borderWidth(5).wy_borderColor([UIColor purpleColor]).wy_shadowColor([UIColor blackColor]).wy_shadowRadius(8).wy_shadowOpacity(0.6); }},
        @{@"title": @"指定位置边框 all 8", @"make": ^(UIView *make) { make.backgroundColor = [UIColor systemTealColor]; }},
        @{@"title": @"阴影+半透明背景(保持轮廓)", @"make": ^(UIView *make) { make.backgroundColor = [UIColor colorWithWhite:0.92 alpha:0.5]; make.wy_shadowColor([UIColor blackColor]).wy_shadowRadius(8).wy_shadowOpacity(0.6); }},
        @{@"title": @"阴影+子视图(轮廓随子视图)", @"make": ^(UIView *make) {
            make.backgroundColor = [UIColor clearColor];
            UIView *icon = [[UIView alloc] initWithFrame:CGRectMake(25, 25, 100, 60)];
            icon.backgroundColor = [UIColor systemTealColor];
            [make addSubview:icon];
            make.wy_shadowColor([UIColor blackColor]).wy_shadowRadius(8).wy_shadowOpacity(0.6);
        }},
        @{@"title": @"阴影+不透明渐变(无圆角)", @"make": ^(UIView *make) { make.wy_gradualColors(@[[UIColor orangeColor], [UIColor redColor]]).wy_shadowColor([UIColor blackColor]).wy_shadowRadius(8).wy_shadowOpacity(0.6); }},
        @{@"title": @"阴影+半透明渐变(保持轮廓)", @"make": ^(UIView *make) {
            make.backgroundColor = [UIColor clearColor];
            make.wy_gradualColors(@[[[UIColor orangeColor] colorWithAlphaComponent:0.5], [UIColor redColor]]).wy_shadowColor([UIColor blackColor]).wy_shadowRadius(8).wy_shadowOpacity(0.6);
        }},
        @{@"title": @"阴影opacity 5(钳到1)", @"make": ^(UIView *make) { make.wy_shadowColor([UIColor blackColor]).wy_shadowRadius(8).wy_shadowOpacity(5); }},
        @{@"title": @"radius 500(钳到半短边)", @"make": ^(UIView *make) { make.wy_cornerRadius(500); }},
        @{@"title": @"radius -20(按0处理)", @"make": ^(UIView *make) { make.wy_cornerRadius(-20).wy_borderWidth(4).wy_borderColor([UIColor blackColor]); }},
        @{@"title": @"border 80超宽(内缩钳制)", @"make": ^(UIView *make) { make.backgroundColor = [UIColor systemTealColor]; make.wy_borderWidth(80).wy_borderColor([UIColor systemPurpleColor]); }},
        @{@"title": @"圆角裁图片", @"make": ^(UIView *make) {
            make.backgroundColor = [UIColor clearColor];
            UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(150, 90)];
            UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
                [[UIColor systemRedColor] setFill];
                CGContextFillRect(context.CGContext, CGRectMake(0, 0, 75, 90));
                [[UIColor systemBlueColor] setFill];
                CGContextFillRect(context.CGContext, CGRectMake(75, 0, 75, 90));
            }];
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            imageView.frame = CGRectMake(0, 0, 150, 90);
            imageView.contentMode = UIViewContentModeScaleToFill;
            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [make addSubview:imageView];
            make.wy_cornerRadius(24);
        }},
        @{@"title": @"圆角裁子视图(左上角被裁圆)", @"make": ^(UIView *make) {
            make.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
            UIView *cornerSquare = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
            cornerSquare.backgroundColor = [UIColor systemRedColor];
            [make addSubview:cornerSquare];
            UILabel *centerLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 40, 100, 30)];
            centerLabel.text = @"内容";
            centerLabel.textAlignment = NSTextAlignmentCenter;
            [make addSubview:centerLabel];
            make.wy_cornerRadius(20);
        }},
        @{@"title": @"椭圆路径+渐变+阴影", @"make": ^(UIView *make) { make.wy_bezierPath([UIBezierPath bezierPathWithOvalInRect:CGRectMake(8, 5, 155, 100)]).wy_gradualColors(@[[UIColor orangeColor], [UIColor redColor]]).wy_shadowColor([UIColor blackColor]).wy_shadowRadius(8).wy_shadowOpacity(0.6); }},
        @{@"title": @"渐变+部分圆角", @"make": ^(UIView *make) { make.wy_gradualColors(@[[UIColor orangeColor], [UIColor redColor]]).wy_cornerRadius(18).wy_rectCorner(UIRectCornerTopLeft | UIRectCornerBottomRight); }},
        @{@"title": @"单色渐变数组(不启用)", @"make": ^(UIView *make) { make.wy_gradualColors(@[[UIColor purpleColor]]); }},
        @{@"title": @"透明底+边框条+阴影(空心轮廓)", @"make": ^(UIView *make) {
            make.backgroundColor = [UIColor clearColor];
            [make wy_addBorder:UIRectEdgeAll color:[UIColor blackColor] thickness:6];
            make.wy_shadowColor([UIColor blackColor]).wy_shadowRadius(8).wy_shadowOpacity(0.6);
        }},
        @{@"title": @"border -10(按0处理)", @"make": ^(UIView *make) { make.wy_borderWidth(-10).wy_borderColor([UIColor blackColor]); }},
        @{@"title": @"阴影opacity 0+透明色(无阴影)", @"make": ^(UIView *make) { make.wy_shadowColor([UIColor clearColor]).wy_shadowOpacity(0).wy_shadowRadius(8); }},
    ];
}

/// 把一至两个演示项摆成一行并应用视觉(指定位置边框走单独API，viewBounds场景由调用方自行应用，其余走链式)
- (UIStackView *)makeRowWithItems:(NSArray<NSDictionary *> *)items {

    NSMutableArray<UIView *> *containers = [NSMutableArray array];
    NSMutableArray<UIView *> *demoViews = [NSMutableArray array];
    for (NSDictionary *item in items) {
        UIView *demoView = nil;
        [containers addObject:[self makeDemoItemWithTitle:item[@"title"] demoView:&demoView]];
        [demoViews addObject:demoView];
    }

    UIStackView *rowStack = [[UIStackView alloc] initWithArrangedSubviews:containers];
    rowStack.axis = UILayoutConstraintAxisHorizontal;
    rowStack.spacing = 16;
    for (UIView *container in containers) {
        CGFloat widthOffset = (containers.count > 1) ? -8 : 0;
        [container mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(rowStack).multipliedBy(0.5).offset(widthOffset);
        }];
    }

    for (NSUInteger index = 0; index < items.count; index++) {
        NSDictionary *item = items[index];
        UIView *demoView = demoViews[index];
        NSString *title = item[@"title"];
        if ([title hasPrefix:@"指定位置"]) {
            [demoView wy_addBorder:UIRectEdgeAll color:[UIColor magentaColor] thickness:8];
        }else if ([title hasPrefix:@"viewBounds"] == NO) {
            WYVisualMakeBlock makeBlock = item[@"make"];
            [demoView wy_makeVisual:makeBlock];
        }
    }
    return rowStack;
}

/// 把已备好的容器摆成一行(viewBounds场景用，视觉由调用方自行应用)
- (UIStackView *)makeRowWithItems:(NSArray<NSDictionary *> *)items containers:(NSArray<UIView *> *)containers demoViews:(NSArray<UIView *> *)demoViews {
    UIStackView *rowStack = [[UIStackView alloc] initWithArrangedSubviews:containers];
    rowStack.axis = UILayoutConstraintAxisHorizontal;
    rowStack.spacing = 16;
    for (UIView *container in containers) {
        CGFloat widthOffset = (containers.count > 1) ? -8 : 0;
        [container mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(rowStack).multipliedBy(0.5).offset(widthOffset);
        }];
    }
    return rowStack;
}

/// 顶部说明
- (UILabel *)makeHintLabel {
    UILabel *hintLabel = [[UILabel alloc] init];
    hintLabel.font = [UIFont systemFontOfSize:12];
    hintLabel.textColor = [UIColor darkGrayColor];
    hintLabel.numberOfLines = 0;
    hintLabel.text = @"静态矩阵看几何与组合：'radius 10 + border 20'可见圆角必须仍是10(不能被宽边框吃成直角)；全叠加里紫色边框在最上层、渐变在最底层；'阴影(无路径)'和'阴影+不透明渐变'走矩形shadowPath，外观必须和轮廓阴影完全一致；'半透明背景/半透明渐变/子视图'三项必须保持轮廓阴影(阴影随实际内容形状变小变淡)；'圆角裁图片/圆角裁子视图'的圆角mask本职场景，子内容必须真的被裁住；'透明底+边框条+阴影'的轮廓阴影必须是空心边框条形状(不是实心矩形)；radius 500/-20、opacity 5、border 80/-10等极端值必须被钳制住不畸形；'单色渐变/opacity 0'必须等于没设置。动态区：点大按钮只改约束不改视觉，圆角/边框/渐变/阴影应自动跟随新尺寸不变形；'重复应用'连点多次应无任何闪烁；位移/旋转/缩放/改宽同样要同步跟随；'直切尺寸'应一步到位不闪帧；'慢动画2秒'途中再点应无缝反向。阴影块：'±圆角'来回切阴影在自身和背景视图间迁移，不能出双影残影；'改尺寸'阴影应同拍伸缩；'极端半径'轮换不畸形；'±子视图'阴影应在矩形shadowPath和轮廓阴影间自动迁移；'清除后立刻重建'应完整恢复；'慢动画+中途改配置'各图层应从当前屏显位置无缝接力到新配置；'同帧连设四边'四条边各自厚度颜色应一次到位无闪烁；'纯清除不重建'应回到裸视图；'先应用后上树'视觉应完整生效且不闪原始方块。";
    return hintLabel;
}

/// 造一个"视觉区+外部标签"的演示项，标签在视觉区下方不会被任何视觉挡住
- (UIView *)makeDemoItemWithTitle:(NSString *)title demoView:(UIView **)demoView {
    UIStackView *container = [[UIStackView alloc] init];
    container.axis = UILayoutConstraintAxisVertical;
    container.spacing = 4;

    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    [container addArrangedSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@110);
    }];
    if (demoView != NULL) {
        *demoView = view;
    }

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:9];
    titleLabel.textColor = [UIColor darkGrayColor];
    titleLabel.numberOfLines = 2;
    [container addArrangedSubview:titleLabel];

    return container;
}

/// 动态验证区(重复应用/清除重建/同边替换/尺寸跟随/位移/旋转/缩放/改宽/直切/慢动画中断/阴影块挂载迁移与极端值/同帧清除重建/动画中重应用)
- (UIView *)makeDynamicArea {
    UIView *container = [[UIView alloc] init];

    UILabel *statusLabel = [[UILabel alloc] init];
    statusLabel.font = [UIFont systemFontOfSize:11];
    statusLabel.textColor = [UIColor darkGrayColor];
    statusLabel.numberOfLines = 0;
    [container addSubview:statusLabel];
    self.statusLabel = statusLabel;
    [statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.and.trailing.equalTo(container);
    }];

    UIButton *bigButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [bigButton setTitle:@"约束控件(点击只改约束尺寸)" forState:UIControlStateNormal];
    [bigButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    bigButton.titleLabel.font = [UIFont systemFontOfSize:12];
    bigButton.titleLabel.numberOfLines = 0;
    [bigButton addTarget:self action:@selector(toggleSize) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:bigButton];
    self.bigButton = bigButton;
    [bigButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(statusLabel.mas_bottom).offset(12);
        // 约束用宽度+中心点定位(初始和leading/trailing等价)，后面位移、改宽都能用mas_updateConstraints只动常量
        make.width.and.centerX.equalTo(container);
        make.height.equalTo(@110);
    }];

    UILabel *shadowCaption = [[UILabel alloc] init];
    shadowCaption.font = [UIFont systemFontOfSize:11];
    shadowCaption.textColor = [UIColor darkGrayColor];
    shadowCaption.numberOfLines = 0;
    shadowCaption.text = @"阴影块(无圆角，阴影走自身矩形shadowPath，外观应和轮廓阴影完全一致；±圆角来回切不能出双影残影)";
    [container addSubview:shadowCaption];
    [shadowCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(bigButton.mas_bottom).offset(16);
        make.leading.and.trailing.equalTo(container);
    }];

    UIView *shadowBlock = [[UIView alloc] init];
    shadowBlock.backgroundColor = [UIColor systemTealColor];
    self.shadowBlock = shadowBlock;
    UIView *shadowBlockChild = [[UIView alloc] initWithFrame:CGRectMake(-24, 20, 60, 60)];
    shadowBlockChild.backgroundColor = [UIColor systemPurpleColor];
    self.shadowBlockChild = shadowBlockChild;
    [container addSubview:shadowBlock];
    [shadowBlock mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(shadowCaption.mas_bottom).offset(8);
        make.centerX.equalTo(container);
        make.width.equalTo(container).multipliedBy(0.8);
        make.height.equalTo(@100);
    }];

    UIStackView *actionStack = [[UIStackView alloc] init];
    actionStack.backgroundColor = [UIColor clearColor];
    actionStack.axis = UILayoutConstraintAxisVertical;
    actionStack.spacing = 8;
    [container addSubview:actionStack];
    [actionStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(shadowBlock.mas_bottom).offset(16);
        make.leading.and.trailing.equalTo(container);
    }];

    // 两个一行摆动作按钮
    NSArray<NSString *> *actionTitles = @[@"重复应用视觉", @"清除后0.6秒重建", @"指定边框换厚度", @"移除指定边框", @"移动位置", @"旋转45度", @"缩放0.7", @"宽度减120", @"直切尺寸", @"慢动画2秒", @"阴影块±圆角", @"阴影块改尺寸", @"阴影块极端半径", @"清除后立刻重建", @"慢动画+中途改配置", @"同帧连设四边", @"纯清除不重建", @"阴影块±子视图", @"先应用后上树"];
    NSArray<NSString *> *actionSelectorNames = @[NSStringFromSelector(@selector(reapplyVisual)), NSStringFromSelector(@selector(clearAndReapply)), NSStringFromSelector(@selector(cycleEdgeBorder)), NSStringFromSelector(@selector(removeEdgeBorder)), NSStringFromSelector(@selector(togglePosition)), NSStringFromSelector(@selector(toggleRotation)), NSStringFromSelector(@selector(toggleScale)), NSStringFromSelector(@selector(toggleWidth)), NSStringFromSelector(@selector(snapSize)), NSStringFromSelector(@selector(slowToggleSize)), NSStringFromSelector(@selector(toggleShadowBlockRadius)), NSStringFromSelector(@selector(toggleShadowBlockSize)), NSStringFromSelector(@selector(cycleShadowBlockRadius)), NSStringFromSelector(@selector(clearAndReapplyNow)), NSStringFromSelector(@selector(slowToggleAndReapply)), NSStringFromSelector(@selector(sameFrameEdgeBorders)), NSStringFromSelector(@selector(clearOnly)), NSStringFromSelector(@selector(toggleShadowBlockChild)), NSStringFromSelector(@selector(applyThenMount))];
    for (NSUInteger index = 0; index < actionTitles.count; index += 2) {
        UIStackView *rowStack = [[UIStackView alloc] init];
        rowStack.axis = UILayoutConstraintAxisHorizontal;
        rowStack.spacing = 8;
        rowStack.distribution = UIStackViewDistributionFillEqually;
        [actionStack addArrangedSubview:rowStack];

        for (NSUInteger subIndex = index; subIndex <= MIN(index + 1, actionTitles.count - 1); subIndex++) {
            UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [actionButton setTitle:actionTitles[subIndex] forState:UIControlStateNormal];
            actionButton.titleLabel.font = [UIFont systemFontOfSize:12];
            actionButton.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
            actionButton.layer.cornerRadius = 6;
            [actionButton addTarget:self action:NSSelectorFromString(actionSelectorNames[subIndex]) forControlEvents:UIControlEventTouchUpInside];
            [rowStack addArrangedSubview:actionButton];
            [actionButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.height.equalTo(@36);
            }];
        }
    }

    UILabel *lateCaption = [[UILabel alloc] init];
    lateCaption.font = [UIFont systemFontOfSize:11];
    lateCaption.textColor = [UIColor darkGrayColor];
    lateCaption.numberOfLines = 0;
    lateCaption.text = @"先应用后上树槽位(点'先应用后上树'，视图在没加到父视图前就调了wy_showVisual，之后才加进来，全套视觉应完整生效)";
    [container addSubview:lateCaption];
    [lateCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(actionStack.mas_bottom).offset(16);
        make.leading.and.trailing.equalTo(container);
    }];

    UIView *lateMountSlot = [[UIView alloc] init];
    lateMountSlot.layer.borderWidth = 1;
    lateMountSlot.layer.borderColor = [UIColor lightGrayColor].CGColor;
    lateMountSlot.layer.cornerRadius = 8;
    lateMountSlot.clipsToBounds = YES;
    self.lateMountSlot = lateMountSlot;
    [container addSubview:lateMountSlot];
    [lateMountSlot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lateCaption.mas_bottom).offset(8);
        make.centerX.equalTo(container);
        make.width.equalTo(container).multipliedBy(0.8);
        make.height.equalTo(@70);
        make.bottom.equalTo(container);
    }];
    return container;
}

- (NSArray<NSNumber *> *)edgeThicknesses {
    return @[@6, @14];
}

- (NSArray<NSNumber *> *)extremeRadii {
    return @[@-20, @8, @500];
}

- (CGFloat)currentExtremeRadius {
    return self.extremeRadii[self.extremeIndex].floatValue;
}

- (CGFloat)currentEdgeThickness {
    return self.edgeThicknesses[self.borderIndex].floatValue;
}

/// 大按钮的完整链式视觉
- (void)applyBigButtonVisual {
    self.bigButton.wy_gradualColors(@[[UIColor orangeColor], [UIColor redColor]]).wy_gradientDirection(WYGradientDirectionTopToBottom).wy_cornerRadius(20).wy_borderWidth(8).wy_borderColor([UIColor purpleColor]).wy_rectCorner(UIRectCornerAllCorners).wy_shadowColor([UIColor blackColor]).wy_shadowRadius(10).wy_shadowOpacity(0.5).wy_showVisual();
}

/// 阴影块的初始视觉(特意不带圆角，验证阴影挂在自身矩形shadowPath上的场景)
- (void)applyShadowBlockVisual {
    self.shadowBlock.wy_shadowColor([UIColor blackColor]).wy_shadowRadius(10).wy_shadowOpacity(0.6).wy_showVisual();
}

- (void)refreshStatus {
    NSString *edgeText = self.edgeBorderRemoved ? @"已移除" : [NSString stringWithFormat:@"厚度%.0f", self.currentEdgeThickness];
    NSString *transformText = self.isRotated ? @"旋转45度" : (self.isScaled ? @"缩放0.7" : @"无形变");
    NSString *sizeText = [NSString stringWithFormat:@"%@x%@", self.isNarrow ? @"减宽" : @"全宽", self.isBigSize ? @"150" : @"110"];
    NSString *shadowText = [NSString stringWithFormat:@"阴影块%@x%ld%@(极端半径%.0f)", self.shadowBlockHasRadius ? @"圆角" : @"直角", (long)(self.shadowBlockBig ? 150 : 100), self.shadowBlockHasChild ? @"+子视图" : @"", self.currentExtremeRadius];
    self.statusLabel.text = [NSString stringWithFormat:@"已应用%ld次 · 指定边框%@ · 当前尺寸%@ · %@ · %@ · %@", (long)self.applyCount, edgeText, sizeText, transformText, self.isOffset ? @"位移80" : @"未位移", shadowText];
}

- (void)toggleSize {
    self.isBigSize = !self.isBigSize;
    // 验证动画同步:动画上下文里改约束并强制布局，view本体和圆角、边框、渐变、阴影应以相同时长一起过渡
    [UIView animateWithDuration:0.25 animations:^{
        [self.bigButton mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(self.isBigSize ? 150 : 110));
        }];
        [self.view layoutIfNeeded];
    }];
    [self refreshStatus];
}

- (void)togglePosition {
    self.isOffset = !self.isOffset;
    // 验证位移同步:动画上下文里只改水平位置不改尺寸，渐变、边框、阴影背景视图应整体一起平移
    [UIView animateWithDuration:0.4 animations:^{
        [self.bigButton mas_updateConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.bigButton.superview).offset(self.isOffset ? 80 : 0);
        }];
        [self.view layoutIfNeeded];
    }];
    [self refreshStatus];
}

- (void)toggleRotation {
    self.isRotated = !self.isRotated;
    self.isScaled = NO;
    // 验证形变同步:transform旋转45度，圆角、边框、渐变是子图层天然跟着转，阴影背景视图靠库内部同步transform跟转
    [UIView animateWithDuration:0.4 animations:^{
        self.bigButton.transform = self.isRotated ? CGAffineTransformMakeRotation(M_PI / 4) : CGAffineTransformIdentity;
    }];
    [self refreshStatus];
}

- (void)toggleScale {
    self.isScaled = !self.isScaled;
    self.isRotated = NO;
    // 验证形变同步:transform整体缩放0.7，全部视觉图层应一起缩放不变形
    [UIView animateWithDuration:0.4 animations:^{
        self.bigButton.transform = self.isScaled ? CGAffineTransformMakeScale(0.7, 0.7) : CGAffineTransformIdentity;
    }];
    [self refreshStatus];
}

- (void)toggleWidth {
    self.isNarrow = !self.isNarrow;
    // 验证宽度跟随:动画上下文里只改宽度，左右边框、渐变、阴影路径应同时收缩不拉伸
    [UIView animateWithDuration:0.25 animations:^{
        [self.bigButton mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(self.bigButton.superview).offset(self.isNarrow ? -120 : 0);
        }];
        [self.view layoutIfNeeded];
    }];
    [self refreshStatus];
}

- (void)snapSize {
    // 验证无动画直切:不在动画上下文里改尺寸，视觉图层应一步到位且不闪帧
    self.isBigSize = !self.isBigSize;
    [self.bigButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(self.isBigSize ? 150 : 110));
    }];
    [self.view layoutIfNeeded];
    [self refreshStatus];
}

- (void)slowToggleSize {
    // 验证动画中断接力:2秒慢动画途中再点会反向，视觉图层应从当前屏显位置无缝接上不跳变
    self.isBigSize = !self.isBigSize;
    [UIView animateWithDuration:2.0 animations:^{
        [self.bigButton mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(self.isBigSize ? 150 : 110));
        }];
        [self.view layoutIfNeeded];
    }];
    [self refreshStatus];
}

- (void)reapplyVisual {
    [self applyBigButtonVisual];
    self.applyCount += 1;
    [self refreshStatus];
}

- (void)clearAndReapply {
    // 防取到block没调用:wy_clearVisual在OC桥接里是block属性，方括号消息只拿到block不会执行，必须带()调用，否则视觉永远清不掉(点了清除重建没反应)
    [self.bigButton wy_clearVisual]();
    [self.bigButton wy_removeBorder:UIRectEdgeAll];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self applyBigButtonVisual];
        self.edgeBorderRemoved = NO;
        [self.bigButton wy_addBorder:UIRectEdgeAll color:[UIColor magentaColor] thickness:self.currentEdgeThickness];
        self.applyCount += 1;
        [self refreshStatus];
    });
}

- (void)cycleEdgeBorder {
    self.borderIndex = (self.borderIndex + 1) % self.edgeThicknesses.count;
    self.edgeBorderRemoved = NO;
    [self.bigButton wy_addBorder:UIRectEdgeAll color:[UIColor magentaColor] thickness:self.currentEdgeThickness];
    [self refreshStatus];
}

- (void)removeEdgeBorder {
    self.edgeBorderRemoved = YES;
    [self.bigButton wy_removeBorder:UIRectEdgeAll];
    [self refreshStatus];
}

- (void)toggleShadowBlockRadius {
    self.shadowBlockHasRadius = !self.shadowBlockHasRadius;
    // 验证阴影挂载迁移:无圆角(阴影挂自身矩形shadowPath)和有圆角(阴影挂背景视图)来回切，不应出现双阴影、残影或闪烁
    self.shadowBlock.wy_cornerRadius(self.shadowBlockHasRadius ? 20 : 0).wy_showVisual();
    [self refreshStatus];
}

- (void)toggleShadowBlockSize {
    self.shadowBlockBig = !self.shadowBlockBig;
    // 验证自身矩形shadowPath的动画同步:动画上下文里改高度，阴影应和本体同拍伸缩不跳变
    [UIView animateWithDuration:0.45 animations:^{
        [self.shadowBlock mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(self.shadowBlockBig ? 150 : 100));
        }];
        [self.view layoutIfNeeded];
    }];
    [self refreshStatus];
}

- (void)cycleShadowBlockRadius {
    // 验证极端值钳制:负数、常规、超过短边一半的半径轮换，路径不畸形不崩溃，阴影挂载也跟着正确迁移
    self.extremeIndex = (self.extremeIndex + 1) % self.extremeRadii.count;
    self.shadowBlock.wy_cornerRadius([self currentExtremeRadius]).wy_showVisual();
    self.shadowBlockHasRadius = [self currentExtremeRadius] > 0;
    [self refreshStatus];
}

- (void)clearAndReapplyNow {
    // 验证同帧清除重建(骚操作):清除后立刻重新应用，排队任务合并执行后效果应完整恢复不缺项(含指定位置边框，防重建后边框缺失被误判成库的问题)
    [self.bigButton wy_clearVisual]();
    [self.bigButton wy_removeBorder:UIRectEdgeAll];
    [self applyBigButtonVisual];
    [self.bigButton wy_addBorder:UIRectEdgeAll color:[UIColor magentaColor] thickness:[self currentEdgeThickness]];
    self.edgeBorderRemoved = NO;
    self.applyCount += 1;
    [self refreshStatus];
}

- (void)slowToggleAndReapply {
    // 验证动画中改配置重应用:2秒慢动画进行到一半时换边框宽度和渐变色再重新应用，各图层应从当前屏显位置无缝接力到新配置，不跳变不多出短动画
    [self slowToggleSize];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.midFlightThick = !self.midFlightThick;
        self.bigButton.wy_borderWidth(self.midFlightThick ? 8 : 3).wy_gradualColors(self.midFlightThick ? @[[UIColor orangeColor], [UIColor redColor]] : @[[UIColor purpleColor], [UIColor blueColor]]).wy_showVisual();
        self.applyCount += 1;
        [self refreshStatus];
    });
}

- (void)sameFrameEdgeBorders {
    // 验证同帧连设四条边(骚操作):四次调用应合并成一个任务、同一条边原地复用图层，最终四边各自厚度颜色正确且无闪烁
    self.sameFrameThick = !self.sameFrameThick;
    UIColor *color = self.sameFrameThick ? [UIColor systemBlueColor] : [UIColor magentaColor];
    CGFloat thickness = self.sameFrameThick ? 10 : 6;
    [self.bigButton wy_addBorder:UIRectEdgeTop color:color thickness:thickness];
    [self.bigButton wy_addBorder:UIRectEdgeLeft color:color thickness:thickness + 2];
    [self.bigButton wy_addBorder:UIRectEdgeRight color:color thickness:thickness + 4];
    [self.bigButton wy_addBorder:UIRectEdgeBottom color:color thickness:thickness + 6];
    self.edgeBorderRemoved = NO;
    [self refreshStatus];
}

- (void)clearOnly {
    // 验证纯清除:清除后不重建，视觉应完全回到裸视图(无mask无图层无阴影背景视图)，再点其它应用按钮能从零完整重建
    [self.bigButton wy_clearVisual]();
    [self.bigButton wy_removeBorder:UIRectEdgeAll];
    self.edgeBorderRemoved = YES;
    [self refreshStatus];
}

- (void)toggleShadowBlockChild {
    // 验证矩形shadowPath和轮廓阴影的自动迁移:加子视图后重应用，内容不再铺满矩形应切回轮廓阴影(子视图伸出左边界，阴影形状跟着变宽)；移除后重应用应切回矩形shadowPath，来回无残留
    self.shadowBlockHasChild = !self.shadowBlockHasChild;
    if (self.shadowBlockHasChild) {
        [self.shadowBlock addSubview:self.shadowBlockChild];
    }else {
        [self.shadowBlockChild removeFromSuperview];
    }
    self.shadowBlock.wy_showVisual();
    [self refreshStatus];
}

- (void)applyThenMount {
    // 验证先应用后上树(骚操作):视图还没加到父视图就调wy_showVisual，之后才加进槽位，全套视觉应完整生效(任务延后一拍取尺寸的设计)，且上树第一帧不应闪过无圆角的原始方块(同步预应用会先用空路径mask把原始背景藏住)
    for (UIView *subview in self.lateMountSlot.subviews) {
        [subview removeFromSuperview];
    }
    UIView *lateView = [[UIView alloc] init];
    lateView.backgroundColor = [UIColor systemIndigoColor];
    lateView.wy_cornerRadius(16).wy_borderWidth(4).wy_borderColor([UIColor whiteColor]).wy_shadowColor([UIColor blackColor]).wy_shadowRadius(6).wy_shadowOpacity(0.5).wy_gradualColors(@[[UIColor yellowColor], [UIColor systemPinkColor]]).wy_showVisual();
    [self.lateMountSlot addSubview:lateView];
    [lateView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.lateMountSlot);
        make.width.equalTo(self.lateMountSlot).multipliedBy(0.7);
        make.height.equalTo(@44);
    }];
}

- (void)dealloc {
    wy_print(@"WYTestVisualController release");
}

@end
