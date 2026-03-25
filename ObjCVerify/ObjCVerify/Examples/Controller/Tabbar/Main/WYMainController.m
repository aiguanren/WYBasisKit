//
//  WYMainController.m
//  ObjCVerify
//
//  Created by guanren on 2025/10/1.
//

#import "WYMainController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>
#import "AppEventDelegate.h"
#import "WYLeftControllerHeaderView.h"

@interface ListItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *controller;

- (instancetype)initWithTitle:(NSString *)title
                    controller:(NSString *)controller;

+ (NSArray<ListItem *> *)cellItems;

@end

@implementation ListItem

- (instancetype)initWithTitle:(NSString *)title
                    controller:(NSString *)controller {
    self = [super init];
    if (self) {
        _title = [title copy];
        _controller = [controller copy];
    }
    return self;
}

+ (NSArray<ListItem *> *)cellItems {
    static NSArray<ListItem *> *items = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        items = @[
            [[ListItem alloc] initWithTitle:@"暗夜、白昼模式"
                                 controller:@"WYTestDarkNightModeController"],
            
            [[ListItem alloc] initWithTitle:@"约束view添加动画"
                                 controller:@"WYTestAnimationController"],
            
            [[ListItem alloc] initWithTitle:@"边框、圆角、阴影、渐变"
                                 controller:@"WYTestVisualController"],
            
            [[ListItem alloc] initWithTitle:@"ButtonEdgeInsets"
                                 controller:@"WYTestButtonEdgeInsetsController"],
            
            [[ListItem alloc] initWithTitle:@"Banner轮播"
                                 controller:@"WYTestBannerController"],
            
            [[ListItem alloc] initWithTitle:@"富文本"
                                 controller:@"WYTestRichTextController"],
            
            [[ListItem alloc] initWithTitle:@"无限层折叠TableView"
                                 controller:@"WYMultilevelTableViewController"],
            
            [[ListItem alloc] initWithTitle:@"tableView.plain"
                                 controller:@"WYTableViewPlainController"],
            
            [[ListItem alloc] initWithTitle:@"tableView.grouped"
                                 controller:@"WYTableViewGroupedController"],
            
            [[ListItem alloc] initWithTitle:@"下载与缓存"
                                 controller:@"WYTestDownloadController"],
            
            [[ListItem alloc] initWithTitle:@"网络请求"
                                 controller:@"WYTestRequestController"],
            
            [[ListItem alloc] initWithTitle:@"屏幕旋转"
                                 controller:@"WYTestInterfaceOrientationController"],
            
            [[ListItem alloc] initWithTitle:@"二维码"
                                 controller:@"WYQRCodeController"],
            
            [[ListItem alloc] initWithTitle:@"Gif加载"
                                 controller:@"WYParseGifController"],
            
            [[ListItem alloc] initWithTitle:@"瀑布流"
                                 controller:@"WYFlowLayoutAlignmentController"],
            
            [[ListItem alloc] initWithTitle:@"直播、点播播放器"
                                 controller:@"WYTestLiveStreamingController"],
            
            [[ListItem alloc] initWithTitle:@"语音识别"
                                 controller:@"WYSpeechRecognitionController"],
            
            [[ListItem alloc] initWithTitle:@"泛型"
                                 controller:@"WYGenericTypeController"],
            
            [[ListItem alloc] initWithTitle:@"离线方法调用"
                                 controller:@"WYOffLineMethodController"],
            
            [[ListItem alloc] initWithTitle:@"WKWebView"
                                 controller:@"WYWebViewController"],
            
            [[ListItem alloc] initWithTitle:@"归档/解归档"
                                 controller:@"WYArchivedController"],
            
            [[ListItem alloc] initWithTitle:@"日志输出与保存"
                                 controller:@"WYLogController"],
            
            [[ListItem alloc] initWithTitle:@"音频录制与播放"
                                 controller:@"WYTestAudioController"],
            
            [[ListItem alloc] initWithTitle:@"设备振动"
                                 controller:@"WYTestVibrateController"],
            
            [[ListItem alloc] initWithTitle:@"文本轮播"
                                 controller:@"WYTestScrollTextController"],
            
            [[ListItem alloc] initWithTitle:@"分页控制器"
                                 controller:@"WYTestPagingViewController"],
            
            [[ListItem alloc] initWithTitle:@"TableViewCell侧滑"
                                 controller:@"WYTestSideslipCellController"],
            
            [[ListItem alloc] initWithTitle:@"图片拼接"
                                 controller:@"WYTestCombineImagesController"],
            
            [[ListItem alloc] initWithTitle:@"图片渲染" controller:@"WYTestImageRenderingController"],
            
            [[ListItem alloc] initWithTitle:@"IM即时通讯(开发中)"
                                 controller:@"WYTestChatController"]
        ];
    });
    return items;
}

@end

@interface WYMainController ()<UITableViewDelegate, UITableViewDataSource, AppEventDelegate>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation WYMainController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"各种测试样例";
    
    self.tableView.backgroundColor = [UIColor wy_dynamicWithLight:[UIColor whiteColor] dark:[UIColor blackColor]];
    
    [WYEventHandler registerWithEvent:AppEventButtonDidMove target:self handler:^(id _Nullable data) {
        WYLog(@"data = %@, controller = %@",data, NSStringFromClass([self class]));
    }];
    
    [WYEventHandler registerWithEvent:AppEventButtonDidReturn target:self handler:^(id _Nullable data) {
        WYLog(@"data = %@, controller = %@",data, NSStringFromClass([self class]));
    }];
    
    __weak typeof(self) weakSelf = self;
    [WYEventHandler registerWithEvent:AppEventDidShowBannerView target:self handler:^(id _Nullable data) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf didShowBannerViewWithData: data];
    }];
    
    // 网络监听
    [WYNetworkStatus listening:@"left" queue:dispatch_get_main_queue() handler:^(NSInteger status) {
        // ✅ 是否已连接网络
        if (WYNetworkStatus.isReachable) {
            WYLogManager.output(@"✅ 网络连接正常");
        }
        
        // ❌ 是否无法连接
        if (WYNetworkStatus.isNotReachable) {
            WYLogManager.output(@"❌ 当前没有网络连接（可能是飞行模式、断网或信号太差）");
        }
        
        // ⚠️ 是否需要额外步骤（如登录认证）
        if (WYNetworkStatus.requiresConnection) {
            WYLogManager.output(@"⚠️ 网络需要建立连接（可能需要认证登录）");
        }
        
        // 📱 是否蜂窝数据网络
        if (WYNetworkStatus.isReachableOnCellular) {
            WYLogManager.output(@"📱 当前使用蜂窝移动网络（4G/5G 数据流量）");
        }
        
        // 📶 是否 Wi-Fi
        if (WYNetworkStatus.isReachableOnWiFi) {
            WYLogManager.output(@"📶 当前通过 Wi-Fi 连接网络");
        }
        
        // 🖥️ 是否有线网络
        if (WYNetworkStatus.isReachableOnWiredEthernet) {
            WYLogManager.output(@"🖥️ 当前使用有线网络（例如 Lightning 转网线适配器）");
        }
        
        // 🛡️ 是否 VPN 连接
        if (WYNetworkStatus.isReachableOnVPN) {
            WYLogManager.output(@"🛡️ 当前通过 VPN 连接（加密通道，可能改变出口 IP）");
        }
        
        // 🔁 是否本地回环接口
        if (WYNetworkStatus.isLoopback) {
            WYLogManager.output(@"🔁 当前网络是本地回环接口（仅限设备内部通信）");
        }
        
        // 💰 是否昂贵连接（蜂窝或热点）
        if (WYNetworkStatus.isExpensive) {
            WYLogManager.output(@"💰 当前网络连接昂贵（例如蜂窝数据或个人热点）");
        }
        
        // 🌐 是否其他(未知类型)
        if (WYNetworkStatus.isReachableOnOther) {
            WYLogManager.output(@"🌐 当前是其他(未知类型)的网络接口（不在常规分类中）");
        }
        
        // 🌍 是否支持 IPv4
        if (WYNetworkStatus.supportsIPv4) {
            WYLogManager.output(@"🌍 当前网络支持 IPv4 协议");
        }
        
        // 🌏 是否支持 IPv6
        if (WYNetworkStatus.supportsIPv6) {
            WYLogManager.output(@"🌏 当前网络支持 IPv6 协议");
        }
        
        // 🧩 当前网络状态值
        NSArray <NSString *>*statusTips = @[@"🟢 当前网络状态：已连接（satisfied）",
                                @"🔴 当前网络状态：未连接（unsatisfied）",
                                @"🟡 当前网络状态：需要额外连接步骤（requiresConnection）",
                                @"⚪️ 当前网络状态：未知"];
        
        [WYActivity showInfo:statusTips[status]];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ListItem.cellItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    
    // 获取所有键并设置文本
    cell.textLabel.text = ListItem.cellItems[indexPath.row].title;
    cell.textLabel.textColor = [UIColor wy_dynamicWithLight:[UIColor blackColor] dark:[UIColor whiteColor]];
    // cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.font = [UIFont systemFontOfSize:[UIDevice wy_screenWidth:15]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *className = ListItem.cellItems[indexPath.row].controller;
    
    UIViewController *nextController = [self wy_showViewControllerWithClassName:className parameters:nil displaMode:WYDisplaModePush animated:YES];
    
    nextController.navigationItem.title = ListItem.cellItems[indexPath.row].title;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [UITableView wy_sharedWithStyle:UITableViewStylePlain separatorStyle: UITableViewCellSeparatorStyleSingleLine delegate:self dataSource:self backgroundColor:[UIColor whiteColor] superView:self.view];
        
        [_tableView wy_register:[UITableViewCell class] style:WYTableViewRegisterStyleCell];
        [_tableView wy_register:[WYLeftControllerHeaderView class] style:WYTableViewRegisterStyleHeaderFooterView];
        [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).mas_offset(UIDevice.wy_navViewHeight);
            make.left.right.equalTo(self.view);
            make.bottom.equalTo(self.view).mas_offset(-UIDevice.wy_tabBarHeight);
        }];
    }
    return _tableView;
}

- (void)didShowBannerViewWithData:(NSString *)data {
    WYLog(@"data = %@, controller = %@",data, NSStringFromClass([self class]));
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
