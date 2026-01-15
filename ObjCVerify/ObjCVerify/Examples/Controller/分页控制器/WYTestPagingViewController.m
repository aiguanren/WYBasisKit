//
//  WYTestPagingViewController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/15.
//

#import "WYTestPagingViewController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

// MARK: - 设置数据模型
@interface PagingSettingsModel : NSObject

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
@property (nonatomic, strong) UIColor *titleDefaultColor;
@property (nonatomic, strong) UIColor *titleSelectedColor;
@property (nonatomic, strong) UIColor *dividingStripColor;
@property (nonatomic, strong) UIColor *scrollLineColor;

// 图片
@property (nonatomic, strong) UIImage *dividingStripImage;
@property (nonatomic, strong) UIImage *scrollLineImage;

// 尺寸
@property (nonatomic, assign) CGFloat itemWidth;
@property (nonatomic, assign) CGFloat itemHeight;
@property (nonatomic, assign) CGSize itemAppendSize;
@property (nonatomic, assign) CGFloat itemCornerRadius;
@property (nonatomic, assign) CGFloat scrollLineWidth;
@property (nonatomic, assign) CGFloat scrollLineBottomOffset;
@property (nonatomic, assign) CGFloat dividingStripHeight;
@property (nonatomic, assign) CGFloat scrollLineHeight;

// 字体
@property (nonatomic, strong) UIFont *titleDefaultFont;
@property (nonatomic, strong) UIFont *titleSelectedFont;

// 其他
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign) BOOL canScrollController;
@property (nonatomic, assign) BOOL canScrollBar;
@property (nonatomic, assign) BOOL pagingBounce;

@end

@implementation PagingSettingsModel

- (instancetype)init {
    self = [super init];
    if (self) {
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
        _titleDefaultColor = [UIColor wy_hex:@"#7B809E"];
        _titleSelectedColor = [UIColor wy_hex:@"#2D3952"];
        _dividingStripColor = [UIColor wy_hex:@"#F2F2F2"];
        _scrollLineColor = [UIColor wy_hex:@"#2D3952"];
        
        // 图片
        _dividingStripImage = nil;
        _scrollLineImage = nil;
        
        // 尺寸
        _itemWidth = 0;
        _itemHeight = 0;
        _itemAppendSize = CGSizeZero;
        _itemCornerRadius = 0;
        _scrollLineWidth = 25;
        _scrollLineBottomOffset = 5;
        _dividingStripHeight = 2;
        _scrollLineHeight = 2;
        
        // 字体
        _titleDefaultFont = [UIFont systemFontOfSize:15];
        _titleSelectedFont = [UIFont boldSystemFontOfSize:15];
        
        // 其他
        _selectedIndex = 0;
        _canScrollController = YES;
        _canScrollBar = YES;
        _pagingBounce = YES;
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
        
        if ([key isEqualToString:@"pagingContentColor"]) {
            colorView.backgroundColor = self.settings.pagingContentColor;
        } else if ([key isEqualToString:@"pagingBgColor"]) {
            colorView.backgroundColor = self.settings.pagingBgColor;
        } else if ([key isEqualToString:@"barBgColor"]) {
            colorView.backgroundColor = self.settings.barBgColor;
        } else if ([key isEqualToString:@"itemDefaultBgColor"]) {
            colorView.backgroundColor = self.settings.itemDefaultBgColor;
        } else if ([key isEqualToString:@"itemSelectedBgColor"]) {
            colorView.backgroundColor = self.settings.itemSelectedBgColor;
        } else if ([key isEqualToString:@"titleDefaultColor"]) {
            colorView.backgroundColor = self.settings.titleDefaultColor;
        } else if ([key isEqualToString:@"titleSelectedColor"]) {
            colorView.backgroundColor = self.settings.titleSelectedColor;
        } else if ([key isEqualToString:@"dividingStripColor"]) {
            colorView.backgroundColor = self.settings.dividingStripColor;
        } else if ([key isEqualToString:@"scrollLineColor"]) {
            colorView.backgroundColor = self.settings.scrollLineColor;
        }
        
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
    if ([key isEqualToString:@"barHeight"]) {
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
        return self.settings.itemTopOffset ? [NSString stringWithFormat:@"%.0f", self.settings.itemTopOffset] : @"0";
    } else if ([key isEqualToString:@"adjustOffset"]) {
        return self.settings.adjustOffset ? @"是" : @"否";
    } else if ([key isEqualToString:@"dividingOffset"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.dividingOffset];
    } else if ([key isEqualToString:@"buttonDividingOffset"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.buttonDividingOffset];
    } else if ([key isEqualToString:@"pagingContentColor"]) {
        return @"已设置";
    } else if ([key isEqualToString:@"pagingBgColor"]) {
        return self.settings.pagingBgColor != nil ? @"已设置" : @"nil";
    } else if ([key isEqualToString:@"barBgColor"]) {
        return @"已设置";
    } else if ([key isEqualToString:@"itemDefaultBgColor"]) {
        return @"已设置";
    } else if ([key isEqualToString:@"itemSelectedBgColor"]) {
        return @"已设置";
    } else if ([key isEqualToString:@"titleDefaultColor"]) {
        return @"已设置";
    } else if ([key isEqualToString:@"titleSelectedColor"]) {
        return @"已设置";
    } else if ([key isEqualToString:@"dividingStripColor"]) {
        return @"已设置";
    } else if ([key isEqualToString:@"scrollLineColor"]) {
        return @"已设置";
    } else if ([key isEqualToString:@"itemWidth"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.itemWidth];
    } else if ([key isEqualToString:@"itemHeight"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.itemHeight];
    } else if ([key isEqualToString:@"itemAppendSize"]) {
        return [NSString stringWithFormat:@"%.0f, %.0f", self.settings.itemAppendSize.width, self.settings.itemAppendSize.height];
    } else if ([key isEqualToString:@"itemCornerRadius"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.itemCornerRadius];
    } else if ([key isEqualToString:@"scrollLineWidth"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.scrollLineWidth];
    } else if ([key isEqualToString:@"scrollLineBottomOffset"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.scrollLineBottomOffset];
    } else if ([key isEqualToString:@"dividingStripHeight"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.dividingStripHeight];
    } else if ([key isEqualToString:@"scrollLineHeight"]) {
        return [NSString stringWithFormat:@"%.0f", self.settings.scrollLineHeight];
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
    }
    
    return @"";
}

- (void)showDetailSettingForKey:(NSString *)key {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"设置 %@", key]
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    if ([key isEqualToString:@"barHeight"] || [key isEqualToString:@"originlLeftOffset"] || [key isEqualToString:@"originlRightOffset"] ||
        [key isEqualToString:@"dividingOffset"] || [key isEqualToString:@"buttonDividingOffset"] || [key isEqualToString:@"itemWidth"] ||
        [key isEqualToString:@"itemHeight"] || [key isEqualToString:@"itemCornerRadius"] || [key isEqualToString:@"scrollLineWidth"] ||
        [key isEqualToString:@"scrollLineBottomOffset"] || [key isEqualToString:@"dividingStripHeight"] || [key isEqualToString:@"scrollLineHeight"]) {
        
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
            else if ([key isEqualToString:@"scrollLineWidth"]) currentValue = self.settings.scrollLineWidth;
            else if ([key isEqualToString:@"scrollLineBottomOffset"]) currentValue = self.settings.scrollLineBottomOffset;
            else if ([key isEqualToString:@"dividingStripHeight"]) currentValue = self.settings.dividingStripHeight;
            else if ([key isEqualToString:@"scrollLineHeight"]) currentValue = self.settings.scrollLineHeight;
            
            textField.text = [NSString stringWithFormat:@"%.0f", currentValue];
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
                else if ([key isEqualToString:@"scrollLineWidth"]) self.settings.scrollLineWidth = value;
                else if ([key isEqualToString:@"scrollLineBottomOffset"]) self.settings.scrollLineBottomOffset = value;
                else if ([key isEqualToString:@"dividingStripHeight"]) self.settings.dividingStripHeight = value;
                else if ([key isEqualToString:@"scrollLineHeight"]) self.settings.scrollLineHeight = value;
                
                [self.tableView reloadData];
            }
        }];
        [alert addAction:confirmAction];
        
    } else if ([key isEqualToString:@"titleDefaultFont"] || [key isEqualToString:@"titleSelectedFont"]) {
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.keyboardType = UIKeyboardTypeNumberPad;
            textField.placeholder = @"请输入字体大小";
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
        
    } else if ([key isEqualToString:@"selectedIndex"]) {
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.keyboardType = UIKeyboardTypeNumberPad;
            textField.placeholder = @"请输入选中索引 (0-4)";
            textField.text = [NSString stringWithFormat:@"%ld", (long)self.settings.selectedIndex];
        }];
        
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
            UITextField *textField = alert.textFields.firstObject;
            if (textField.text.length > 0) {
                NSInteger index = [textField.text integerValue];
                self.settings.selectedIndex = MAX(0, MIN(index, 4));
                [self.tableView reloadData];
            }
        }];
        [alert addAction:confirmAction];
        
    } else if ([key isEqualToString:@"itemTopOffset"]) {
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.keyboardType = UIKeyboardTypeDecimalPad;
            textField.placeholder = @"请输入数值或留空";
            if (self.settings.itemTopOffset) {
                textField.text = [NSString stringWithFormat:@"%.0f", self.settings.itemTopOffset];
            }
        }];
        
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
            UITextField *textField = alert.textFields.firstObject;
            if (textField.text.length > 0) {
                self.settings.itemTopOffset = [textField.text floatValue];
            } else {
                self.settings.itemTopOffset = 0;
            }
            [self.tableView reloadData];
        }];
        [alert addAction:confirmAction];
        
    } else if ([key isEqualToString:@"adjustOffset"] || [key isEqualToString:@"canScrollController"] ||
               [key isEqualToString:@"canScrollBar"] || [key isEqualToString:@"pagingBounce"]) {
        BOOL currentValue = NO;
        if ([key isEqualToString:@"adjustOffset"]) currentValue = self.settings.adjustOffset;
        else if ([key isEqualToString:@"canScrollController"]) currentValue = self.settings.canScrollController;
        else if ([key isEqualToString:@"canScrollBar"]) currentValue = self.settings.canScrollBar;
        else if ([key isEqualToString:@"pagingBounce"]) currentValue = self.settings.pagingBounce;
        
        alert.message = currentValue ? @"当前状态: 开启" : @"当前状态: 关闭";
        
        UIAlertAction *toggleAction = [UIAlertAction actionWithTitle:@"切换"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action) {
            if ([key isEqualToString:@"adjustOffset"]) {
                self.settings.adjustOffset = !currentValue;
            } else if ([key isEqualToString:@"canScrollController"]) {
                self.settings.canScrollController = !currentValue;
            } else if ([key isEqualToString:@"canScrollBar"]) {
                self.settings.canScrollBar = !currentValue;
            } else if ([key isEqualToString:@"pagingBounce"]) {
                self.settings.pagingBounce = !currentValue;
            }
            [self.tableView reloadData];
        }];
        [alert addAction:toggleAction];
        
    } else if ([key isEqualToString:@"buttonPosition"]) {
        NSArray<NSNumber *> *positions = @[@(WYButtonPositionImageLeftTitleRight), @(WYButtonPositionImageRightTitleLeft),
                                           @(WYButtonPositionImageTopTitleBottom), @(WYButtonPositionImageBottomTitleTop)];
        NSArray<NSString *> *positionNames = @[@"图片左文字右", @"图片右文字左", @"图片上文字下", @"图片下文字上"];
        
        for (NSInteger i = 0; i < positionNames.count; i++) {
            UIAlertAction *action = [UIAlertAction actionWithTitle:positionNames[i]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
                self.settings.buttonPosition = [positions[i] integerValue];
                [self.tableView reloadData];
            }];
            [alert addAction:action];
        }
        
    } else if ([key isEqualToString:@"itemAppendSize"]) {
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"宽度,高度 (如: 10,20)";
            textField.text = [NSString stringWithFormat:@"%.0f,%.0f", self.settings.itemAppendSize.width, self.settings.itemAppendSize.height];
        }];
        
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
            UITextField *textField = alert.textFields.firstObject;
            if (textField.text.length > 0) {
                NSArray<NSString *> *components = [textField.text componentsSeparatedByString:@","];
                if (components.count == 2) {
                    CGFloat width = [components[0] doubleValue];
                    CGFloat height = [components[1] doubleValue];
                    self.settings.itemAppendSize = CGSizeMake(width, height);
                    [self.tableView reloadData];
                }
            }
        }];
        [alert addAction:confirmAction];
        
    } else if ([key containsString:@"Color"]) {
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
        
        // 添加自定义颜色选项
        UIAlertAction *customAction = [UIAlertAction actionWithTitle:@"自定义颜色"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action) {
            [self showCustomColorPickerForKey:key];
        }];
        [colorAlert addAction:customAction];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [colorAlert addAction:cancelAction];
        
        // 适配 iPad
        if (UIDevice.wy_iPadSeries) {
            colorAlert.popoverPresentationController.sourceView = self.tableView;
            
            // 找到包含当前key的section和row
            NSIndexPath *foundIndexPath = nil;
            for (NSInteger section = 0; section < self.items.count; section++) {
                for (NSInteger row = 0; row < self.items[section].count; row++) {
                    NSDictionary *item = self.items[section][row];
                    if ([item[@"key"] isEqualToString:key]) {
                        foundIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
                        break;
                    }
                }
                if (foundIndexPath) break;
            }
            
            if (foundIndexPath) {
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:foundIndexPath];
                colorAlert.popoverPresentationController.sourceRect = cell.bounds;
                colorAlert.popoverPresentationController.sourceView = cell;
            }
        }
        
        [self presentViewController:colorAlert animated:YES completion:nil];
        return;
        
    } else {
        alert.message = @"该设置项暂不支持编辑";
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:okAction];
    }
    
    if (![key containsString:@"Color"]) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
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

- (void)saveSettings {
    [self.delegate didSaveSettings:self.settings];
}

- (void)cancelSettings {
    [self.delegate didCancelSettings];
}

#pragma mark - Lazy Loading

- (NSArray<NSString *> *)sections {
    if (!_sections) {
        _sections = @[@"基本属性", @"颜色设置", @"尺寸设置", @"字体设置", @"其他设置"];
    }
    return _sections;
}

- (NSArray<NSArray<NSDictionary *> *> *)items {
    if (!_items) {
        _items = @[
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
                @{@"title": @"标题默认颜色", @"key": @"titleDefaultColor"},
                @{@"title": @"标题选中颜色", @"key": @"titleSelectedColor"},
                @{@"title": @"分隔带颜色", @"key": @"dividingStripColor"},
                @{@"title": @"滑动线颜色", @"key": @"scrollLineColor"}
            ],
            // 尺寸设置
            @[
                @{@"title": @"Item宽度", @"key": @"itemWidth"},
                @{@"title": @"Item高度", @"key": @"itemHeight"},
                @{@"title": @"Item追加尺寸", @"key": @"itemAppendSize"},
                @{@"title": @"Item圆角", @"key": @"itemCornerRadius"},
                @{@"title": @"滑动线宽度", @"key": @"scrollLineWidth"},
                @{@"title": @"滑动线底部偏移", @"key": @"scrollLineBottomOffset"},
                @{@"title": @"分隔带高度", @"key": @"dividingStripHeight"},
                @{@"title": @"滑动线高度", @"key": @"scrollLineHeight"}
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
                @{@"title": @"弹跳效果", @"key": @"pagingBounce"}
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

/// 分页视图
@property (nonatomic, strong) WYPagingView *pagingView;

/// 设置按钮
@property (nonatomic, strong) UIBarButtonItem *settingsButton;

/// 设置数据模型
@property (nonatomic, strong) PagingSettingsModel *settings;

/// 测试用的子控制器数组
@property (nonatomic, strong) NSArray<UIViewController *> *testControllers;

/// 测试用的标题数组
@property (nonatomic, strong) NSArray<NSString *> *testTitles;

/// 测试用的图片数组（使用系统图标代替）
@property (nonatomic, strong) NSArray<UIImage *> *testDefaultImages;
@property (nonatomic, strong) NSArray<UIImage *> *testSelectedImages;

@end

@implementation WYTestPagingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupNavigationBar];
    [self setupInitialPagingView];
}

/// 设置导航栏
- (void)setupNavigationBar {
    self.title = @"WYPagingView 测试";
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 添加设置按钮
    self.settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"设置"
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(showSettings)];
    self.navigationItem.rightBarButtonItem = self.settingsButton;
    
    self.wy_navBarBackgroundColor = [UIColor orangeColor];
}

/// 初始化默认的分页视图
- (void)setupInitialPagingView {
    // 移除旧的视图
    [self.pagingView removeFromSuperview];
    self.pagingView = nil;
    
    // 创建新的分页视图
    WYPagingView *newPagingView = [[WYPagingView alloc] init];
    [self.view addSubview:newPagingView];
    
    // 设置约束
    [newPagingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.leading.equalTo(self.view);
        make.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    
    // 应用当前设置
    [self applySettingsTo:newPagingView];
    
    // 布局分页视图
    [newPagingView layoutWithControllers:self.testControllers
                                  titles:self.testTitles
                           defaultImages:self.testDefaultImages
                          selectedImages:self.testSelectedImages
                     superViewController:self];
    
    self.pagingView = newPagingView;
}

/// 显示设置界面
- (void)showSettings {
    PagingSettingsViewController *settingsVC = [[PagingSettingsViewController alloc] initWithSettings:self.settings];
    settingsVC.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    [self presentViewController:navController animated:YES completion:nil];
}

/// 将设置应用到分页视图
- (void)applySettingsTo:(WYPagingView *)pagingView {
    // 基本属性设置
    pagingView.bar_Height = self.settings.barHeight;
    pagingView.buttonPosition = self.settings.buttonPosition;
    pagingView.bar_originlLeftOffset = self.settings.originlLeftOffset;
    pagingView.bar_originlRightOffset = self.settings.originlRightOffset;
    pagingView.bar_itemTopOffset = self.settings.itemTopOffset;
    pagingView.bar_adjustOffset = self.settings.adjustOffset;
    pagingView.bar_dividingOffset = self.settings.dividingOffset;
    pagingView.barButton_dividingOffset = self.settings.buttonDividingOffset;
    
    // 颜色设置
    pagingView.bar_pagingContro_content_color = self.settings.pagingContentColor;
    pagingView.bar_pagingContro_bg_color = self.settings.pagingBgColor;
    pagingView.bar_bg_defaultColor = self.settings.barBgColor;
    pagingView.bar_item_bg_defaultColor = self.settings.itemDefaultBgColor;
    pagingView.bar_item_bg_selectedColor = self.settings.itemSelectedBgColor;
    pagingView.bar_title_defaultColor = self.settings.titleDefaultColor;
    pagingView.bar_title_selectedColor = self.settings.titleSelectedColor;
    pagingView.bar_dividingStripColor = self.settings.dividingStripColor;
    pagingView.bar_scrollLineColor = self.settings.scrollLineColor;
    
    // 图片设置
    pagingView.bar_dividingStripImage = self.settings.dividingStripImage;
    pagingView.bar_scrollLineImage = self.settings.scrollLineImage;
    
    // 尺寸设置
    pagingView.bar_item_width = self.settings.itemWidth;
    pagingView.bar_item_height = self.settings.itemHeight;
    pagingView.bar_item_appendSize = self.settings.itemAppendSize;
    pagingView.bar_item_cornerRadius = self.settings.itemCornerRadius;
    pagingView.bar_scrollLineWidth = self.settings.scrollLineWidth;
    pagingView.bar_scrollLineBottomOffset = self.settings.scrollLineBottomOffset;
    pagingView.bar_dividingStripHeight = self.settings.dividingStripHeight;
    pagingView.bar_scrollLineHeight = self.settings.scrollLineHeight;
    
    // 字体设置
    pagingView.bar_title_defaultFont = self.settings.titleDefaultFont;
    pagingView.bar_title_selectedFont = self.settings.titleSelectedFont;
    
    // 其他设置
    pagingView.bar_selectedIndex = self.settings.selectedIndex;
    pagingView.canScrollController = self.settings.canScrollController;
    pagingView.canScrollBar = self.settings.canScrollBar;
    pagingView.bar_pagingContro_bounce = self.settings.pagingBounce;
    
    // 设置代理和回调
    pagingView.delegate = self;
    [pagingView itemDidScroll:^(NSInteger index) {
        NSLog(@"分页滚动到第 %ld 页 - 通过闭包回调", (long)index);
    }];
}

#pragma mark - WYPagingViewDelegate

- (void)itemDidScroll:(NSInteger)pagingIndex {
    NSLog(@"分页滚动到第 %ld 页 - 通过代理回调", (long)pagingIndex);
}

#pragma mark - PagingSettingsDelegate

- (void)didSaveSettings:(PagingSettingsModel *)settings {
    self.settings = settings;
    [self setupInitialPagingView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didCancelSettings {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Lazy Loading

- (NSArray<UIViewController *> *)testControllers {
    if (!_testControllers) {
        NSArray<UIColor *> *colors = @[[UIColor redColor], [UIColor greenColor], [UIColor blueColor], [UIColor yellowColor], [UIColor purpleColor]];
        NSMutableArray<UIViewController *> *controllers = [NSMutableArray array];
        
        for (UIColor *color in colors) {
            UIViewController *vc = [[UIViewController alloc] init];
            vc.view.backgroundColor = color;
            vc.view.layer.borderWidth = 2;
            vc.view.layer.borderColor = [UIColor blackColor].CGColor;
            [controllers addObject:vc];
        }
        
        _testControllers = [controllers copy];
    }
    return _testControllers;
}

- (NSArray<NSString *> *)testTitles {
    if (!_testTitles) {
        _testTitles = @[@"首页", @"消息", @"发现", @"我的", @"设置"];
    }
    return _testTitles;
}

- (NSArray<UIImage *> *)testDefaultImages {
    if (!_testDefaultImages) {
        _testDefaultImages = @[
            [UIImage systemImageNamed:@"house"],
            [UIImage systemImageNamed:@"message"],
            [UIImage systemImageNamed:@"magnifyingglass"],
            [UIImage systemImageNamed:@"person"],
            [UIImage systemImageNamed:@"gearshape"]
        ];
    }
    return _testDefaultImages;
}

- (NSArray<UIImage *> *)testSelectedImages {
    if (!_testSelectedImages) {
        _testSelectedImages = @[
            [UIImage systemImageNamed:@"house.fill"],
            [UIImage systemImageNamed:@"message.fill"],
            [UIImage systemImageNamed:@"magnifyingglass.circle.fill"],
            [UIImage systemImageNamed:@"person.fill"],
            [UIImage systemImageNamed:@"gearshape.fill"]
        ];
    }
    return _testSelectedImages;
}

- (PagingSettingsModel *)settings {
    if (!_settings) {
        _settings = [[PagingSettingsModel alloc] init];
    }
    return _settings;
}

- (void)dealloc {
    NSLog(@"WYTestPagingViewController deinit");
}

@end
