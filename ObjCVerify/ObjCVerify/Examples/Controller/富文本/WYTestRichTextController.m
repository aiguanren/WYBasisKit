//
//  WYTestRichTextController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/8.
//

#import "WYTestRichTextController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestRichTextController ()<WYRichTextDelegate>

@end

@implementation WYTestRichTextController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    [self.view addSubview:scrollView];
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // -------------------------------------------------------------------------
    // 第一个 Label：点击 + 长按测试，不同字符串独立
    // -------------------------------------------------------------------------
    UILabel *label = [[UILabel alloc] init];
    NSString *str = @"治性之道，必审己之所有余而强其所不足，盖聪明疏通者戒于太察，寡闻少见者戒于壅蔽，勇猛刚强者戒于太暴，仁爱温良者戒于无断，湛静安舒者戒于后时，广心浩大者戒于遗忘。必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。";
    label.numberOfLines = 0;
    NSMutableAttributedString *attribute = [[NSMutableAttributedString alloc] initWithString:str];
    [attribute addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:20] range:NSMakeRange(0, str.length)];
    
    [attribute wy_setColorForRanges:@{
        [UIColor blueColor]: @"勇猛刚强",
        [UIColor orangeColor]: @"仁爱温良者戒于无断",
        [UIColor purpleColor]: @"安舒",
        [UIColor magentaColor]: @"必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。"
    }];
    [attribute wy_setColorForRanges:@{[UIColor wy_random]: @[@"足", @"太", @"暴"]}];
    [attribute wy_setFontForRanges:@{[UIFont boldSystemFontOfSize:26]: @[@[@"2", @"2"], @[@"8", @"5"]]}];
    [attribute wy_lineSpacing:15];
    [attribute wy_underline:[UIColor magentaColor] rangeValue:@[@"勇猛刚强", @"仁爱温良者戒于无断", @"安舒", @"必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。"]];
    
    label.attributedText = attribute;
    label.wy_maxTouchMoveDistance = 50;
    label.wy_enableLongPress = YES;
    label.wy_longPressMinimumDuration = 1;
    
    // 点击专用字符串数组
    NSArray *tapStrings = @[@"勇猛刚强", @"仁爱温良者戒于无断", @"安舒", @"必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。"];
    // 长按专用字符串数组（与点击不同）
    NSArray *longPressStrings = @[@"所有余而强其所不足，盖聪明疏通者戒于太察，寡闻少见者戒于壅蔽",
                                  @"广心浩大者戒于遗忘",
                                  @"必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。"];
    
    [label wy_addRichTextTapWithStrings:tapStrings handler:^(UILabel *label, NSString *richText, NSRange range, NSInteger index) {
        if ([richText isEqualToString:@"勇猛刚强"]) {
            [WYActivity showInfo:[NSString stringWithFormat:@"string = %@ range = %@ index = %ld", richText, NSStringFromRange(range), (long)index] option:[self activityInfoWithPosition:WYActivityPositionMiddle]];
        } else if ([richText isEqualToString:@"仁爱温良者戒于无断"]) {
            [WYActivity showInfo:[NSString stringWithFormat:@"string = %@ range = %@ index = %ld", richText, NSStringFromRange(range), (long)index] option:[self activityInfoWithPosition:WYActivityPositionTop]];
        } else if ([richText isEqualToString:@"安舒"]) {
            [WYActivity showInfo:[NSString stringWithFormat:@"string = %@ range = %@ index = %ld", richText, NSStringFromRange(range), (long)index] option:[self activityInfoWithPosition:WYActivityPositionBottom]];
        }
    }];
    
    // 同时添加点击 Delegate（同一字符串也可以触发 delegate）
    [label wy_addRichTextTapWithStrings:tapStrings delegate:self];
    // 添加长按 Delegate（使用不同的字符串数组）
    [label wy_addRichTextLongPressWithStrings:longPressStrings delegate:self];
    
    [scrollView addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(scrollView);
        make.width.equalTo(@([UIDevice wy_screenWidth] - 30));
        make.top.equalTo(scrollView).offset(20);
    }];
    
    // -------------------------------------------------------------------------
    // 表情 Label（原有测试）
    // -------------------------------------------------------------------------
    UILabel *emojiLabel = [[UILabel alloc] init];
    emojiLabel.font = [UIFont systemFontOfSize:18];
    emojiLabel.numberOfLines = 0;
    emojiLabel.backgroundColor = [UIColor whiteColor];
    emojiLabel.textColor = [UIColor blackColor];
    NSMutableAttributedString *emojiLabelAttributed = [NSMutableAttributedString wy_convertEmojiAttributed:@"Hello，这是一个测试表情匹配的UILabel，现在开始匹配，喝彩[喝彩] 唇[唇]  爱心[爱心] 三个表情，看见了吗，他可以用在即时通讯等需要表情匹配的地方，嘻嘻，哈哈" textColor:emojiLabel.textColor textFont:emojiLabel.font emojiTable:@[@"[喝彩]", @"[唇]", @"[爱心]"] sourceBundle:nil pattern:nil];
    [emojiLabelAttributed wy_lineSpacing:5];
    emojiLabel.attributedText = emojiLabelAttributed;
    [scrollView addSubview:emojiLabel];
    [emojiLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(label.mas_bottom).offset(50);
        make.centerX.equalTo(scrollView);
        make.width.equalTo(@([UIDevice wy_screenWidth] - 30));
    }];
    
    // -------------------------------------------------------------------------
    // 内边距 Label（原有）
    // -------------------------------------------------------------------------
    UILabel *marginLabel = [[UILabel alloc] init];
    marginLabel.text = @"测试内边距";
    marginLabel.font = [UIFont systemFontOfSize:18];
    marginLabel.backgroundColor = [UIColor purpleColor];
    marginLabel.textColor = [UIColor orangeColor];
    NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithString:marginLabel.text];
    [attrText wy_innerMarginWithFirstLineHeadIndent:10 headIndent:0 tailIndent:-20 alignment:NSTextAlignmentLeft];
    marginLabel.numberOfLines = 0;
    marginLabel.attributedText = attrText;
    [scrollView addSubview:marginLabel];
    CGFloat marginLabelWidth = [marginLabel.text wy_calculateWidthWithControlHeight:marginLabel.font.lineHeight controlFont:marginLabel.font];
    [marginLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(scrollView);
        make.width.mas_equalTo(marginLabelWidth + 30);
        make.top.equalTo(emojiLabel.mas_bottom).offset(50);
    }];
    
    [label layoutIfNeeded];
    NSArray *lines = [label.attributedText wy_stringPerLineWithControlWidth:label.wy_width];
    NSInteger numberOfRows = [label.attributedText wy_numberOfRowsWithControlWidth:label.wy_width];
    wy_print(@"每行显示的分别是 %@, 一共 %ld 行", lines, (long)numberOfRows);
    
    // -------------------------------------------------------------------------
    // 图文混排 Label（原有）
    // -------------------------------------------------------------------------
    UILabel *attachmentView = [[UILabel alloc] init];
    attachmentView.font = [UIFont systemFontOfSize:15];
    attachmentView.numberOfLines = 0;
    NSString *string_font_30 = @"嘴唇";
    NSString *string_font_40 = @"爱心";
    NSString *string_font_50 = @"喝彩";
    UIImage *image_font_30 = [UIImage wy_find:@"嘴唇"];
    UIImage *image_font_40 = [UIImage wy_find:@"爱心"];
    UIImage *image_font_50 = [UIImage wy_find:@"喝彩"];
    NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:[[NSString wy_randomWithMinimux:10 maximum:20] stringByAppendingFormat:@"\n%@\n%@\n%@\n%@", string_font_30, string_font_40, string_font_50, [NSString wy_randomWithMinimux:10 maximum:20]]];
    
    NSInteger string_font_50Index = 0;
    NSRange range50 = [attributed.string rangeOfString:string_font_50];
    if (range50.location != NSNotFound) {
        string_font_50Index = range50.location - 1;
    }
    NSArray<WYImageAttachmentOption *> *options = @[
        [[WYImageAttachmentOption alloc] initWithImage:image_font_30 size:CGSizeMake(10, 10) position:WYImageAttachmentPositionIndex positionValue:@1 offsetY:5 spacingBefore:0 spacingAfter:20],
        [[WYImageAttachmentOption alloc] initWithImage:image_font_30 size:CGSizeMake(20, 20) position:WYImageAttachmentPositionBefore positionValue:string_font_30 offsetY:9 spacingBefore:0 spacingAfter:20],
        [[WYImageAttachmentOption alloc] initWithImage:image_font_40 size:CGSizeMake(20, 20) position:WYImageAttachmentPositionAfter positionValue:string_font_40 offsetY:2.5 spacingBefore:10 spacingAfter:0],
        [[WYImageAttachmentOption alloc] initWithImage:image_font_50 size:CGSizeMake(10, 10) position:WYImageAttachmentPositionIndex positionValue:@(string_font_50Index + 2) offsetY:30 spacingBefore:0 spacingAfter:0],
        [[WYImageAttachmentOption alloc] initWithImage:image_font_50 size:CGSizeMake(20, 20) position:WYImageAttachmentPositionAfter positionValue:string_font_50 offsetY:-5 spacingBefore:0 spacingAfter:0]
    ];
    [attributed wy_setFontForRanges:@{[UIFont systemFontOfSize:30]: string_font_30, [UIFont systemFontOfSize:40]: string_font_40, [UIFont systemFontOfSize:50]: string_font_50}];
    [attributed wy_insertImageWithAttachments:options];
    [attributed wy_lineSpacing:10];
    attachmentView.attributedText = attributed;
    [scrollView addSubview:attachmentView];
    [attachmentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@([UIDevice wy_screenWidth] - 30));
        make.centerX.equalTo(scrollView);
        make.top.equalTo(marginLabel.mas_bottom).offset(50);
    }];
    
    // -------------------------------------------------------------------------
    // 行间距测试（原有）
    // -------------------------------------------------------------------------
    UILabel *spacingView = [[UILabel alloc] init];
    spacingView.textColor = [UIColor wy_random];
    spacingView.numberOfLines = 0;
    [scrollView addSubview:spacingView];
    [spacingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@([UIDevice wy_screenWidth] - 30));
        make.centerX.equalTo(scrollView);
        make.top.equalTo(attachmentView.mas_bottom).offset(50);
    }];
    NSString *spacing10 = [NSString wy_randomWithMinimux:50 maximum:100];
    NSString *spacing15 = [NSString wy_randomWithMinimux:30 maximum:80];
    NSString *spacing30 = [NSString wy_randomWithMinimux:25 maximum:60];
    NSString *spacing20 = [NSString wy_randomWithMinimux:80 maximum:100];
    wy_print(@"spacing10 = %@, spacing15 = %@, spacing30 = %@, spacing20 = %@", spacing10, spacing15, spacing30, spacing20);
    NSMutableAttributedString *spacingAttributed = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n%@\n%@\n%@", spacing10, spacing15, spacing30, spacing20]];
    [spacingAttributed wy_lineSpacing:10 beforeString:spacing10 afterString:spacing15 alignment:NSTextAlignmentLeft];
    [spacingAttributed wy_lineSpacing:15 beforeString:spacing15 afterString:spacing30 alignment:NSTextAlignmentRight];
    [spacingAttributed wy_lineSpacing:30 beforeString:spacing30 afterString:spacing20 alignment:NSTextAlignmentLeft];
    [spacingAttributed wy_lineSpacing:50 rangeValue:spacing20 alignment:NSTextAlignmentLeft];
    spacingView.attributedText = spacingAttributed;
    
    // -------------------------------------------------------------------------
    // 宽度 / 高度计算对比（原有）
    // -------------------------------------------------------------------------
    CGFloat sizeWidth = [UIDevice wy_screenWidth] - 30;
    CGFloat sizeHeight = 30;
    UILabel *widthView = [[UILabel alloc] init];
    widthView.backgroundColor = [UIColor wy_random];
    widthView.font = [UIFont boldSystemFontOfSize:15];
    widthView.text = [NSString wy_randomWithMinimux:5 maximum:20];
    [scrollView addSubview:widthView];
    [widthView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(scrollView);
        make.top.equalTo(spacingView.mas_bottom).offset([UIDevice wy_screenWidth:50]);
        make.height.equalTo(@(sizeHeight));
    }];
    CGFloat textWidth = [widthView.text wy_calculateWidthWithControlHeight:sizeHeight controlFont:widthView.font lineSpacing:0 wordsSpacing:0];
    NSMutableAttributedString *widthAttributed = [[NSMutableAttributedString alloc] initWithString:widthView.text];
    [widthAttributed wy_setFont:widthView.font];
    CGFloat attributedWidth = [widthAttributed wy_calculateWidthWithControlHeight:sizeHeight];
    
    UILabel *heightView = [[UILabel alloc] init];
    heightView.backgroundColor = [UIColor wy_random];
    heightView.numberOfLines = 0;
    heightView.font = [UIFont boldSystemFontOfSize:15];
    heightView.text = [NSString wy_randomWithMinimux:150 maximum:300];
    [scrollView addSubview:heightView];
    [heightView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(scrollView);
        make.top.equalTo(widthView.mas_bottom).offset([UIDevice wy_screenWidth:50]);
        make.width.equalTo(@(sizeWidth));
    }];
    CGFloat textHeight = [heightView.text wy_calculateHeightWithControlWidth:sizeWidth controlFont:heightView.font lineSpacing:0 wordsSpacing:0];
    NSMutableAttributedString *heightAttributed = [[NSMutableAttributedString alloc] initWithString:heightView.text];
    [heightAttributed wy_setFont:heightView.font];
    CGFloat attributedHeight = [heightAttributed wy_calculateHeightWithControlWidth:sizeWidth];
    
    UIView *textWidthLine = [[UIView alloc] init];
    textWidthLine.backgroundColor = [UIColor orangeColor];
    [scrollView addSubview:textWidthLine];
    [textWidthLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(widthView);
        make.height.equalTo(@2);
        make.width.equalTo(@(textWidth));
    }];
    UIView *attributedWidthLine = [[UIView alloc] init];
    attributedWidthLine.backgroundColor = [UIColor orangeColor];
    [scrollView addSubview:attributedWidthLine];
    [attributedWidthLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.equalTo(widthView);
        make.height.equalTo(@2);
        make.width.equalTo(@(attributedWidth));
    }];
    UIView *textHeightLine = [[UIView alloc] init];
    textHeightLine.backgroundColor = [UIColor redColor];
    [scrollView addSubview:textHeightLine];
    [textHeightLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(heightView);
        make.height.equalTo(@(textHeight));
        make.width.equalTo(@2);
    }];
    UIView *attributedHeightLine = [[UIView alloc] init];
    attributedHeightLine.backgroundColor = [UIColor redColor];
    [scrollView addSubview:attributedHeightLine];
    [attributedHeightLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.top.equalTo(heightView);
        make.height.equalTo(@(attributedHeight));
        make.width.equalTo(@2);
    }];
    
    // -------------------------------------------------------------------------
    // 新增测试：垂直居中、numberOfLines=0、不同对齐方式
    // -------------------------------------------------------------------------
    __block UIView *lastView = heightView;
    
    // 1. 多行 + 垂直居中（固定高度）
    UILabel *centerLabel = [[UILabel alloc] init];
    centerLabel.numberOfLines = 0;
    centerLabel.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    NSString *centerText = @"垂直 居中 测试长按\n第二行 可点击 内容\n第三行包含可点击 LinkCenter";
    NSMutableAttributedString *centerAttr = [[NSMutableAttributedString alloc] initWithString:centerText];
    NSMutableParagraphStyle *centerStyle = [[NSMutableParagraphStyle alloc] init];
    centerStyle.lineSpacing = 8;
    centerStyle.alignment = NSTextAlignmentCenter;
    [centerAttr addAttribute:NSParagraphStyleAttributeName value:centerStyle range:NSMakeRange(0, centerAttr.length)];
    [centerAttr wy_setFontForRanges:@{[UIFont systemFontOfSize:19]: centerText}];
    [centerAttr wy_setColorForRanges:@{[UIColor redColor]: @[@"居中", @"可点击", @"LinkCenter"]}];
    [centerAttr wy_underline:[UIColor wy_random] rangeValue:@[@"长按", @"行", @"LinkCenter"]];
    centerLabel.attributedText = centerAttr;
    centerLabel.wy_longPressEffectColor = [UIColor greenColor];
    centerLabel.wy_enableLongPress = YES;
    centerLabel.wy_longPressMinimumDuration = 1;
    [centerLabel wy_addRichTextTapWithStrings:@[@"居中", @"可点击", @"LinkCenter", @"第", @"行"] delegate:self];
    [centerLabel wy_addRichTextLongPressWithStrings:@[@"长按", @"行", @"LinkCenter", @"第"] handler:^(UILabel *label, NSString *richText, NSRange range, NSInteger index) {
        [WYActivity showInfo:[NSString stringWithFormat:@"string = %@ range = %@ index = %ld", richText, NSStringFromRange(range), (long)index] option:[self activityInfoWithPosition:WYActivityPositionBottom]];
    }];
    [scrollView addSubview:centerLabel];
    [centerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastView.mas_bottom).offset(40);
        make.centerX.equalTo(scrollView);
        make.width.equalTo(@([UIDevice wy_screenWidth] - 40));
        make.height.equalTo(@160);
    }];
    lastView = centerLabel;
    
    // 2. numberOfLines = 0 + 自动换行 + 多链接
    UILabel *autoLabel = [[UILabel alloc] init];
    autoLabel.numberOfLines = 0;
    autoLabel.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    NSString *autoText = @"这是一段自动换行测试文本 numberOfLines=0。点击测试链接：https://www.example.com 和 www.baidu.com 以及最后一个链接 https://github.com";
    NSMutableAttributedString *autoAttr = [[NSMutableAttributedString alloc] initWithString:autoText];
    [autoAttr wy_setFontForRanges:@{[UIFont systemFontOfSize:18]: autoText}];
    [autoAttr wy_setColorForRanges:@{[UIColor systemBlueColor]: @[@"https://www.example.com", @"www.baidu.com", @"https://github.com"]}];
    autoLabel.attributedText = autoAttr;
    autoLabel.wy_clickEffectColor = [UIColor orangeColor];
    [autoLabel wy_addRichTextTapWithStrings:@[@"https://www.example.com", @"www.baidu.com", @"https://github.com"] delegate:self];
    [scrollView addSubview:autoLabel];
    [autoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastView.mas_bottom).offset(40);
        make.centerX.equalTo(scrollView);
        make.width.equalTo(@([UIDevice wy_screenWidth] - 40));
    }];
    lastView = autoLabel;
    
    // 3. 不同 textAlignment + 垂直居中 组合测试
    NSArray<NSDictionary *> *alignments = @[
        @{@"title": @"左对齐 + 垂直居中", @"alignment": @(NSTextAlignmentLeft)},
        @{@"title": @"居中对齐 + 垂直居中", @"alignment": @(NSTextAlignmentCenter)},
        @{@"title": @"右对齐 + 垂直居中", @"alignment": @(NSTextAlignmentRight)}
    ];
    for (NSDictionary *alignInfo in alignments) {
        NSString *title = alignInfo[@"title"];
        NSTextAlignment alignment = [alignInfo[@"alignment"] integerValue];
        UILabel *alignLabel = [[UILabel alloc] init];
        alignLabel.numberOfLines = 0;
        alignLabel.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        NSString *alignText = [NSString stringWithFormat:@"%@\n第二行测试文字\n第三行可点击 ClickMe", title];
        NSMutableAttributedString *alignAttr = [[NSMutableAttributedString alloc] initWithString:alignText];
        NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
        paraStyle.alignment = alignment;
        paraStyle.lineSpacing = 10;
        [alignAttr addAttribute:NSParagraphStyleAttributeName value:paraStyle range:NSMakeRange(0, alignAttr.length)];
        [alignAttr wy_setFontForRanges:@{[UIFont systemFontOfSize:18]: alignText}];
        [alignAttr wy_setColorForRanges:@{[UIColor systemPinkColor]: @"ClickMe"}];
        [alignAttr wy_underline:[UIColor wy_random] rangeValue:@[@"对齐", @"测试", @"ClickMe"]];
        alignLabel.attributedText = alignAttr;
        alignLabel.wy_enableLongPress = YES;
        alignLabel.wy_longPressMinimumDuration = 5;
        [alignLabel wy_addRichTextLongPressWithStrings:@[@"对齐", @"测试", @"ClickMe"] delegate:self];
        [alignLabel wy_addRichTextTapWithStrings:@[@"ClickMe"] delegate:self];
        [scrollView addSubview:alignLabel];
        [alignLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(lastView.mas_bottom).offset(40);
            make.centerX.equalTo(scrollView);
            make.width.equalTo(@([UIDevice wy_screenWidth] - 40));
            make.height.equalTo(@140);
        }];
        lastView = alignLabel;
    }
    
    // 设置 scrollView 底部约束，确保滚动到底部
    [lastView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(scrollView).offset(-50);
    }];
}

- (WYMessageInfoOptions *)activityInfoWithPosition:(WYActivityPosition)position {
    WYMessageInfoOptions *option = [[WYMessageInfoOptions alloc] init];
    option.position = position;
    option.contentView = self.view;
    return option;
}

#pragma mark - WYRichTextDelegate

- (void)wy_richTextDidClick:(UILabel *)label richText:(NSString *)richText range:(NSRange)range index:(NSInteger)index {
    // 处理点击回调（Delegate 方式）
    if ([richText isEqualToString:@"必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。"]) {
        [WYActivity showScrollInfo:@"必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。"];
    } else {
        [WYActivity showInfo:[NSString stringWithFormat:@"点击: %@", richText] option:[self activityInfoWithPosition:WYActivityPositionMiddle]];
    }
}

- (void)wy_richTextDidLongPress:(UILabel *)label richText:(NSString *)richText range:(NSRange)range index:(NSInteger)index {
    [WYActivity showInfo:[NSString stringWithFormat:@"长按: %@", richText] option:[self activityInfoWithPosition:WYActivityPositionMiddle]];
}

- (void)dealloc {
    wy_print(@"dealloc");
}

@end
