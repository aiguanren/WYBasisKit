//
//  WYTestPagingViewController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/15.
//

#import "WYTestPagingViewController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

// MARK: - 显示模式枚举
typedef NS_ENUM(NSInteger, DisplayMode) {
    DisplayModeTextOnly = 0,
    DisplayModeImageOnly,
    DisplayModeBoth
};

// MARK: - 测试页数据(控制器/标题/图片绑成一组，插删页或换顺序时标题和内容跟着同一页走)
@interface TestPageItem : NSObject

@property (nonatomic, strong) UIViewController *controller;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *defaultImage;
@property (nonatomic, strong) UIImage *selectedImage;

- (instancetype)initWithController:(UIViewController *)controller title:(NSString *)title defaultImage:(UIImage *)defaultImage selectedImage:(UIImage *)selectedImage;

@end

@implementation TestPageItem

- (instancetype)initWithController:(UIViewController *)controller title:(NSString *)title defaultImage:(UIImage *)defaultImage selectedImage:(UIImage *)selectedImage {
    self = [super init];
    if (self) {
        _controller = controller;
        _title = title;
        _defaultImage = defaultImage;
        _selectedImage = selectedImage;
    }
    return self;
}

@end

// MARK: - 设置数据模型
@interface PagingSettingsModel : NSObject

// 显示模式
@property (nonatomic, assign) DisplayMode displayMode;

// 基本属性
@property (nonatomic, assign) CGFloat barHeight;
@property (nonatomic, assign) WYButtonPosition buttonPosition;
@property (nonatomic, assign) CGFloat originlLeftOffset;
@property (nonatomic, assign) CGFloat originlRightOffset;
@property (nonatomic, assign) CGFloat itemTopOffset;
@property (nonatomic, assign) BOOL adjustOffset;
@property (nonatomic, assign) CGFloat dividingOffset;
@property (nonatomic, assign) CGFloat buttonDividingOffset;

// 颜色
@property (nonatomic, strong) UIColor *pagingContentColor;
@property (nonatomic, strong) UIColor *pagingBgColor;
@property (nonatomic, strong) UIColor *barBgColor;
@property (nonatomic, strong) UIColor *itemDefaultBgColor;
@property (nonatomic, strong) UIColor *itemSelectedBgColor;
@property (nonatomic, strong) UIColor *itemNormalBorderColor;
@property (nonatomic, strong) UIColor *itemSelectedBorderColor;
@property (nonatomic, strong) UIColor *titleDefaultColor;
@property (nonatomic, strong) UIColor *titleSelectedColor;
@property (nonatomic, strong) UIColor *dividingStripColor;
@property (nonatomic, strong) UIColor *scrollLineColor;

// 图片资源
@property (nonatomic, strong) UIImage *dividingStripImage;
@property (nonatomic, strong) UIImage *scrollLineImage;

// 尺寸
@property (nonatomic, assign) CGFloat itemWidth;
@property (nonatomic, assign) CGFloat itemHeight;
@property (nonatomic, assign) CGFloat itemCornerRadius;
@property (nonatomic, assign) CGFloat itemBorderWidth;
@property (nonatomic, assign) CGFloat scrollLineWidth;
@property (nonatomic, assign) CGFloat scrollLineBottomOffset;
@property (nonatomic, assign) CGFloat scrollLineCornerRadius;
@property (nonatomic, assign) CGFloat dividingStripHeight;
@property (nonatomic, assign) CGFloat scrollLineHeight;
@property (nonatomic, assign) CGFloat titleSelectedScale;

// 新增属性
@property (nonatomic, assign) BOOL scrollLineFollowFinger;
@property (nonatomic, assign) UIEdgeInsets itemInsideMargins;
@property (nonatomic, assign) CGSize itemImageViewSize;

// 字体
@property (nonatomic, strong) UIFont *titleDefaultFont;
@property (nonatomic, strong) UIFont *titleSelectedFont;

// 其他
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign) BOOL canScrollController;
@property (nonatomic, assign) BOOL canScrollBar;
@property (nonatomic, assign) BOOL slideThroughIntermediatePages;
@property (nonatomic, assign) BOOL pagingBounce;
@property (nonatomic, assign) BOOL barBounce;

@end

@implementation PagingSettingsModel

- (instancetype)init {
    self = [super init];
    if (self) {
        // 显示模式
        _displayMode = DisplayModeBoth;

        // 基本属性
        _barHeight = 65;
        _buttonPosition = WYButtonPositionImageTopTitleBottom;
        _originlLeftOffset = 0;
        _originlRightOffset = 0;
        _itemTopOffset = 0;
        _adjustOffset = YES;
        _dividingOffset = 20;
        _buttonDividingOffset = 5;

        // 颜色
        _pagingContentColor = [UIColor whiteColor];
        _pagingBgColor = nil;
        _barBgColor = [UIColor whiteColor];
        _itemDefaultBgColor = [UIColor whiteColor];
        _itemSelectedBgColor = [UIColor whiteColor];
        _itemNormalBorderColor = nil;
        _itemSelectedBorderColor = nil;
        _titleDefaultColor = [UIColor wy_hex:@"#7B809E"];
        _titleSelectedColor = [UIColor wy_hex:@"#2D3952"];
        _dividingStripColor = [UIColor wy_hex:@"#F2F2F2"];
        _scrollLineColor = [UIColor wy_hex:@"#2D3952"];

        // 图片资源
        _dividingStripImage = nil;
        _scrollLineImage = nil;

        // 尺寸
        _itemWidth = 0;
        _itemHeight = 0;
        _itemCornerRadius = 0;
        _itemBorderWidth = 0;
        _scrollLineWidth = 25;
        _scrollLineBottomOffset = 5;
        _scrollLineCornerRadius = 0;
        _dividingStripHeight = 2;
        _scrollLineHeight = 2;
        _titleSelectedScale = 1;

        // 新增属性
        _scrollLineFollowFinger = YES;
        _itemInsideMargins = UIEdgeInsetsZero;
        _itemImageViewSize = CGSizeZero;

        // 字体
        _titleDefaultFont = [UIFont systemFontOfSize:15];
        _titleSelectedFont = [UIFont boldSystemFontOfSize:15];

        // 其他
        _selectedIndex = 0;
        _canScrollController = YES;
        _canScrollBar = YES;
        _slideThroughIntermediatePages = NO;
        _pagingBounce = YES;
        _barBounce = YES;
    }
    return self;
}

@end

// MARK: - 设置页面协议
@protocol PagingSettingsDelegate <NSObject>
- (void)didSaveSettings:(PagingSettingsModel *)settings;
- (void)didCancelSettings;
@end

// MARK: - 设置页面控制器
@interface PagingSettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) PagingSettingsModel *settings;
@property (nonatomic, weak) id<PagingSettingsDelegate> delegate;

/// 当前title数量(用于限制初始选中项的取值范围)
@property (nonatomic, assign) NSInteger titleCount;

@property (nonatomic, strong) UITableView *tableView;

// 所有设置项
@property (nonatomic, strong) NSArray<NSString *> *sections;
@property (nonatomic, strong) NSArray<NSArray<NSDictionary *> *> *items;

// 颜色选项
@property (nonatomic, strong) NSDictionary<NSString *, UIColor *> *colorOptions;

- (instancetype)initWithSettings:(PagingSettingsModel *)settings;

@end

@implementation PagingSettingsViewController

- (instancetype)initWithSettings:(PagingSettingsModel *)settings {
    self = [super init];
    if (self) {
        _settings = settings;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self setupNavigationBar];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView];

    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.leading.equalTo(self.view);
        make.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
}

- (void)setupNavigationBar {
    self.title = @"WYPagingView 设置";

    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"保存"
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(saveSettings)];

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(cancelSettings)];

    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = saveButton;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items[section].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    if (cell.detailTextLabel == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }

    NSDictionary *item = self.items[indexPath.section][indexPath.row];

    cell.textLabel.text = item[@"title"];
    cell.detailTextLabel.text = [self getValueDescriptionForKey:item[@"key"]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    // 为颜色设置项添加颜色预览
    NSString *key = item[@"key"];
    if ([key containsString:@"Color"]) {
        UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        colorView.layer.cornerRadius = 4;
        colorView.layer.borderWidth = 1;
        colorView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        colorView.backgroundColor = [self colorValueForKey:key];
        cell.accessoryView = colorView;
    } else {
        cell.accessoryView = nil;
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *item = self.items[indexPath.section][indexPath.row];
    [self showDetailSettingForKey:item[@"key"]];
}

- (NSString *)getValueDescriptionForKey:(NSString *)key {
    if ([key isEqualToString:@"displayMode"]) {
        switch (self.settings.displayMode) {
            case DisplayModeTextOnly: return @"仅文本";
            case DisplayModeImageOnly: return @"仅图片";
            case DisplayModeBoth: return @"图片+文本";
        }
    } else if ([key isEqualToString:@"barHeight"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.barHeight];
    } else if ([key isEqualToString:@"buttonPosition"]) {
        switch (self.settings.buttonPosition) {
            case WYButtonPositionImageLeftTitleRight: return @"图片左文字右";
            case WYButtonPositionImageRightTitleLeft: return @"图片右文字左";
            case WYButtonPositionImageTopTitleBottom: return @"图片上文字下";
            case WYButtonPositionImageBottomTitleTop: return @"图片下文字上";
        }
    } else if ([key isEqualToString:@"originlLeftOffset"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.originlLeftOffset];
    } else if ([key isEqualToString:@"originlRightOffset"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.originlRightOffset];
    } else if ([key isEqualToString:@"itemTopOffset"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.itemTopOffset];
    } else if ([key isEqualToString:@"adjustOffset"]) {
        return self.settings.adjustOffset ? @"是" : @"否";
    } else if ([key isEqualToString:@"dividingOffset"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.dividingOffset];
    } else if ([key isEqualToString:@"buttonDividingOffset"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.buttonDividingOffset];
    } else if ([key isEqualToString:@"itemWidth"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.itemWidth];
    } else if ([key isEqualToString:@"itemHeight"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.itemHeight];
    } else if ([key isEqualToString:@"itemCornerRadius"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.itemCornerRadius];
    } else if ([key isEqualToString:@"itemBorderWidth"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.itemBorderWidth];
    } else if ([key isEqualToString:@"scrollLineWidth"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.scrollLineWidth];
    } else if ([key isEqualToString:@"scrollLineBottomOffset"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.scrollLineBottomOffset];
    } else if ([key isEqualToString:@"scrollLineCornerRadius"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.scrollLineCornerRadius];
    } else if ([key isEqualToString:@"dividingStripHeight"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.dividingStripHeight];
    } else if ([key isEqualToString:@"scrollLineHeight"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.scrollLineHeight];
    } else if ([key isEqualToString:@"titleSelectedScale"]) {
        return [NSString stringWithFormat:@"%@", @(self.settings.titleSelectedScale)];
    } else if ([key isEqualToString:@"scrollLineFollowFinger"]) {
        return self.settings.scrollLineFollowFinger ? @"是" : @"否";
    } else if ([key isEqualToString:@"slideThroughIntermediatePages"]) {
        return self.settings.slideThroughIntermediatePages ? @"是" : @"否";
    } else if ([key isEqualToString:@"itemInsideMargins"]) {
        return [NSString stringWithFormat:@"T:%.0f L:%.0f B:%.0f R:%.0f",
                self.settings.itemInsideMargins.top,
                self.settings.itemInsideMargins.left,
                self.settings.itemInsideMargins.bottom,
                self.settings.itemInsideMargins.right];
    } else if ([key isEqualToString:@"itemImageViewSize"]) {
        return [NSString stringWithFormat:@"W:%.0f H:%.0f", self.settings.itemImageViewSize.width, self.settings.itemImageViewSize.height];
    } else if ([key isEqualToString:@"titleDefaultFont"]) {
        return [NSString stringWithFormat:@"%d", (int)self.settings.titleDefaultFont.pointSize];
    } else if ([key isEqualToString:@"titleSelectedFont"]) {
        return [NSString stringWithFormat:@"%d", (int)self.settings.titleSelectedFont.pointSize];
    } else if ([key isEqualToString:@"selectedIndex"]) {
        return [NSString stringWithFormat:@"%ld", (long)self.settings.selectedIndex];
    } else if ([key isEqualToString:@"canScrollController"]) {
        return self.settings.canScrollController ? @"是" : @"否";
    } else if ([key isEqualToString:@"canScrollBar"]) {
        return self.settings.canScrollBar ? @"是" : @"否";
    } else if ([key isEqualToString:@"pagingBounce"]) {
        return self.settings.pagingBounce ? @"是" : @"否";
    } else if ([key isEqualToString:@"barBounce"]) {
        return self.settings.barBounce ? @"是" : @"否";
    } else if ([key containsString:@"Color"]) {
        return @"已设置";
    }

    return @"";
}

- (void)showDetailSettingForKey:(NSString *)key {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"设置 %@", key]
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];

    if ([key isEqualToString:@"displayMode"]) {
        [self showDisplayModeSheet];
        return;
    } else if ([key isEqualToString:@"buttonPosition"]) {
        [self showButtonPositionSheet];
        return;
    } else if ([key isEqualToString:@"itemTopOffset"]) {
        [self showOptionalNumberEditorForKey:key];
        return;
    } else if ([key isEqualToString:@"itemInsideMargins"]) {
        [self showEdgeInsetsEditor];
        return;
    } else if ([key isEqualToString:@"itemImageViewSize"]) {
        [self showSizeEditor];
        return;
    } else if ([key isEqualToString:@"scrollLineFollowFinger"] ||
               [key isEqualToString:@"slideThroughIntermediatePages"]) {
        [self showBoolEditorForKey:key];
        return;
    } else if ([key isEqualToString:@"adjustOffset"] || [key isEqualToString:@"canScrollController"] ||
               [key isEqualToString:@"canScrollBar"] || [key isEqualToString:@"pagingBounce"] ||
               [key isEqualToString:@"barBounce"]) {
        [self showLegacyBoolEditorForKey:key];
        return;
    } else if ([key isEqualToString:@"titleDefaultFont"] || [key isEqualToString:@"titleSelectedFont"]) {
        [self showFontEditorForKey:key];
        return;
    } else if ([key isEqualToString:@"selectedIndex"]) {
        [self showIndexEditor];
        return;
    } else if ([key containsString:@"Color"]) {
        [self showColorEditorForKey:key];
        return;
    } else if ([@[@"barHeight", @"originlLeftOffset", @"originlRightOffset", @"dividingOffset",
                  @"buttonDividingOffset", @"itemWidth", @"itemHeight", @"itemCornerRadius", @"itemBorderWidth",
                  @"scrollLineWidth", @"scrollLineBottomOffset", @"scrollLineCornerRadius", @"titleSelectedScale",
                  @"dividingStripHeight", @"scrollLineHeight"] containsObject:key]) {
        [self showNumberEditorForKey:key];
        return;
    } else {
        alert.message = @"该设置项暂不支持编辑";
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

// MARK: - 显示模式/按钮位置选择
- (void)showDisplayModeSheet {
    UIAlertController *modeAlert = [UIAlertController alertControllerWithTitle:@"选择显示模式"
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
    [modeAlert addAction:[UIAlertAction actionWithTitle:@"仅文本" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.settings.displayMode = DisplayModeTextOnly;
        [self.tableView reloadData];
    }]];
    [modeAlert addAction:[UIAlertAction actionWithTitle:@"仅图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.settings.displayMode = DisplayModeImageOnly;
        [self.tableView reloadData];
    }]];
    [modeAlert addAction:[UIAlertAction actionWithTitle:@"图片+文本" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.settings.displayMode = DisplayModeBoth;
        [self.tableView reloadData];
    }]];
    [modeAlert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    if (UIDevice.wy_iPadSeries) {
        [self setupPopover:modeAlert forKey:@"displayMode"];
    }
    [self presentViewController:modeAlert animated:YES completion:nil];
}

- (void)showButtonPositionSheet {
    UIAlertController *posAlert = [UIAlertController alertControllerWithTitle:@"按钮位置"
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray<NSNumber *> *positions = @[@(WYButtonPositionImageLeftTitleRight),
                                       @(WYButtonPositionImageRightTitleLeft),
                                       @(WYButtonPositionImageTopTitleBottom),
                                       @(WYButtonPositionImageBottomTitleTop)];
    NSArray<NSString *> *positionNames = @[@"图片左文字右", @"图片右文字左", @"图片上文字下", @"图片下文字上"];

    for (NSInteger i = 0; i < positionNames.count; i++) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:positionNames[i]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
            self.settings.buttonPosition = [positions[i] integerValue];
            [self.tableView reloadData];
        }];
        [posAlert addAction:action];
    }
    [posAlert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    if (UIDevice.wy_iPadSeries) {
        [self setupPopover:posAlert forKey:@"buttonPosition"];
    }
    [self presentViewController:posAlert animated:YES completion:nil];
}

// MARK: - 数值编辑
- (void)showNumberEditorForKey:(NSString *)key {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"输入数值"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeDecimalPad;
        textField.placeholder = @"请输入数值";
        CGFloat currentValue = 0;
        if ([key isEqualToString:@"barHeight"]) currentValue = self.settings.barHeight;
        else if ([key isEqualToString:@"originlLeftOffset"]) currentValue = self.settings.originlLeftOffset;
        else if ([key isEqualToString:@"originlRightOffset"]) currentValue = self.settings.originlRightOffset;
        else if ([key isEqualToString:@"dividingOffset"]) currentValue = self.settings.dividingOffset;
        else if ([key isEqualToString:@"buttonDividingOffset"]) currentValue = self.settings.buttonDividingOffset;
        else if ([key isEqualToString:@"itemWidth"]) currentValue = self.settings.itemWidth;
        else if ([key isEqualToString:@"itemHeight"]) currentValue = self.settings.itemHeight;
        else if ([key isEqualToString:@"itemCornerRadius"]) currentValue = self.settings.itemCornerRadius;
        else if ([key isEqualToString:@"itemBorderWidth"]) currentValue = self.settings.itemBorderWidth;
        else if ([key isEqualToString:@"scrollLineWidth"]) currentValue = self.settings.scrollLineWidth;
        else if ([key isEqualToString:@"scrollLineBottomOffset"]) currentValue = self.settings.scrollLineBottomOffset;
        else if ([key isEqualToString:@"scrollLineCornerRadius"]) currentValue = self.settings.scrollLineCornerRadius;
        else if ([key isEqualToString:@"titleSelectedScale"]) currentValue = self.settings.titleSelectedScale;
        else if ([key isEqualToString:@"dividingStripHeight"]) currentValue = self.settings.dividingStripHeight;
        else if ([key isEqualToString:@"scrollLineHeight"]) currentValue = self.settings.scrollLineHeight;

        textField.text = [NSString stringWithFormat:@"%@", @(currentValue)];
    }];

    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alert.textFields.firstObject;
        if (textField.text.length > 0) {
            CGFloat value = [textField.text doubleValue];
            if ([key isEqualToString:@"barHeight"]) self.settings.barHeight = value;
            else if ([key isEqualToString:@"originlLeftOffset"]) self.settings.originlLeftOffset = value;
            else if ([key isEqualToString:@"originlRightOffset"]) self.settings.originlRightOffset = value;
            else if ([key isEqualToString:@"dividingOffset"]) self.settings.dividingOffset = value;
            else if ([key isEqualToString:@"buttonDividingOffset"]) self.settings.buttonDividingOffset = value;
            else if ([key isEqualToString:@"itemWidth"]) self.settings.itemWidth = value;
            else if ([key isEqualToString:@"itemHeight"]) self.settings.itemHeight = value;
            else if ([key isEqualToString:@"itemCornerRadius"]) self.settings.itemCornerRadius = value;
            else if ([key isEqualToString:@"itemBorderWidth"]) self.settings.itemBorderWidth = value;
            else if ([key isEqualToString:@"scrollLineWidth"]) self.settings.scrollLineWidth = value;
            else if ([key isEqualToString:@"scrollLineBottomOffset"]) self.settings.scrollLineBottomOffset = value;
            else if ([key isEqualToString:@"scrollLineCornerRadius"]) self.settings.scrollLineCornerRadius = value;
            else if ([key isEqualToString:@"titleSelectedScale"]) self.settings.titleSelectedScale = value;
            else if ([key isEqualToString:@"dividingStripHeight"]) self.settings.dividingStripHeight = value;
            else if ([key isEqualToString:@"scrollLineHeight"]) self.settings.scrollLineHeight = value;

            [self.tableView reloadData];
        }
    }];
    [alert addAction:confirmAction];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showOptionalNumberEditorForKey:(NSString *)key {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"输入数值（留空则为nil）"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeDecimalPad;
        if ([key isEqualToString:@"itemTopOffset"]) {
            textField.text = [NSString stringWithFormat:@"%.0f", self.settings.itemTopOffset];
        }
    }];

    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alert.textFields.firstObject;
        if (textField.text.length > 0) {
            if ([key isEqualToString:@"itemTopOffset"]) self.settings.itemTopOffset = [textField.text floatValue];
        } else {
            if ([key isEqualToString:@"itemTopOffset"]) self.settings.itemTopOffset = 0;
        }
        [self.tableView reloadData];
    }];
    [alert addAction:confirmAction];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

// MARK: - 布尔编辑
- (void)showBoolEditorForKey:(NSString *)key {
    BOOL currentValue = NO;
    if ([key isEqualToString:@"scrollLineFollowFinger"]) currentValue = self.settings.scrollLineFollowFinger;
    else if ([key isEqualToString:@"slideThroughIntermediatePages"]) currentValue = self.settings.slideThroughIntermediatePages;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"切换状态"
                                                                   message:currentValue ? @"当前状态: 开启" : @"当前状态: 关闭"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"切换" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([key isEqualToString:@"scrollLineFollowFinger"]) self.settings.scrollLineFollowFinger = !currentValue;
        else if ([key isEqualToString:@"slideThroughIntermediatePages"]) self.settings.slideThroughIntermediatePages = !currentValue;
        [self.tableView reloadData];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showLegacyBoolEditorForKey:(NSString *)key {
    BOOL currentValue = NO;
    if ([key isEqualToString:@"adjustOffset"]) currentValue = self.settings.adjustOffset;
    else if ([key isEqualToString:@"canScrollController"]) currentValue = self.settings.canScrollController;
    else if ([key isEqualToString:@"canScrollBar"]) currentValue = self.settings.canScrollBar;
    else if ([key isEqualToString:@"pagingBounce"]) currentValue = self.settings.pagingBounce;
    else if ([key isEqualToString:@"barBounce"]) currentValue = self.settings.barBounce;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"切换状态"
                                                                   message:currentValue ? @"当前状态: 开启" : @"当前状态: 关闭"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"切换" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([key isEqualToString:@"adjustOffset"]) self.settings.adjustOffset = !currentValue;
        else if ([key isEqualToString:@"canScrollController"]) self.settings.canScrollController = !currentValue;
        else if ([key isEqualToString:@"canScrollBar"]) self.settings.canScrollBar = !currentValue;
        else if ([key isEqualToString:@"pagingBounce"]) self.settings.pagingBounce = !currentValue;
        else if ([key isEqualToString:@"barBounce"]) self.settings.barBounce = !currentValue;
        [self.tableView reloadData];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

// MARK: - 字体/下标/边距/尺寸编辑
- (void)showFontEditorForKey:(NSString *)key {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"输入字体大小"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeNumberPad;
        CGFloat currentSize = [key isEqualToString:@"titleDefaultFont"] ? self.settings.titleDefaultFont.pointSize : self.settings.titleSelectedFont.pointSize;
        textField.text = [NSString stringWithFormat:@"%d", (int)currentSize];
    }];

    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alert.textFields.firstObject;
        if (textField.text.length > 0) {
            CGFloat fontSize = [textField.text doubleValue];
            if ([key isEqualToString:@"titleDefaultFont"]) {
                self.settings.titleDefaultFont = [UIFont systemFontOfSize:fontSize];
            } else {
                self.settings.titleSelectedFont = [UIFont boldSystemFontOfSize:fontSize];
            }
            [self.tableView reloadData];
        }
    }];
    [alert addAction:confirmAction];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showIndexEditor {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"初始选中项"
                                                                   message:[NSString stringWithFormat:@"范围 0-%ld", (long)MAX(self.titleCount - 1, 0)]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.text = [NSString stringWithFormat:@"%ld", (long)self.settings.selectedIndex];
    }];

    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alert.textFields.firstObject;
        if (textField.text.length > 0) {
            NSInteger index = [textField.text integerValue];
            self.settings.selectedIndex = MAX(0, MIN(index, MAX(self.titleCount - 1, 0)));
            [self.tableView reloadData];
        }
    }];
    [alert addAction:confirmAction];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showEdgeInsetsEditor {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"按钮内边距 (top, left, bottom, right)"
                                                                   message:[NSString stringWithFormat:@"当前: %@", NSStringFromUIEdgeInsets(self.settings.itemInsideMargins)]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"top";
        textField.text = [NSString stringWithFormat:@"%.0f", self.settings.itemInsideMargins.top];
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"left";
        textField.text = [NSString stringWithFormat:@"%.0f", self.settings.itemInsideMargins.left];
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"bottom";
        textField.text = [NSString stringWithFormat:@"%.0f", self.settings.itemInsideMargins.bottom];
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"right";
        textField.text = [NSString stringWithFormat:@"%.0f", self.settings.itemInsideMargins.right];
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];

    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
        CGFloat top = [alert.textFields[0].text doubleValue];
        CGFloat left = [alert.textFields[1].text doubleValue];
        CGFloat bottom = [alert.textFields[2].text doubleValue];
        CGFloat right = [alert.textFields[3].text doubleValue];
        self.settings.itemInsideMargins = UIEdgeInsetsMake(top, left, bottom, right);
        [self.tableView reloadData];
    }];
    [alert addAction:confirmAction];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showSizeEditor {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"图片尺寸 (width, height)"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"宽度";
        textField.text = [NSString stringWithFormat:@"%.0f", self.settings.itemImageViewSize.width];
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"高度";
        textField.text = [NSString stringWithFormat:@"%.0f", self.settings.itemImageViewSize.height];
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];

    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
        CGFloat width = [alert.textFields[0].text doubleValue];
        CGFloat height = [alert.textFields[1].text doubleValue];
        self.settings.itemImageViewSize = CGSizeMake(width, height);
        [self.tableView reloadData];
    }];
    [alert addAction:confirmAction];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

// MARK: - 颜色编辑
- (void)showColorEditorForKey:(NSString *)key {
    UIAlertController *colorAlert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"选择 %@ 颜色", key]
                                                                        message:nil
                                                                 preferredStyle:UIAlertControllerStyleActionSheet];

    for (NSString *name in self.colorOptions.allKeys) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:name
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
            [self setColor:self.colorOptions[name] forKey:key];
            [self.tableView reloadData];
        }];
        [colorAlert addAction:action];
    }

    UIAlertAction *customAction = [UIAlertAction actionWithTitle:@"自定义颜色"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
        [self showCustomColorPickerForKey:key];
    }];
    [colorAlert addAction:customAction];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [colorAlert addAction:cancelAction];

    if (UIDevice.wy_iPadSeries) {
        [self setupPopover:colorAlert forKey:key];
    }

    [self presentViewController:colorAlert animated:YES completion:nil];
}

- (void)showCustomColorPickerForKey:(NSString *)key {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"自定义颜色 - %@", key]
                                                                   message:@"请输入RGB值 (0-255)"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"红色 (0-255)";
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"绿色 (0-255)";
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"蓝色 (0-255)";
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];

    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
        UITextField *redField = alert.textFields[0];
        UITextField *greenField = alert.textFields[1];
        UITextField *blueField = alert.textFields[2];

        if (redField.text.length > 0 && greenField.text.length > 0 && blueField.text.length > 0) {
            NSInteger red = [redField.text integerValue];
            NSInteger green = [greenField.text integerValue];
            NSInteger blue = [blueField.text integerValue];

            UIColor *color = [UIColor colorWithRed:red/255.0
                                             green:green/255.0
                                              blue:blue/255.0
                                             alpha:1.0];
            [self setColor:color forKey:key];
            [self.tableView reloadData];
        }
    }];
    [alert addAction:confirmAction];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (UIColor *)colorValueForKey:(NSString *)key {
    if ([key isEqualToString:@"pagingContentColor"]) {
        return self.settings.pagingContentColor;
    } else if ([key isEqualToString:@"pagingBgColor"]) {
        return self.settings.pagingBgColor ?: [UIColor clearColor];
    } else if ([key isEqualToString:@"barBgColor"]) {
        return self.settings.barBgColor;
    } else if ([key isEqualToString:@"itemDefaultBgColor"]) {
        return self.settings.itemDefaultBgColor;
    } else if ([key isEqualToString:@"itemSelectedBgColor"]) {
        return self.settings.itemSelectedBgColor;
    } else if ([key isEqualToString:@"itemNormalBorderColor"]) {
        return self.settings.itemNormalBorderColor ?: [UIColor clearColor];
    } else if ([key isEqualToString:@"itemSelectedBorderColor"]) {
        return self.settings.itemSelectedBorderColor ?: [UIColor clearColor];
    } else if ([key isEqualToString:@"titleDefaultColor"]) {
        return self.settings.titleDefaultColor;
    } else if ([key isEqualToString:@"titleSelectedColor"]) {
        return self.settings.titleSelectedColor;
    } else if ([key isEqualToString:@"dividingStripColor"]) {
        return self.settings.dividingStripColor;
    } else if ([key isEqualToString:@"scrollLineColor"]) {
        return self.settings.scrollLineColor;
    }
    return [UIColor clearColor];
}

- (void)setColor:(UIColor *)color forKey:(NSString *)key {
    if ([key isEqualToString:@"pagingContentColor"]) {
        self.settings.pagingContentColor = color;
    } else if ([key isEqualToString:@"pagingBgColor"]) {
        self.settings.pagingBgColor = color;
    } else if ([key isEqualToString:@"barBgColor"]) {
        self.settings.barBgColor = color;
    } else if ([key isEqualToString:@"itemDefaultBgColor"]) {
        self.settings.itemDefaultBgColor = color;
    } else if ([key isEqualToString:@"itemSelectedBgColor"]) {
        self.settings.itemSelectedBgColor = color;
    } else if ([key isEqualToString:@"itemNormalBorderColor"]) {
        self.settings.itemNormalBorderColor = color;
    } else if ([key isEqualToString:@"itemSelectedBorderColor"]) {
        self.settings.itemSelectedBorderColor = color;
    } else if ([key isEqualToString:@"titleDefaultColor"]) {
        self.settings.titleDefaultColor = color;
    } else if ([key isEqualToString:@"titleSelectedColor"]) {
        self.settings.titleSelectedColor = color;
    } else if ([key isEqualToString:@"dividingStripColor"]) {
        self.settings.dividingStripColor = color;
    } else if ([key isEqualToString:@"scrollLineColor"]) {
        self.settings.scrollLineColor = color;
    }
}

- (NSIndexPath *)indexPathForKey:(NSString *)key {
    for (NSInteger section = 0; section < self.items.count; section++) {
        for (NSInteger row = 0; row < self.items[section].count; row++) {
            NSDictionary *item = self.items[section][row];
            if ([item[@"key"] isEqualToString:key]) {
                return [NSIndexPath indexPathForRow:row inSection:section];
            }
        }
    }
    return nil;
}

- (void)setupPopover:(UIAlertController *)alert forKey:(NSString *)key {
    alert.popoverPresentationController.sourceView = self.tableView;
    NSIndexPath *foundPath = [self indexPathForKey:key];
    if (foundPath) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:foundPath];
        alert.popoverPresentationController.sourceRect = cell.bounds;
        alert.popoverPresentationController.sourceView = cell;
    }
}

- (void)saveSettings {
    [self.delegate didSaveSettings:self.settings];
}

- (void)cancelSettings {
    [self.delegate didCancelSettings];
}

#pragma mark - Lazy Loading

- (NSArray<NSString *> *)sections {
    if (!_sections) {
        _sections = @[@"显示模式", @"基本属性", @"颜色设置", @"尺寸设置", @"高级属性", @"字体设置", @"其他设置"];
    }
    return _sections;
}

- (NSArray<NSArray<NSDictionary *> *> *)items {
    if (!_items) {
        _items = @[
            // 显示模式
            @[
                @{@"title": @"显示模式", @"key": @"displayMode"}
            ],
            // 基本属性
            @[
                @{@"title": @"分页栏高度", @"key": @"barHeight"},
                @{@"title": @"按钮位置", @"key": @"buttonPosition"},
                @{@"title": @"左偏移量", @"key": @"originlLeftOffset"},
                @{@"title": @"右偏移量", @"key": @"originlRightOffset"},
                @{@"title": @"Item顶部偏移", @"key": @"itemTopOffset"},
                @{@"title": @"居中调整", @"key": @"adjustOffset"},
                @{@"title": @"分栏间距", @"key": @"dividingOffset"},
                @{@"title": @"按钮内间距", @"key": @"buttonDividingOffset"}
            ],
            // 颜色设置
            @[
                @{@"title": @"页面内容颜色", @"key": @"pagingContentColor"},
                @{@"title": @"页面背景颜色", @"key": @"pagingBgColor"},
                @{@"title": @"分页栏背景色", @"key": @"barBgColor"},
                @{@"title": @"Item默认背景", @"key": @"itemDefaultBgColor"},
                @{@"title": @"Item选中背景", @"key": @"itemSelectedBgColor"},
                @{@"title": @"Item边框色(默认)", @"key": @"itemNormalBorderColor"},
                @{@"title": @"Item边框色(选中)", @"key": @"itemSelectedBorderColor"},
                @{@"title": @"标题默认颜色", @"key": @"titleDefaultColor"},
                @{@"title": @"标题选中颜色", @"key": @"titleSelectedColor"},
                @{@"title": @"分隔带颜色", @"key": @"dividingStripColor"},
                @{@"title": @"滑动线颜色", @"key": @"scrollLineColor"}
            ],
            // 尺寸设置
            @[
                @{@"title": @"Item宽度", @"key": @"itemWidth"},
                @{@"title": @"Item高度", @"key": @"itemHeight"},
                @{@"title": @"Item圆角", @"key": @"itemCornerRadius"},
                @{@"title": @"Item边框宽", @"key": @"itemBorderWidth"},
                @{@"title": @"滑动线宽度", @"key": @"scrollLineWidth"},
                @{@"title": @"滑动线底部偏移", @"key": @"scrollLineBottomOffset"},
                @{@"title": @"滑动线圆角", @"key": @"scrollLineCornerRadius"},
                @{@"title": @"分隔带高度", @"key": @"dividingStripHeight"},
                @{@"title": @"滑动线高度", @"key": @"scrollLineHeight"},
                @{@"title": @"选中缩放", @"key": @"titleSelectedScale"}
            ],
            // 高级属性
            @[
                @{@"title": @"滑动线跟随手指", @"key": @"scrollLineFollowFinger"},
                @{@"title": @"按钮内边距", @"key": @"itemInsideMargins"},
                @{@"title": @"图片尺寸", @"key": @"itemImageViewSize"}
            ],
            // 字体设置
            @[
                @{@"title": @"默认字体大小", @"key": @"titleDefaultFont"},
                @{@"title": @"选中字体大小", @"key": @"titleSelectedFont"}
            ],
            // 其他设置
            @[
                @{@"title": @"初始选中项", @"key": @"selectedIndex"},
                @{@"title": @"控制器可滚动", @"key": @"canScrollController"},
                @{@"title": @"分页栏可滚动", @"key": @"canScrollBar"},
                @{@"title": @"远距滑动中间页", @"key": @"slideThroughIntermediatePages"},
                @{@"title": @"内容区弹跳", @"key": @"pagingBounce"},
                @{@"title": @"分页栏弹跳", @"key": @"barBounce"}
            ]
        ];
    }
    return _items;
}

- (NSDictionary<NSString *,UIColor *> *)colorOptions {
    if (!_colorOptions) {
        _colorOptions = @{
            @"白色": [UIColor whiteColor],
            @"黑色": [UIColor blackColor],
            @"红色": [UIColor redColor],
            @"绿色": [UIColor greenColor],
            @"蓝色": [UIColor blueColor],
            @"黄色": [UIColor yellowColor],
            @"橙色": [UIColor orangeColor],
            @"紫色": [UIColor purpleColor],
            @"灰色": [UIColor grayColor],
            @"浅灰色": [UIColor lightGrayColor],
            @"默认标题色": [UIColor wy_hex:@"#7B809E"],
            @"选中标题色": [UIColor wy_hex:@"#2D3952"],
            @"分隔带色": [UIColor wy_hex:@"#F2F2F2"],
            @"滑动线色": [UIColor wy_hex:@"#2D3952"]
        };
    }
    return _colorOptions;
}

@end

// MARK: - 主控制器
@interface WYTestPagingViewController () <WYPagingViewDelegate, PagingSettingsDelegate>

/// 分页控件(整个生命周期复用同一个实例，首次布局、设置更新、动态加减/插删/换顺序都通过重调layout原地重载)
@property (nonatomic, strong) WYPagingView *pagingView;
@property (nonatomic, strong) UIBarButtonItem *settingsButton;
@property (nonatomic, strong) PagingSettingsModel *settings;

/// 动态修改title数量的悬浮控件(固定盖在WYPagingView右下角，不占用导航栏，避免顶掉返回按钮)
@property (nonatomic, strong) UIView *countControl;
@property (nonatomic, strong) UIButton *increaseButton;
@property (nonatomic, strong) UIButton *reduceButton;
@property (nonatomic, strong) UIButton *countButton;

/// 最多准备的测试页数(需要覆盖固定Item宽度下超一屏滚动等场景，20页已远超常见业务规模)
@property (nonatomic, assign) NSInteger maxTestPageCount;

/// 测试页循环使用的背景色与图标(固定前8页与动态生成的页共用一套)
@property (nonatomic, strong) NSArray<UIColor *> *pageColors;
@property (nonatomic, strong) NSArray<NSString *> *pageDefaultSymbols;
@property (nonatomic, strong) NSArray<NSString *> *pageSelectedSymbols;

/// 备好的测试页(前8页有专属标题与图标，超出后由firstUnusedItem按序号动态生成)
@property (nonatomic, strong) NSMutableArray<TestPageItem *> *allPageItems;

/// 当前展示中的测试页(数量和顺序都会变，模拟接口下发的title数量与顺序)
@property (nonatomic, strong) NSMutableArray<TestPageItem *> *currentItems;

@end

@implementation WYTestPagingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupNavigationBar];

    // 首次进入默认展示前5页(之后插删页/换顺序/设置保存改的是currentItems，均保持现状)
    if (self.currentItems.count == 0) {
        [self.currentItems addObjectsFromArray:[self.allPageItems subarrayWithRange:NSMakeRange(0, 5)]];
    }

    [self applySettings];
    [self setupCountControl];
    [self reloadPagingView];
}

- (void)setupNavigationBar {
    self.title = @"WYPagingView 测试";

    self.settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"设置"
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(showSettings)];
    self.navigationItem.rightBarButtonItem = self.settingsButton;

    self.wy_navBarBackgroundColor = [UIColor orangeColor];
}

#pragma mark - 懒加载

- (WYPagingView *)pagingView {
    if (!_pagingView) {
        _pagingView = [[WYPagingView alloc] init];
        _pagingView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:_pagingView];

        [_pagingView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
            make.leading.equalTo(self.view);
            make.trailing.equalTo(self.view);
            make.bottom.equalTo(self.view);
        }];

        // 代理和闭包随实例创建注册一次即可，原地重载不会清除
        _pagingView.delegate = self;
        [_pagingView itemDidScroll:^(WYPagingView * _Nonnull pagingView, NSInteger pagingIndex, BOOL isFirstDisplayed) {
            NSLog(@"分页滚动到第 %ld 页 - 通过闭包回调", (long)pagingIndex);
        }];
        [_pagingView itemDidLayout:^(WYPagingView * _Nonnull pagingView) {
            NSLog(@"分页视图布局完成 - 闭包回调");
        }];
        [_pagingView itemDidRepeatClick:^(WYPagingView * _Nonnull pagingView, NSInteger pagingIndex) {
            NSLog(@"重复点击了当前页 第 %ld 页 - 通过闭包回调", (long)pagingIndex + 1);
        }];
    }
    return _pagingView;
}

- (PagingSettingsModel *)settings {
    if (!_settings) {
        _settings = [[PagingSettingsModel alloc] init];
    }
    return _settings;
}

- (NSInteger)maxTestPageCount {
    if (_maxTestPageCount == 0) {
        _maxTestPageCount = 20;
    }
    return _maxTestPageCount;
}

- (NSArray<UIColor *> *)pageColors {
    if (!_pageColors) {
        _pageColors = @[[UIColor redColor], [UIColor greenColor], [UIColor blueColor], [UIColor yellowColor], [UIColor purpleColor], [UIColor orangeColor], [UIColor cyanColor], [UIColor magentaColor]];
    }
    return _pageColors;
}

- (NSArray<NSString *> *)pageDefaultSymbols {
    if (!_pageDefaultSymbols) {
        _pageDefaultSymbols = @[@"house", @"message", @"magnifyingglass", @"person", @"gearshape", @"star", @"trash", @"flag"];
    }
    return _pageDefaultSymbols;
}

- (NSArray<NSString *> *)pageSelectedSymbols {
    if (!_pageSelectedSymbols) {
        _pageSelectedSymbols = @[@"house.fill", @"message.fill", @"magnifyingglass.circle.fill", @"person.fill", @"gearshape.fill", @"star.fill", @"trash.fill", @"flag.fill"];
    }
    return _pageSelectedSymbols;
}

- (NSMutableArray<TestPageItem *> *)allPageItems {
    if (!_allPageItems) {
        _allPageItems = [NSMutableArray array];

        NSArray<NSString *> *titles = @[@"首页", @"消息", @"发现", @"我的", @"设置", @"收藏", @"草稿", @"关于"];

        for (NSInteger index = 0; index < self.pageColors.count; index++) {
            UIViewController *controller = [[UIViewController alloc] init];
            controller.view.backgroundColor = self.pageColors[index];
            controller.view.layer.borderWidth = 2;
            controller.view.layer.borderColor = [UIColor blackColor].CGColor;

            TestPageItem *item = [[TestPageItem alloc] initWithController:controller
                                                                    title:titles[index]
                                                              defaultImage:[UIImage systemImageNamed:self.pageDefaultSymbols[index]]
                                                              selectedImage:[UIImage systemImageNamed:self.pageSelectedSymbols[index]]];
            [_allPageItems addObject:item];
        }
    }
    return _allPageItems;
}

- (NSMutableArray<TestPageItem *> *)currentItems {
    if (!_currentItems) {
        _currentItems = [NSMutableArray array];
    }
    return _currentItems;
}

- (UIView *)countControl {
    if (!_countControl) {
        _countControl = [[UIView alloc] init];
        _countControl.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.92];
        _countControl.layer.cornerRadius = 18;
        _countControl.layer.shadowColor = [UIColor blackColor].CGColor;
        _countControl.layer.shadowOpacity = 0.15;
        _countControl.layer.shadowRadius = 4;
        _countControl.layer.shadowOffset = CGSizeMake(0, 2);
        _countControl.translatesAutoresizingMaskIntoConstraints = NO;

        [_countControl addSubview:self.reduceButton];
        [_countControl addSubview:self.countButton];
        [_countControl addSubview:self.increaseButton];

        [self.reduceButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_countControl);
            make.centerY.equalTo(_countControl);
            make.width.mas_offset(40);
            make.height.equalTo(_countControl);
        }];

        [self.countButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.reduceButton.mas_trailing);
            make.centerY.equalTo(_countControl);
            make.width.mas_offset(60);
        }];

        [self.increaseButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.countButton.mas_trailing);
            make.trailing.equalTo(_countControl);
            make.centerY.equalTo(_countControl);
            make.width.mas_offset(40);
            make.height.equalTo(_countControl);
        }];
    }
    return _countControl;
}

/// 数量+1按钮(到达上限时置灰)
- (UIButton *)increaseButton {
    if (!_increaseButton) {
        _increaseButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_increaseButton setTitle:@"＋" forState:UIControlStateNormal];
        _increaseButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        [_increaseButton addTarget:self action:@selector(increaseTitleCount) forControlEvents:UIControlEventTouchUpInside];
        _increaseButton.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _increaseButton;
}

/// 数量-1按钮(到达下限时置灰)
- (UIButton *)reduceButton {
    if (!_reduceButton) {
        _reduceButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_reduceButton setTitle:@"－" forState:UIControlStateNormal];
        _reduceButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        [_reduceButton addTarget:self action:@selector(reduceTitleCount) forControlEvents:UIControlEventTouchUpInside];
        _reduceButton.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _reduceButton;
}

/// 当前页数展示按钮(点击弹出插删页/换顺序操作菜单)
- (UIButton *)countButton {
    if (!_countButton) {
        _countButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _countButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        [_countButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [_countButton addTarget:self action:@selector(showPageOperations) forControlEvents:UIControlEventTouchUpInside];
        _countButton.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _countButton;
}

#pragma mark - 悬浮控件

- (void)setupCountControl {
    [self.view addSubview:self.countControl];

    [self.countControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight).offset(-16);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
        make.height.mas_offset(36);
        make.width.mas_offset(140);
    }];

    [self updateCountControlState];
}

- (void)updateCountControlState {
    [self.countButton setTitle:[NSString stringWithFormat:@"数量 %ld", (long)self.currentItems.count] forState:UIControlStateNormal];
    self.increaseButton.enabled = ([self firstUnusedItem] != nil);
    self.reduceButton.enabled = (self.currentItems.count > 1);
}

#pragma mark - 设置应用与重载

- (void)applySettings {
    WYPagingView *pagingView = self.pagingView;
    PagingSettingsModel *settings = self.settings;

    // 基本属性
    pagingView.bar_height = settings.barHeight;
    pagingView.buttonPosition = settings.buttonPosition;
    pagingView.bar_originlLeftOffset = settings.originlLeftOffset;
    pagingView.bar_originlRightOffset = settings.originlRightOffset;
    pagingView.bar_itemTopOffset = settings.itemTopOffset;
    pagingView.bar_adjustOffset = settings.adjustOffset;
    pagingView.bar_dividingOffset = settings.dividingOffset;
    pagingView.barButton_dividingOffset = settings.buttonDividingOffset;

    // 颜色设置
    pagingView.bar_pagingContro_content_color = settings.pagingContentColor;
    pagingView.bar_pagingContro_bg_color = settings.pagingBgColor;
    pagingView.bar_bg_defaultColor = settings.barBgColor;
    pagingView.bar_item_bg_defaultColor = settings.itemDefaultBgColor;
    pagingView.bar_item_bg_selectedColor = settings.itemSelectedBgColor;
    pagingView.bar_item_normalBorderColor = settings.itemNormalBorderColor;
    pagingView.bar_item_selectedBorderColor = settings.itemSelectedBorderColor;
    pagingView.bar_title_defaultColor = settings.titleDefaultColor;
    pagingView.bar_title_selectedColor = settings.titleSelectedColor;
    pagingView.bar_dividingStripColor = settings.dividingStripColor;
    pagingView.bar_scrollLineColor = settings.scrollLineColor;

    // 图片资源
    pagingView.bar_dividingStripImage = settings.dividingStripImage;
    pagingView.bar_scrollLineImage = settings.scrollLineImage;

    // 尺寸设置
    pagingView.bar_item_width = settings.itemWidth;
    pagingView.bar_item_height = settings.itemHeight;
    pagingView.bar_item_cornerRadius = settings.itemCornerRadius;
    pagingView.bar_item_borderWidth = settings.itemBorderWidth;
    pagingView.bar_scrollLineWidth = settings.scrollLineWidth;
    pagingView.bar_scrollLineBottomOffset = settings.scrollLineBottomOffset;
    pagingView.bar_scrollLineCornerRadius = settings.scrollLineCornerRadius;
    pagingView.bar_title_selectedScale = settings.titleSelectedScale;
    pagingView.bar_dividingStripHeight = settings.dividingStripHeight;
    pagingView.bar_scrollLineHeight = settings.scrollLineHeight;

    // 新增属性
    pagingView.bar_scrollLineFollowFinger = settings.scrollLineFollowFinger;
    pagingView.bar_item_insideMargins = settings.itemInsideMargins;
    pagingView.bar_item_imageViewSize = settings.itemImageViewSize;

    // 字体设置
    pagingView.bar_title_defaultFont = settings.titleDefaultFont;
    pagingView.bar_title_selectedFont = settings.titleSelectedFont;

    // 其他设置
    pagingView.bar_selectedIndex = settings.selectedIndex;
    pagingView.canScrollController = settings.canScrollController;
    pagingView.canScrollBar = settings.canScrollBar;
    pagingView.slideThroughIntermediatePages = settings.slideThroughIntermediatePages;
    pagingView.bar_pagingContro_bounce = settings.pagingBounce;
    pagingView.bar_bounce = settings.barBounce;
}

/// 原地(重新)布局分页控件(首次进入、设置保存、加减数量、插删页、换顺序都走这里，落位过渡由控件内部处理)
- (void)reloadPagingView {
    NSMutableArray<UIViewController *> *controllers = [NSMutableArray array];
    for (TestPageItem *item in self.currentItems) {
        [controllers addObject:item.controller];
    }

    NSArray<NSString *> *titles = nil;
    NSArray<UIImage *> *defaultImages = nil;
    NSArray<UIImage *> *selectedImages = nil;
    NSArray<NSArray *> *displayParams = [self resolveDisplayModeParameters];
    titles = displayParams[0];
    defaultImages = displayParams[1];
    selectedImages = displayParams[2];

    [self.pagingView layoutWithControllers:controllers
                                      titles:titles
                               defaultImages:defaultImages
                              selectedImages:selectedImages
                         superViewController:self];
}

/// 根据显示模式返回对应的 titles 和 images 数组(跟随currentItems的数量与顺序)
- (NSArray<NSArray *> *)resolveDisplayModeParameters {
    NSMutableArray<NSString *> *titles = [NSMutableArray array];
    NSMutableArray<UIImage *> *defaultImages = [NSMutableArray array];
    NSMutableArray<UIImage *> *selectedImages = [NSMutableArray array];

    switch (self.settings.displayMode) {
        case DisplayModeTextOnly:
            for (TestPageItem *item in self.currentItems) {
                [titles addObject:item.title];
            }
            break;
        case DisplayModeImageOnly:
            for (TestPageItem *item in self.currentItems) {
                [defaultImages addObject:item.defaultImage];
                [selectedImages addObject:item.selectedImage];
            }
            break;
        case DisplayModeBoth:
            for (TestPageItem *item in self.currentItems) {
                [titles addObject:item.title];
                [defaultImages addObject:item.defaultImage];
                [selectedImages addObject:item.selectedImage];
            }
            break;
    }

    return @[titles, defaultImages, selectedImages];
}

#pragma mark - 数量加减

- (void)increaseTitleCount {
    [self changeTitleCount:1];
}

- (void)reduceTitleCount {
    [self changeTitleCount:-1];
}

/**
 * 调整末尾页数量并原地重载当前WYPagingView(中间位置插删、换顺序见showPageOperations菜单)
 *
 * @param delta 数量变化值(正数末尾加一页，负数末尾减一页)
 */
- (void)changeTitleCount:(NSInteger)delta {

    if (delta > 0) {
        TestPageItem *unusedItem = [self firstUnusedItem];
        if (unusedItem == nil) { return; }
        [self.currentItems addObject:unusedItem];
    } else {
        if (self.currentItems.count <= 1) { return; }
        [self.currentItems removeLastObject];
    }

    [self updateCountControlState];
    [self reloadPagingView];
}

#pragma mark - 操作菜单

/// 弹出插删页/换顺序/代码切页操作菜单(模拟接口下发不同数量与顺序的title，并验证switchToPage与重复点击回调)
- (void)showPageOperations {

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"页面操作"
                                                                   message:[NSString stringWithFormat:@"当前 %ld 页", (long)self.currentItems.count]
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    if ([self firstUnusedItem] != nil) {
        [alert addAction:[UIAlertAction actionWithTitle:@"随机位置插入一页" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self insertRandomPage];
        }]];
    }

    if (self.currentItems.count > 1) {
        [alert addAction:[UIAlertAction actionWithTitle:@"删除随机一页" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self removeRandomPage];
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:@"打乱顺序" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self shufflePages];
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:@"代码切页到第3页(动画)" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.pagingView switchToPageAt:2 animated:YES];
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:@"代码切页到第4页(直切)" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.pagingView switchToPageAt:3 animated:NO];
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:@"代码切页越界(应无效)" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.pagingView switchToPageAt:99 animated:YES];
        }]];
    }

    [alert addAction:[UIAlertAction actionWithTitle:@"点击当前页(重复点击回调)" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSInteger current = self.pagingView.bar_selectedIndex;
        for (WYPagingItem *item in self.pagingView.buttonItems) {
            if (item.tag == 1000 + current) {
                [item sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            }
        }
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"恢复初始5页" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self resetPages];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    // 防iPad上actionSheet没有锚点报错:指向悬浮控件弹出
    if (alert.popoverPresentationController) {
        alert.popoverPresentationController.sourceView = self.countControl;
        alert.popoverPresentationController.sourceRect = self.countControl.bounds;
    }

    [self presentViewController:alert animated:YES completion:nil];
}

/// 在随机位置插入一页没在展示中的页
- (void)insertRandomPage {

    TestPageItem *unusedItem = [self firstUnusedItem];
    if (unusedItem == nil) { return; }

    NSUInteger insertIndex = arc4random_uniform((uint32_t)self.currentItems.count + 1);
    [self.currentItems insertObject:unusedItem atIndex:insertIndex];

    [self updateCountControlState];
    [self reloadPagingView];
}

/// 删除随机一页
- (void)removeRandomPage {

    if (self.currentItems.count <= 1) { return; }

    [self.currentItems removeObjectAtIndex:arc4random_uniform((uint32_t)self.currentItems.count)];

    [self updateCountControlState];
    [self reloadPagingView];
}

/// 打乱当前页顺序(数量不变，验证选中页跟着同一页内容走)
- (void)shufflePages {

    if (self.currentItems.count <= 1) { return; }

    NSUInteger count = self.currentItems.count;
    for (NSUInteger index = count - 1; index > 0; index--) {
        NSUInteger randomIndex = arc4random_uniform((uint32_t)(index + 1));
        if (randomIndex != index) {
            TestPageItem *item = self.currentItems[index];
            [self.currentItems removeObjectAtIndex:index];
            [self.currentItems insertObject:item atIndex:randomIndex];
        }
    }

    [self reloadPagingView];
}

/// 恢复成初始的前5页
- (void)resetPages {

    [self.currentItems removeAllObjects];
    [self.currentItems addObjectsFromArray:[self.allPageItems subarrayWithRange:NSMakeRange(0, 5)]];

    [self updateCountControlState];
    [self reloadPagingView];
}

/// 取第一个没在展示中的测试页(固定数据用完后动态生成，到maxTestPageCount上限后返回nil)
- (TestPageItem *)firstUnusedItem {

    for (TestPageItem *item in self.allPageItems) {
        BOOL isUsed = NO;
        for (TestPageItem *currentItem in self.currentItems) {
            if (currentItem.controller == item.controller) {
                isUsed = YES;
                break;
            }
        }
        if (isUsed == NO) {
            return item;
        }
    }

    // 防+号加到8页就到顶(前8页是固定数据):数据不够时按序号动态生成，直到maxTestPageCount上限
    if (self.allPageItems.count < (NSUInteger)self.maxTestPageCount) {
        TestPageItem *newItem = [self makePageItemWithSlot:self.allPageItems.count];
        [self.allPageItems addObject:newItem];
        return newItem;
    }

    return nil;
}

/// 按序号动态生成一页测试页(标题带序号，颜色与图标循环取用)
- (TestPageItem *)makePageItemWithSlot:(NSInteger)slot {

    UIViewController *controller = [[UIViewController alloc] init];
    controller.view.backgroundColor = self.pageColors[slot % self.pageColors.count];
    controller.view.layer.borderWidth = 2;
    controller.view.layer.borderColor = [UIColor blackColor].CGColor;

    return [[TestPageItem alloc] initWithController:controller
                                              title:[NSString stringWithFormat:@"页面%ld", (long)slot + 1]
                                        defaultImage:[UIImage systemImageNamed:self.pageDefaultSymbols[slot % self.pageDefaultSymbols.count]]
                                        selectedImage:[UIImage systemImageNamed:self.pageSelectedSymbols[slot % self.pageSelectedSymbols.count]]];
}

- (void)showSettings {
    PagingSettingsViewController *settingsVC = [[PagingSettingsViewController alloc] initWithSettings:self.settings];
    settingsVC.delegate = self;
    settingsVC.titleCount = self.currentItems.count;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - WYPagingViewDelegate

- (void)wy_pagingViewItemDidScroll:(WYPagingView *)pagingView pagingIndex:(NSInteger)pagingIndex displayed:(BOOL)isFirstDisplayed {
    NSLog(@"分页滚动到第 %ld 页 - 通过代理回调, %@第一次显示该页面", (long)pagingIndex, isFirstDisplayed ? @"是" : @"不是");
}

- (void)wy_pagingViewLayoutDidCompleted:(WYPagingView *)pagingView {
    NSLog(@"分页视图布局完成 - 代理回调");
}

- (void)wy_pagingViewItemDidRepeatClick:(WYPagingView *)pagingView pagingIndex:(NSInteger)pagingIndex {
    NSLog(@"重复点击了当前页 第 %ld 页 - 代理回调", (long)pagingIndex + 1);
}

#pragma mark - PagingSettingsDelegate

- (void)didSaveSettings:(PagingSettingsModel *)settings {
    self.settings = settings;
    [self applySettings];
    [self reloadPagingView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didCancelSettings {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    NSLog(@"WYTestPagingViewController deinit");
}

@end
