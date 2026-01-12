//
//  WYTableViewGroupedController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/12.
//

#import "WYTableViewGroupedController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

// MARK: - WYGroupedHeaderView
@interface WYGroupedHeaderView : UITableViewHeaderFooterView

@property (nonatomic, strong) WYBannerView *bannerView;

- (void)reloadWithImages:(NSArray<NSString *> *)images;

@end

@implementation WYGroupedHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [UIColor whiteColor];
        
        self.bannerView = [[WYBannerView alloc] init];
        self.bannerView.backgroundColor = [UIColor wy_random];
        self.bannerView.automaticCarousel = NO;
        self.bannerView.imageContentMode = UIViewContentModeScaleAspectFit;
        WYLog(@"字节描述(KB或MB等)：%@，%ld字节", self.bannerView.cacheSizeString, (long)self.bannerView.cacheSize);
        [self.contentView addSubview:self.bannerView];
        [self.bannerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.equalTo([NSValue valueWithCGSize:CGSizeMake(300, 600)]);
            make.edges.equalTo(self.contentView);
        }];
    }
    return self;
}

- (void)reloadWithImages:(NSArray<NSString *> *)images {
    
    WYLog(@"第一张图片信息：%@", [self.bannerView cacheImageFromUrlString:[images firstObject]]);
    [self.bannerView reloadImages:images];
}

@end

@interface WYTableViewGroupedController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation WYTableViewGroupedController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.title = @"测试tableview Grouped模式";
    self.tableView.backgroundColor = [UIColor wy_dynamicWithLight:[UIColor whiteColor] dark:[UIColor blackColor]];
}

- (UITableView *)tableView {
    if (!_tableView) {
        
        _tableView = [UITableView wy_sharedWithStyle:UITableViewStyleGrouped separatorStyle: UITableViewCellSeparatorStyleSingleLine delegate:self dataSource:self backgroundColor:[UIColor whiteColor] superView:self.view];
        
        [_tableView wy_register:[UITableViewCell class] style:WYTableViewRegisterStyleCell];
        [_tableView wy_register:[WYGroupedHeaderView class] style:WYTableViewRegisterStyleHeaderFooterView];
        
        [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset([UIDevice wy_navViewHeight]);
            make.left.right.bottom.equalTo(self.view);
        }];
    }
    return _tableView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"%ld", (long)indexPath.row];
    cell.textLabel.textColor = [UIColor wy_dynamicWithLight:[UIColor blackColor] dark:[UIColor whiteColor]];
    cell.textLabel.font = [UIFont systemFontOfSize:[UIFont wy_fontSize:15 pixels:WYBasisKitConfig.defaultScreenPixels]];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    WYGroupedHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"WYGroupedHeaderView"];
    [headerView reloadWithImages:@[@"https://pic4.zhimg.com/v2-f4fa00c730322fb24143e4a33dbec223_1440w.jpg",
                                   @"https://pic4.zhimg.com/v2-d2d0eda42a507e4e5215352a5454b117_1440w.jpg",
                                   @"https://picx.zhimg.com/v2-4d913fbfef97730e8a6f65fc69f87cd1_1440w.jpg",
                                   @"https://pic2.zhimg.com/v2-007cfca521fce9b8c3db588c484d87b1_1440w.jpg",
                                   @"https://pic3.zhimg.com/v2-08d43a5cdddcbf948e9240d08bbc3068_1440w.jpg",
                                   @"https://pic4.zhimg.com/v2-b40b07cdbe0229e4011df2545f9336e7_1440w.jpg",
                                   @"https://pic4.zhimg.com/v2-25ae3f2b5912e43b988d623f4b32afff_1440w.jpg",
                                   @"https://pic4.zhimg.com/v2-f012f54144d0364c33a9ccdc42e789b7_1440w.jpg",
                                   @"https://picx.zhimg.com/v2-399017a28614691ebe64df664701fb2f_1440w.jpg"]];
    
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)dealloc {
    WYLog(@"deinit");
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
