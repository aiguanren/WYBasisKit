//
//  WYTestTextViewCell.m
//  ObjCVerify
//
//  Created by guanren on 2026/5/21.
//

#import "WYTestTextViewCell.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestTextViewCell () <WYTextViewTouchDelegate>

@property (nonatomic, strong) UITextView *linkView;
@property (nonatomic, strong) UITextView *textView;

@end

@implementation WYTestTextViewCell

#pragma mark - 初始化

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // 创建 linkView
        _linkView = [[UITextView alloc] init];
        _linkView.editable = NO; // 不可编辑
        _linkView.selectable = YES; // 必须为 YES 才能响应链接
        _linkView.dataDetectorTypes = UIDataDetectorTypeNone; // 关闭系统检测，手动控制样式
        _linkView.textContainer.lineFragmentPadding = 0; // 去除左右边距
        _linkView.scrollEnabled = NO;
        _linkView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail; // 文本截断方式
        _linkView.textContainer.maximumNumberOfLines = 0;// 限制最多显示6行
        [self.contentView addSubview:_linkView];
        
        [_linkView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.top.equalTo(self.contentView);
            make.width.mas_equalTo([UIDevice wy_screenWidth] - 30);
        }];
        
        // 创建 textView
        _textView = [[UITextView alloc] init];
        _textView.editable = NO; // 不可编辑
        _textView.selectable = YES; // 必须为 YES 才能响应链接
        _textView.dataDetectorTypes = UIDataDetectorTypeNone; // 关闭系统检测，手动控制样式
        _textView.textContainer.lineFragmentPadding = 0; // 去除左右边距
        _textView.scrollEnabled = NO;
        _textView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail; // 文本截断方式
        _textView.textContainer.maximumNumberOfLines = 0; // 限制最多显示8行
        [self.contentView addSubview:_textView];
        
        [_textView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_linkView.mas_bottom).offset(20);
            make.centerX.equalTo(self.contentView);
            make.width.mas_equalTo([UIDevice wy_screenWidth] - 30);
            make.bottom.equalTo(self.contentView).offset(-20);
        }];
    }
    return self;
}

#pragma mark - 刷新数据

- (void)reloadWithClickEffectColor:(UIColor *)clickEffectColor
              longPressEffectColor:(UIColor *)longPressEffectColor
          longPressMinimumDuration:(NSTimeInterval)longPressMinimumDuration
                  eventPenetration:(BOOL)eventPenetration
                     useCustomFont:(BOOL)useCustomFont {
    
    // 固定文本内容
    NSString *text = @"早知混成这样，不如找个对象，少妇一直是我的理想，她已有车有房，不用我去闯荡，吃着软饭是真的很香。关关雎鸠，在河之洲。窈窕淑女，君子好逑。参差荇菜，左右流之。窈窕淑女，寤寐求之。求之不得，寤寐思服。悠哉悠哉，辗转反侧。参差荇菜，左右采之。窈窕淑女，琴瑟友之。参差荇菜，左右芼之。窈窕淑女，钟鼓乐之。漫步海边，脚下的沙砾带着白日阳光的余温，细腻而柔软。海浪层层叠叠地涌来，热情地亲吻沙滩，又恋恋不舍地退去，发出悦耳声响。海风肆意穿梭，咸湿气息钻进鼻腔，带来大海独有的韵味。抬眼望去，落日熔金，余晖将海面染成橙红，粼粼波光像是无数碎钻在闪烁。我沉醉其中，心也被这梦幻海景悄然填满。";
    
    // 需要添加事件的字符串数组
    NSArray *block_tap = @[@"左右", @"韵味", @"窈窕淑女", @"参差荇菜"];
    NSArray *block_longPress = @[@"左右", @"沙滩", @"海浪", @"参差荇菜"];
    NSArray *delegate_tap = @[@"钟鼓乐之", @"韵味", @"理想", @"参差荇菜"];
    NSArray *delegate_longPress = @[@"粼粼波光", @"沙滩", @"关关雎鸠", @"参差荇菜"];
    
    // 设置 linkView 的基础属性
    self.linkView.wy_clickEffectColor = clickEffectColor;
    self.linkView.wy_longPressEffectColor = longPressEffectColor;
    self.linkView.wy_longPressMinimumDuration = longPressMinimumDuration;
    self.linkView.wy_eventPenetration = eventPenetration;
    
    // 构建富文本
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text];
    
    // 设置行间距 5
    [attributedText wy_lineSpacing:5];
    
    [attributedText wy_underline:[UIColor blueColor] rangeValue:block_tap];
    [attributedText wy_underline:[UIColor purpleColor] rangeValue:block_longPress];
    [attributedText wy_underline:[UIColor orangeColor] rangeValue:delegate_tap];
    [attributedText wy_underline:[UIColor greenColor] rangeValue:delegate_longPress];
    
    // 设置字体
    UIFont *font = nil;
    if (useCustomFont) {
        font = [UIFont fontWithName:@"NotoSans-Regular" size:16];
    } else {
        font = [UIFont boldSystemFontOfSize:16];
    }
    [attributedText wy_setFont:font];
    
    self.linkView.attributedText = attributedText;
    
    // Block 回调 - 点击
    [self.linkView wy_addTextTapEventsWithRangeValue:block_tap handler:^(UITextView *textView, NSString *text, NSRange range, NSInteger index) {
        wy_print(@"自定义Block，点击\ntext:%@,index:%ld,range:%@", text, (long)index, NSStringFromRange(range));
    }];
    // Delegate 回调 - 点击
    [self.linkView wy_addTextTapEventsWithRangeValue:delegate_tap delegate:self];
    // Block 回调 - 长按
    [self.linkView wy_addTextLongPressEventsWithRangeValue:block_longPress handler:^(UITextView *textView, NSString *text, NSRange range, NSInteger index) {
        wy_print(@"自定义Block，长按\ntext:%@,index:%ld,range:%@", text, (long)index, NSStringFromRange(range));
    }];
    // Delegate 回调 - 长按
    [self.linkView wy_addTextLongPressEventsWithRangeValue:delegate_longPress delegate:self];
    
    self.textView.attributedText = attributedText;
    
    for (UITextView *view in @[self.linkView, self.textView]) {
        [view wy_addBorder:UIRectEdgeAll color:[UIColor wy_random] thickness:1];
    }
}

#pragma mark - WYTextViewTouchDelegate（代理回调）

- (void)wy_textViewTextDidClick:(UITextView *)textView clickText:(NSString *)text range:(NSRange)range index:(NSInteger)index {
    wy_print(@"自定义代理，点击\ntext:%@,index:%ld,range:%@", text, (long)index, NSStringFromRange(range));
}

- (void)wy_textViewTextDidLongPress:(UITextView *)textView text:(NSString *)text range:(NSRange)range index:(NSInteger)index {
    wy_print(@"自定义代理，长按\ntext:%@,index:%ld,range:%@", text, (long)index, NSStringFromRange(range));
}

#pragma mark - 释放

- (void)dealloc {
    wy_print(@"WYTestTextViewCell release");
}

@end
