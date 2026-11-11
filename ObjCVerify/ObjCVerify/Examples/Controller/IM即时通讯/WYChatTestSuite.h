//
//  WYChatTestSuite.h
//  ObjCVerify
//
//  Created by guanren on 2026/11/9.
//

#import <UIKit/UIKit.h>

@class WYChatView;

NS_ASSUME_NONNULL_BEGIN

/// 聊天组件接口与布局测试
@interface WYChatTestSuite : UITableViewController
- (instancetype)initWithChatView:(WYChatView *)chatView;
@end

NS_ASSUME_NONNULL_END
