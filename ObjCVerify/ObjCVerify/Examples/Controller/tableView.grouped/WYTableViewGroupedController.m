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
@interface WYGroupedHeaderView : UITableViewHeaderFooterView <WYContentScrollViewDelegate>

@property (nonatomic, strong) WYContentScrollView *contentScrollView;

/// 水平方向的两页View(当前+预备，banner由图片构成)
@property (nonatomic, strong) NSArray<UIImageView *> *horizontalViews;

/// 垂直方向的两页View(当前+预备，banner由图片构成)
@property (nonatomic, strong) NSArray<UIImageView *> *verticalViews;

/// 水平方向各下标对应的图片地址
@property (nonatomic, strong) NSArray<NSString *> *horizontalImages;

/// 垂直方向各下标对应的图片
@property (nonatomic, strong) NSArray<UIImage *> *verticalImages;

- (void)reloadWithImages:(NSArray<NSString *> *)images;

@end

@implementation WYGroupedHeaderView

/// 图片内存缓存(复用与环绕重载时避免重复下载)
static NSCache<NSString *, UIImage *> *imageCache;

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [UIColor whiteColor];

        if (!imageCache) {
            imageCache = [[NSCache alloc] init];
        }

        NSMutableArray<UIImageView *> *views = [NSMutableArray array];
        NSMutableArray<UIImageView *> *verticalViews = [NSMutableArray array];
        for (NSInteger i = 0; i <= 1; i++) {
            UIImageView *imageView = [[UIImageView alloc] init];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            imageView.clipsToBounds = YES;
            imageView.tag = 100 + i;
            [views addObject:imageView];

            UIImageView *verticalImageView = [[UIImageView alloc] init];
            verticalImageView.contentMode = UIViewContentModeScaleAspectFit;
            verticalImageView.clipsToBounds = YES;
            verticalImageView.tag = 200 + i;
            [verticalViews addObject:verticalImageView];
        }
        _horizontalViews = views;
        _verticalViews = verticalViews;

        _contentScrollView = [[WYContentScrollView alloc] init];
        _contentScrollView.backgroundColor = [UIColor wy_random];
        _contentScrollView.contentDelegate = self;
        _contentScrollView.contentSlidingDirection = WYContentSlidingDirectionOmnidirectional;
        [self.contentView addSubview:_contentScrollView];
        [_contentScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.equalTo([NSValue valueWithCGSize:CGSizeMake(300, 600)]);
            make.edges.equalTo(self.contentView);
        }];
    }
    return self;
}

- (void)reloadWithImages:(NSArray<NSString *> *)images {
    self.horizontalImages = images;
    // 预取全部图片进缓存：首滑命中缓存无占位阶段(冷缓存时占位图→真图跳变表现为闪一下)
    for (NSString *urlString in images) {
        [self warmupCacheWithUrlString:urlString];
    }
    self.contentScrollView.numberOfHorizontalContent = images.count;
    self.contentScrollView.numberOfVerticalContent = images.count;

    // 判断刷新当前展示的信息，防止因为复用导致展示信息被切换
    if ([self.contentScrollView reload] == false) {
        [self.contentScrollView omnidirectionalDisplayWithCurrentHorizontalView:self.horizontalViews.firstObject reserveHorizontalView:self.horizontalViews.lastObject currentVerticalView:self.verticalViews.firstObject reserveVerticalView:self.verticalViews.lastObject];
    }
}

/// 只下载进缓存不碰View(预取用)
- (void)warmupCacheWithUrlString:(NSString *)urlString {
    if (!urlString.length || [imageCache objectForKey:urlString]) { return; }
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:urlString] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data) { return; }
        UIImage *image = [UIImage imageWithData:data];
        if (image) {
            [imageCache setObject:image forKey:urlString];
        }
    }] resume];
}


/// 按地址加载图片(缓存命中直接设置，否则下载后回主线程设置)
- (void)setImage:(UIImageView *)imageView urlString:(NSString *)urlString {
    if (!urlString.length) { return; }
    UIImage *cached = [imageCache objectForKey:urlString];
    if (cached) {
        imageView.image = cached;
        return;
    }
    // 防首次进入当前页空白，dataTask创建后必须resume才会发起请求(漏掉时只有warmup在后台填缓存、从不回调装图，表现为第一次进空白、退出重进命中缓存才显示)
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:urlString] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data) { return; }
        UIImage *image = [UIImage imageWithData:data];
        if (!image) { return; }
        [imageCache setObject:image forKey:urlString];
        dispatch_async(dispatch_get_main_queue(), ^{
            imageView.image = image;
        });
    }] resume];
}

- (void)wy_contentScrollViewWillSwitch:(WYContentScrollView *)contentScrollView direction:(WYSlidingDirection)direction currentHorizontalView:(UIView *)currentHorizontalView reserveHorizontalView:(UIView *)reserveHorizontalView currentVerticalView:(UIView *)currentVerticalView reserveVerticalView:(UIView *)reserveVerticalView {
    // 预备页按reserveIndex预载图片(取模防环绕越界)
    if ((direction == WYSlidingDirectionLeft || direction == WYSlidingDirectionRight) && [reserveHorizontalView isKindOfClass:[UIImageView class]] && self.horizontalImages.count > 0) {
        [self setImage:(UIImageView *)reserveHorizontalView urlString:self.horizontalImages[contentScrollView.reserveHorizontalIndex % self.horizontalImages.count]];
    }

    if ((direction == WYSlidingDirectionUp || direction == WYSlidingDirectionDown) && [reserveVerticalView isKindOfClass:[UIImageView class]] && self.verticalImages.count > 0) {
        ((UIImageView *)reserveVerticalView).image = self.verticalImages[contentScrollView.reserveVerticalIndex % self.verticalImages.count];
    }
}

- (void)wy_contentScrollViewDidSwitch:(WYContentScrollView *)contentScrollView direction:(WYSlidingDirection)direction currentHorizontalView:(UIView *)currentHorizontalView reserveHorizontalView:(UIView *)reserveHorizontalView currentVerticalView:(UIView *)currentVerticalView reserveVerticalView:(UIView *)reserveVerticalView {
    // 当前页按currentIndex装图(补发didSwitch时reserveIndex还是残留值，用它会串台；取模防环绕越界)
    if ((direction == WYSlidingDirectionLeft || direction == WYSlidingDirectionRight) && [currentHorizontalView isKindOfClass:[UIImageView class]] && self.horizontalImages.count > 0) {
        [self setImage:(UIImageView *)currentHorizontalView urlString:self.horizontalImages[contentScrollView.currentHorizontalIndex % self.horizontalImages.count]];
    }

    if ((direction == WYSlidingDirectionUp || direction == WYSlidingDirectionDown) && [currentVerticalView isKindOfClass:[UIImageView class]] && self.verticalImages.count > 0) {
        ((UIImageView *)currentVerticalView).image = self.verticalImages[contentScrollView.currentVerticalIndex % self.verticalImages.count];
    }
}

- (NSArray<UIImage *> *)verticalImages {
    if (!_verticalImages) {
        _verticalImages = @[[UIImage imageNamed:@"banner_0"],
                            [UIImage imageNamed:@"banner_1"],
                            [UIImage imageNamed:@"banner_2"],
                            [UIImage imageNamed:@"banner_3"],
                            [UIImage imageNamed:@"banner_4"],
                            [UIImage imageNamed:@"banner_5"],
                            [UIImage imageNamed:@"banner_6"],
                            [UIImage imageNamed:@"banner_7"],
                            [UIImage imageNamed:@"banner_8"],
                            [UIImage imageNamed:@"banner_9"]];
    }
    return _verticalImages;
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
    wy_print(@"deinit");
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
