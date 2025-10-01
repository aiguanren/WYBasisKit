//
//  WYMainController.m
//  ObjCVerify
//
//  Created by guanren on 2025/10/1.
//

#import "WYMainController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYMainController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *cellObjs;

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation WYMainController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"各种测试样例";
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
            @"WKWebView进度条": @"WYWebViewController",
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

- (UITableView *)tableView {
    if (!_tableView) {
        
        _tableView = [UITableView wy_sharedWithFrame:CGRectZero style:UITableViewStylePlain headerHeight:0 footerHeight:0 rowHeight:0 separatorStyle:UITableViewCellSeparatorStyleSingleLine delegate:self dataSource:self backgroundColor:[UIColor whiteColor] superView:self.view];
        
        [_tableView wy_register:[UITableViewCell class] style:WYTableViewRegisterStyleCell];
        //[_tableView wy_register:[WYLeftControllerHeaderView class] style:WYTableViewRegisterStyleHeaderFooterView];
        [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).mas_offset(UIDevice.wy_navViewHeight);
            make.left.right.equalTo(self.view);
            make.bottom.equalTo(self.view).mas_offset(UIDevice.wy_tabBarHeight);
        }];
    }
    return _tableView;
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
