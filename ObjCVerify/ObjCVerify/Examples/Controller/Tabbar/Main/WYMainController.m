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

@interface WYMainController ()<UITableViewDelegate, UITableViewDataSource, AppEventDelegate>

@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *cellObjs;

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
//    WYNetworkStatus.listening("left") { status in
//        switch status {
//        case .notReachable:
//            WYActivity.showInfo("无网络连接")
//        case .unknown :
//            WYActivity.showInfo("未知网络连接状态")
//        case .reachable(.ethernetOrWiFi):
//            WYActivity.showInfo("连接到WiFi网络")
//        case .reachable(.cellular):
//            WYActivity.showInfo("连接到移动网络")
//        }
//    }
}

- (NSDictionary<NSString *,NSString *> *)cellObjs {
    if (_cellObjs == nil) {
        _cellObjs = @{
            @"暗夜、白昼模式": @"WYTestDarkNightModeController",
            @"约束view添加动画": @"WYTestAnimationController",
            @"边框、圆角、阴影、渐变": @"WYTestVisualController",
            @"ButtonEdgeInsets": @"WYTestButtonEdgeInsetsController",
            @"Banner轮播": @"WYTestBannerController",
            @"富文本": @"WYTestRichTextController",
            @"无限层折叠TableView": @"WYMultilevelTableViewController",
            @"tableView.plain": @"WYTableViewPlainController",
            @"tableView.grouped": @"WYTableViewGroupedController",
            @"下载与缓存": @"WYTestDownloadController",
            @"网络请求": @"WYTestRequestController",
            @"屏幕旋转": @"WYTestInterfaceOrientationController",
            @"二维码": @"WYQRCodeController",
            @"Gif加载": @"WYParseGifController",
            @"瀑布流": @"WYFlowLayoutAlignmentController",
            @"直播、点播播放器": @"WYTestLiveStreamingController",
            @"IM即时通讯(开发中)": @"WYTestChatController",
            @"语音识别": @"WYSpeechRecognitionController",
            @"泛型": @"WYGenericTypeController",
            @"离线方法调用": @"WYOffLineMethodController",
            @"WKWebView进度条": @"WYTestWebViewController",
            @"归档/解归档": @"WYArchivedController",
            @"日志输出与保存": @"WYLogController",
            @"音频录制与播放": @"TestAudioController",
            @"设备振动": @"WYTestVibrateController",
            @"文本轮播": @"WYTestScrollTextController",
            @"分页控制器": @"WYTestPagingViewController"
        };
    }
    return _cellObjs;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cellObjs.allKeys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    
    // 获取所有键并设置文本
    cell.textLabel.text = _cellObjs.allKeys[indexPath.row];
    cell.textLabel.textColor = [UIColor wy_dynamicWithLight:[UIColor blackColor] dark:[UIColor whiteColor]];
    // cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.font = [UIFont systemFontOfSize:[UIDevice wy_screenWidth:15]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *className = _cellObjs.allValues[indexPath.row];
    
    UIViewController *nextController = [self wy_showViewControllerWithClassName:className parameters:nil displaMode:WYDisplaModePush animated:YES];
    
    nextController.navigationItem.title = _cellObjs.allKeys[indexPath.row];
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [UITableView wy_sharedWithFrame:CGRectZero style:UITableViewStylePlain headerHeight:UITableViewAutomaticDimension footerHeight:UITableViewAutomaticDimension rowHeight:UITableViewAutomaticDimension separatorStyle:UITableViewCellSeparatorStyleSingleLine delegate:self dataSource:self backgroundColor:[UIColor whiteColor] superView:self.view];
        
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
