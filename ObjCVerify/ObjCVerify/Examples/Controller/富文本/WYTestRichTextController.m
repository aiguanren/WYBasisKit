//
//  WYTestRichTextController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/8.
//

#import "WYTestRichTextController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestRichTextController ()
@property (nonatomic, copy) void (^updateMeasuredHeights)(void);

@end

@implementation WYTestRichTextController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.accessibilityIdentifier = @"WYRichText.scroll";
    scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:scrollView];
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
    
    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:contentView];
    [NSLayoutConstraint activateConstraints:@[
        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [contentView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [contentView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor]
    ]];

    // 1. 第一个 Label：长文本，测试各种富文本样式
    UILabel *label = [[UILabel alloc] init];
    label.accessibilityIdentifier = @"WYRichText.primary";
    NSString *str = @"治性之道，必审己之所有余而强其所不足，盖聪明疏通者戒于太察，寡闻少见者戒于壅蔽，勇猛刚强者戒于太暴，仁爱温良者戒于无断，湛静安舒者戒于后时，广心浩大者戒于遗忘。必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。";
    label.numberOfLines = 0;
    NSMutableAttributedString *attribute = [[NSMutableAttributedString alloc] initWithString:str];
    [attribute addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:[UIFont wy_fontSize:20 pixels:WYBasisKitConfig.defaultScreenPixels]] range:NSMakeRange(0, str.length)];
    
    [attribute wy_setColorForRanges:@{
        [UIColor blueColor]: @"勇猛刚强",
        [UIColor orangeColor]: @"仁爱温良者戒于无断",
        [UIColor purpleColor]: @"安舒",
        [UIColor magentaColor]: @"必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。"
    }];
    [attribute wy_setColorForRanges:@{[UIColor wy_random]: @[@"太", @"暴"]}];
    [attribute wy_setFontForRanges:@{[UIFont boldSystemFontOfSize:[UIFont wy_fontSize:26 pixels:WYBasisKitConfig.defaultScreenPixels]]: @[[NSValue valueWithRange:NSMakeRange(2,2)], [NSValue valueWithRange:NSMakeRange(20,6)]]}];
    [attribute wy_lineSpacing:15 rangeValue:attribute.string alignment:NSTextAlignmentLeft];
    [attribute wy_wordsSpacing:20 rangeValue:@[@"必审己之所有余而强其所不足", [NSValue valueWithRange:NSMakeRange(20,6)]]];
    [attribute wy_underline:[UIColor magentaColor] rangeValue:@"勇猛刚强"];
    label.attributedText = attribute;
    [contentView addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(contentView);
        make.width.equalTo(contentView).offset(-[UIDevice wy_screenWidth:30 pixels:WYBasisKitConfig.defaultScreenPixels]);
        make.top.equalTo(contentView).offset([UIDevice wy_screenHeight:20 pixels:WYBasisKitConfig.defaultScreenPixels]);
    }];
    
    // 2. 第二个 Label：测试表情匹配
    UILabel *emojiLabel = [[UILabel alloc] init];
    emojiLabel.font = [UIFont systemFontOfSize:[UIFont wy_fontSize:18 pixels:WYBasisKitConfig.defaultScreenPixels]];
    emojiLabel.numberOfLines = 0;
    emojiLabel.backgroundColor = [UIColor whiteColor];
    emojiLabel.textColor = [UIColor blackColor];
    NSMutableAttributedString *emojiLabelAttributed = [NSMutableAttributedString wy_convertEmojiAttributed:@"Hello，这是一个测试表情匹配的UILabel，现在开始匹配，喝彩[喝彩] 唇[唇]  爱心[爱心] 三个表情，看见了吗，他可以用在即时通讯等需要表情匹配的地方，嘻嘻，哈哈" textColor:emojiLabel.textColor textFont:emojiLabel.font emojiTable:@[@"[喝彩]", @"[唇]", @"[爱心]"] sourceBundle:nil pattern:nil];
    [emojiLabelAttributed wy_lineSpacing:5 rangeValue:nil alignment:NSTextAlignmentLeft];
    emojiLabel.attributedText = emojiLabelAttributed;
    [contentView addSubview:emojiLabel];
    [emojiLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(label.mas_bottom).offset([UIDevice wy_screenHeight:50 pixels:WYBasisKitConfig.defaultScreenPixels]);
        make.centerX.equalTo(contentView);
        make.width.equalTo(contentView).offset(-[UIDevice wy_screenWidth:30 pixels:WYBasisKitConfig.defaultScreenPixels]);
    }];
    
    // 3. 第三个 Label：测试内边距
    UILabel *marginLabel = [[UILabel alloc] init];
    marginLabel.text = @"测试内边距";
    marginLabel.font = [UIFont systemFontOfSize:[UIFont wy_fontSize:18 pixels:WYBasisKitConfig.defaultScreenPixels]];
    marginLabel.backgroundColor = [UIColor purpleColor];
    marginLabel.textColor = [UIColor orangeColor];
    NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithString:marginLabel.text];
    [attribute wy_paragraphIndentsWithRangeValue:nil firstLineHeadIndent:10 headIndent:0 tailIndent:-20 alignment:NSTextAlignmentLeft];
    marginLabel.numberOfLines = 0;
    marginLabel.attributedText = attrText;
    [contentView addSubview:marginLabel];
    CGFloat marginLabelWidth = [marginLabel.text wy_calculateWidthWithControlHeight:marginLabel.font.lineHeight controlFont:marginLabel.font lineSpacing:0];
    [marginLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(contentView);
        make.width.mas_equalTo(marginLabelWidth + 30);
        make.top.equalTo(emojiLabel.mas_bottom).offset([UIDevice wy_screenHeight:50 pixels:WYBasisKitConfig.defaultScreenPixels]);
    }];
    
    // 4. 第四个 Label：测试图片附件
    UILabel *attachmentView = [[UILabel alloc] init];
    attachmentView.font = [UIFont systemFontOfSize:[UIFont wy_fontSize:15 pixels:WYBasisKitConfig.defaultScreenPixels]];
    attachmentView.numberOfLines = 0;
    NSString *string_font_30 = @"嘴唇";
    NSString *string_font_40 = @"爱心";
    NSString *string_font_50 = @"喝彩";
    UIImage *image_font_30 = [UIImage wy_find:@"嘴唇"];
    UIImage *image_font_40 = [UIImage wy_find:@"爱心"];
    UIImage *image_font_50 = [UIImage wy_find:@"喝彩"];
    NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:[[NSString wy_randomWithMinimum:10 maximum:20] stringByAppendingFormat:@"\n%@\n%@\n%@\n%@", string_font_30, string_font_40, string_font_50, [NSString wy_randomWithMinimum:10 maximum:20]]];
    
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
    [attributed wy_setFontForRanges:@{[UIFont systemFontOfSize:[UIFont wy_fontSize:30 pixels:WYBasisKitConfig.defaultScreenPixels]]: string_font_30, [UIFont systemFontOfSize:[UIFont wy_fontSize:40 pixels:WYBasisKitConfig.defaultScreenPixels]]: string_font_40, [UIFont systemFontOfSize:[UIFont wy_fontSize:50 pixels:WYBasisKitConfig.defaultScreenPixels]]: string_font_50}];
    [attributed wy_insertImageWithAttachments:options];
    [attributed wy_lineSpacing:10 rangeValue:nil alignment:NSTextAlignmentLeft];
    attachmentView.attributedText = attributed;
    [contentView addSubview:attachmentView];
    [attachmentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(contentView).offset(-[UIDevice wy_screenWidth:30 pixels:WYBasisKitConfig.defaultScreenPixels]);
        make.centerX.equalTo(contentView);
        make.top.equalTo(marginLabel.mas_bottom).offset([UIDevice wy_screenHeight:50 pixels:WYBasisKitConfig.defaultScreenPixels]);
    }];
    
    // 5. 第五个 Label：测试不同范围的行间距
    UILabel *spacingView = [[UILabel alloc] init];
    spacingView.textColor = [UIColor wy_random];
    spacingView.numberOfLines = 0;
    [contentView addSubview:spacingView];
    [spacingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(contentView).offset(-[UIDevice wy_screenWidth:30 pixels:WYBasisKitConfig.defaultScreenPixels]);
        make.centerX.equalTo(contentView);
        make.top.equalTo(attachmentView.mas_bottom).offset([UIDevice wy_screenHeight:50 pixels:WYBasisKitConfig.defaultScreenPixels]);
    }];
    NSString *spacing10 = [NSString wy_randomWithMinimum:50 maximum:100];
    NSString *spacing15 = [NSString wy_randomWithMinimum:30 maximum:80];
    NSString *spacing30 = [NSString wy_randomWithMinimum:25 maximum:60];
    NSString *spacing20 = [NSString wy_randomWithMinimum:80 maximum:100];
    NSMutableAttributedString *spacingAttributed = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n%@\n%@\n%@", spacing10, spacing15, spacing30, spacing20]];
    [spacingAttributed wy_paragraphSpace:10 beforeString:spacing10 afterString:spacing15 alignment:NSTextAlignmentLeft];
    [spacingAttributed wy_paragraphSpace:15 beforeString:spacing15 afterString:spacing30 alignment:NSTextAlignmentRight];
    [spacingAttributed wy_paragraphSpace:30 beforeString:spacing30 afterString:spacing20 alignment:NSTextAlignmentLeft];
    [spacingAttributed wy_lineSpacing:50 rangeValue:spacing20 alignment:NSTextAlignmentLeft];
    spacingView.attributedText = spacingAttributed;
    
    // 6. 第六个 Label：测试宽度计算
    CGFloat sizeHeight = [UIDevice wy_screenHeight:30 pixels:WYBasisKitConfig.defaultScreenPixels];
    UILabel *widthView = [[UILabel alloc] init];
    widthView.backgroundColor = [UIColor wy_random];
    widthView.font = [UIFont boldSystemFontOfSize:[UIFont wy_fontSize:15 pixels:WYBasisKitConfig.defaultScreenPixels]];
    widthView.text = [NSString wy_randomWithMinimum:5 maximum:20];
    [contentView addSubview:widthView];
    [widthView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(contentView);
        make.top.equalTo(spacingView.mas_bottom).offset([UIDevice wy_screenHeight:50 pixels:WYBasisKitConfig.defaultScreenPixels]);
        make.height.equalTo(@(sizeHeight));
    }];
    CGFloat textWidth = [widthView.text wy_calculateWidthWithControlHeight:sizeHeight controlFont:widthView.font lineSpacing:0];
    NSMutableAttributedString *widthAttributed = [[NSMutableAttributedString alloc] initWithString:widthView.text];
    [widthAttributed wy_setFont:widthView.font];
    CGFloat attributedWidth = [widthAttributed wy_calculateWidthWithControlHeight:sizeHeight];
    
    // 7. 第七个 Label：测试高度计算
    UILabel *heightView = [[UILabel alloc] init];
    heightView.accessibilityIdentifier = @"WYRichText.height";
    heightView.backgroundColor = [UIColor wy_random];
    heightView.numberOfLines = 0;
    heightView.font = [UIFont boldSystemFontOfSize:[UIFont wy_fontSize:15 pixels:WYBasisKitConfig.defaultScreenPixels]];
    heightView.text = [NSString wy_randomWithMinimum:150 maximum:300];
    [contentView addSubview:heightView];
    [heightView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(contentView);
        make.top.equalTo(widthView.mas_bottom).offset([UIDevice wy_screenHeight:50 pixels:WYBasisKitConfig.defaultScreenPixels]);
        make.width.equalTo(contentView).offset(-[UIDevice wy_screenWidth:30 pixels:WYBasisKitConfig.defaultScreenPixels]);
    }];
    NSMutableAttributedString *heightAttributed = [[NSMutableAttributedString alloc] initWithString:heightView.text];
    [heightAttributed wy_setFont:heightView.font];
    
    // 辅助线条
    UIView *textWidthLine = [[UIView alloc] init];
    textWidthLine.backgroundColor = [UIColor orangeColor];
    [contentView addSubview:textWidthLine];
    [textWidthLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(widthView);
        make.height.equalTo(@2);
        make.width.equalTo(@(textWidth));
    }];
    UIView *attributedWidthLine = [[UIView alloc] init];
    attributedWidthLine.backgroundColor = [UIColor orangeColor];
    [contentView addSubview:attributedWidthLine];
    [attributedWidthLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.equalTo(widthView);
        make.height.equalTo(@2);
        make.width.equalTo(@(attributedWidth));
    }];
    UIView *textHeightLine = [[UIView alloc] init];
    textHeightLine.backgroundColor = [UIColor redColor];
    [contentView addSubview:textHeightLine];
    [textHeightLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(heightView);
        make.height.equalTo(@0);
        make.width.equalTo(@2);
    }];
    UIView *attributedHeightLine = [[UIView alloc] init];
    attributedHeightLine.backgroundColor = [UIColor redColor];
    [contentView addSubview:attributedHeightLine];
    [attributedHeightLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.top.equalTo(heightView);
        make.height.equalTo(@0);
        make.width.equalTo(@2);
    }];
    
    // 滚动区域底部预留空间（与 Swift 对齐，保证最后一个视图能完全滚动露出）
    [heightView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(contentView).offset(-[UIDevice wy_screenHeight:50 pixels:WYBasisKitConfig.defaultScreenPixels]);
    }];
    
    // 打印行信息
    [label layoutIfNeeded];
    __block CGFloat measuredWidth = 0;
    self.updateMeasuredHeights = ^{
        CGFloat width = heightView.bounds.size.width;
        if (width <= 0 || width == measuredWidth) { return; }
        measuredWidth = width;
        CGFloat textHeight = [heightView.text wy_calculateHeightWithControlWidth:width controlFont:heightView.font lineSpacing:0];
        CGFloat attributedHeight = [heightAttributed wy_calculateHeightWithControlWidth:width];
        [textHeightLine mas_updateConstraints:^(MASConstraintMaker *make) { make.height.equalTo(@(textHeight)); }];
        [attributedHeightLine mas_updateConstraints:^(MASConstraintMaker *make) { make.height.equalTo(@(attributedHeight)); }];
    };
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.updateMeasuredHeights != nil) { self.updateMeasuredHeights(); }
}

- (void)dealloc {
    wy_print(@"dealloc");
}

@end
