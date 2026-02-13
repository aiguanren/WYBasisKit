//
//  WYMultilevelTableViewController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/9.
//

#import "WYMultilevelTableViewController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

/**
 * 无限折叠的原理其实很简单
 * 1.不会新增section，只会新增row
 * 2.根据不同类型判断显示不同cell或利用视觉差拉开子级row与父级row之间的布局原点X，如一级页面有个label的原点X为10，二级页面就可以设置label的原点X为20，三级页面就可以设置label的原点X为30，以此类推，达到新增section一样的效果
 */

// MARK: - WYMultilevelTable 类
@interface WYMultilevelTable : NSObject

/// 当前所属父层级
@property (nonatomic, assign, readonly) NSInteger superLevel;
/// 当前所属层级
@property (nonatomic, assign, readonly) NSInteger level;
/// 当前所属层级下的子层级数量
@property (nonatomic, assign) NSInteger subLevel;
/// 当前层级是展开还是折叠状态
@property (nonatomic, assign) BOOL expand;
/// 当前层级名
@property (nonatomic, copy) NSString *levelName;

/// 推荐初始化方法
- (instancetype)initWithSuperLevel:(NSInteger)superLevel
                             level:(NSInteger)level
                          subLevel:(NSInteger)subLevel;

@end

@implementation WYMultilevelTable

- (instancetype)initWithSuperLevel:(NSInteger)superLevel
                             level:(NSInteger)level
                          subLevel:(NSInteger)subLevel {
    self = [super init];
    if (self) {
        _superLevel = superLevel;
        _level = level;
        _subLevel = subLevel;
        _expand = NO;
    }
    return self;
}

@end

@interface WYMultilevelTableViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray<WYMultilevelTable *> *dataSource;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation WYMultilevelTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"无限层折叠TableView";
    self.tableView.backgroundColor = [UIColor whiteColor];
}

- (UITableView *)tableView {
    if (!_tableView) {
        
        _tableView = [UITableView wy_sharedWithStyle:UITableViewStylePlain separatorStyle: UITableViewCellSeparatorStyleSingleLine delegate:self dataSource:self backgroundColor:[UIColor whiteColor] superView:self.view];
        
        [_tableView wy_register:[UITableViewCell class] style:WYTableViewRegisterStyleCell];
        
        [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset([UIDevice wy_navViewHeight]);
            make.left.right.bottom.equalTo(self.view);
        }];
        self.dataSource = [NSMutableArray array];
        [self.dataSource addObject:[[WYMultilevelTable alloc] initWithSuperLevel:0 level:0 subLevel:0]];
    }
    return _tableView;
}

- (void)expandWithModel:(WYMultilevelTable *)model indexPath:(NSIndexPath *)indexPath {
    
    NSMutableArray<NSIndexPath *> *reloadRows = [NSMutableArray array];
    NSInteger insertLocation = indexPath.row + 1;
    NSInteger subLevel = [WYInt wy_randomWithMinimum:1 maximum:5];
    model.subLevel = subLevel;
    for (NSInteger index = 0; index < subLevel; index++) {
        
        WYMultilevelTable *insertModel = [[WYMultilevelTable alloc] initWithSuperLevel:model.level level:model.level + 1 subLevel:0];
        [self.dataSource insertObject:insertModel atIndex:insertLocation + index];
        [reloadRows addObject:[NSIndexPath indexPathForRow:insertLocation + index inSection:0]];
    }
    
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:reloadRows withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    
    [self.tableView reloadRowsAtIndexPaths:reloadRows withRowAnimation:UITableViewRowAnimationNone];
}

- (void)foldWithModel:(WYMultilevelTable *)model indexPath:(NSIndexPath *)indexPath {
    
    NSMutableArray<NSIndexPath *> *reloadRows = [NSMutableArray array];
    NSInteger length = 0;
    NSInteger location = indexPath.row + 1;
    for (NSInteger index = 0; index < self.dataSource.count - location; index++) {
        WYMultilevelTable *multilevelModel = self.dataSource[location + index];
        if (multilevelModel.level > model.level) {
            [reloadRows addObject:[NSIndexPath indexPathForRow:location + index inSection:indexPath.section]];
            length += 1;
        } else {
            break;
        }
    }
    NSRange range = NSMakeRange(location, length);
    [self.dataSource removeObjectsInRange:range];
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:reloadRows withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
}

- (NSString *)sharedLevelNameWithModel:(WYMultilevelTable *)model {
    
    NSMutableString *offset = [NSMutableString string];
    for (NSInteger i = 0; i < model.level; i++) {
        [offset appendString:@"    "];
    }
    return [NSString stringWithFormat:@"%@第%ld级", offset, (long)model.level];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    
    cell.textLabel.textColor = [UIColor wy_dynamicWithLight:[UIColor blackColor] dark:[UIColor whiteColor]];
    cell.textLabel.font = [UIFont systemFontOfSize:[UIFont wy_fontSize:15 pixels:WYBasisKitConfig.defaultScreenPixels]];
    cell.textLabel.text = [self sharedLevelNameWithModel:self.dataSource[indexPath.row]];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    WYMultilevelTable *model = self.dataSource[indexPath.row];
    model.expand = !model.expand;
    if (model.expand) {
        [self expandWithModel:model indexPath:indexPath];
    } else {
        [self foldWithModel:model indexPath:indexPath];
    }
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
