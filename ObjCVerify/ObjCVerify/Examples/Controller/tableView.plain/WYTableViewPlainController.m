//
//  WYTableViewPlainController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/9.
//

#import "WYTableViewPlainController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

// MARK: - WYTestTableViewHeaderView
@interface WYTestTableViewHeaderView : UITableViewHeaderFooterView

@property (nonatomic, strong) UILabel *titleView;

@end

@implementation WYTestTableViewHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [UIColor redColor];
        
        self.titleView = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, [UIDevice wy_screenWidth] - 20, 30)];
        self.titleView.textColor = [UIColor whiteColor];
        self.titleView.font = [UIFont systemFontOfSize:[UIDevice wy_screenWidth:14]];
        [self.contentView addSubview:self.titleView];
    }
    return self;
}

/*
// Only override draw() if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

// MARK: - WYTestTableViewFooterView
@interface WYTestTableViewFooterView : UITableViewHeaderFooterView

@property (nonatomic, strong) UILabel *titleView;

@end

@implementation WYTestTableViewFooterView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [UIColor blueColor];
        
        self.titleView = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, [UIDevice wy_screenWidth] - 20, 30)];
        self.titleView.textColor = [UIColor whiteColor];
        self.titleView.font = [UIFont systemFontOfSize:[UIDevice wy_screenWidth:14]];
        [self.contentView addSubview:self.titleView];
    }
    return self;
}

/*
// Only override draw() if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

@interface WYTableViewPlainController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation WYTableViewPlainController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tableView.backgroundColor = [UIColor orangeColor];
}

- (UITableView *)tableView {
    if (!_tableView) {
        
        _tableView = [UITableView wy_sharedWithFrame:CGRectZero style:UITableViewStylePlain headerHeight:UITableViewAutomaticDimension footerHeight:UITableViewAutomaticDimension rowHeight:UITableViewAutomaticDimension separatorStyle:UITableViewCellSeparatorStyleSingleLine delegate:self dataSource:self backgroundColor:[UIColor whiteColor] superView:self.view];
        
        [_tableView wy_register:[UITableViewCell class] style:WYTableViewRegisterStyleCell];
        [_tableView wy_registers:@[WYTestTableViewHeaderView.class, WYTestTableViewFooterView.class] style:WYTableViewRegisterStyleHeaderFooterView];
        [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset([UIDevice wy_navViewHeight]);
            make.left.right.bottom.equalTo(self.view);
        }];
    }
    return _tableView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 10;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    
    cell.textLabel.text = [NSString stringWithFormat:@"section = %ld  row = %ld", (long)indexPath.section, (long)indexPath.row];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    WYTestTableViewHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"WYTestTableViewHeaderView"];
    headerView.titleView.text = [NSString stringWithFormat:@"header section = %ld", (long)section];
    
    return headerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    
    WYTestTableViewFooterView *footerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"WYTestTableViewFooterView"];
    footerView.titleView.text = [NSString stringWithFormat:@"footer section = %ld", (long)section];
    
    return footerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
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
