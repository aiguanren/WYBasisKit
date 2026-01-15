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
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    [self.view addSubview:scrollView];
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    UILabel *label = [[UILabel alloc] init];
    NSString *str = @"治性之道，必审己之所有余而强其所不足，盖聪明疏通者戒于太察，寡闻少见者戒于壅蔽，勇猛刚强者戒于太暴，仁爱温良者戒于无断，湛静安舒者戒于后时，广心浩大者戒于遗忘。必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。";
    label.numberOfLines = 0;
    NSMutableAttributedString *attribute = [[NSMutableAttributedString alloc] initWithString:str];
    
    [attribute addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:20] range:NSMakeRange(0, str.length)];
    [attribute wy_colorsOfRanges:@{[UIColor blueColor]: @"勇猛刚强", [UIColor orangeColor]: @"仁爱温良者戒于无断", [UIColor purpleColor]: @"安舒", [UIColor magentaColor]: @"必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。"}];
    [attribute wy_lineSpacing:15];
    
    label.attributedText = attribute;
    label.wy_clickEffectColor = [UIColor greenColor];
    [label wy_addRichTexts:@[@"勇猛刚强", @"仁爱温良者戒于无断", @"安舒", @"必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。"] handler:^(NSString * _Nonnull string, NSRange range, NSInteger index) {
        //WYLog(@"string = %@, range = %@, index = %ld", string, NSStringFromRange(range), (long)index);
        
        if ([string isEqualToString:@"勇猛刚强"]) {
            
            [WYActivity showInfo:[NSString stringWithFormat:@"string = %@ range = %@ index = %ld", string, NSStringFromRange(range), (long)index] option: [self activityInfoWithPosition:WYActivityPositionMiddle]];
        }
        if ([string isEqualToString:@"仁爱温良者戒于无断"]) {
            
            [WYActivity showInfo:[NSString stringWithFormat:@"string = %@ range = %@ index = %ld", string, NSStringFromRange(range), (long)index] option:[self activityInfoWithPosition:WYActivityPositionTop]];
        }
        if ([string isEqualToString:@"安舒"]) {
            
            [WYActivity showInfo:[NSString stringWithFormat:@"string = %@ range = %@ index = %ld", string, NSStringFromRange(range), (long)index] option:[self activityInfoWithPosition:WYActivityPositionBottom]];
        }
    }];
    [label wy_addRichTexts:@[@"勇猛刚强", @"仁爱温良者戒于无断", @"安舒", @"必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。"] delegate:self];
    [scrollView addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(scrollView);
        make.width.equalTo(@([UIDevice wy_screenWidth] - 30));
        make.top.equalTo(scrollView).offset(20);
    }];
    
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
    
    UILabel *marginLabel = [[UILabel alloc] init];
    marginLabel.text = @"测试内边距";
    marginLabel.font = [UIFont systemFontOfSize:18];
    marginLabel.backgroundColor = [UIColor purpleColor];
    marginLabel.textColor = [UIColor orangeColor];
    
    NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithString:marginLabel.text];
    [attrText wy_innerMarginWithFirstLineHeadIndent:10 headIndent:0 tailIndent:-10 alignment:NSTextAlignmentLeft];
    
    marginLabel.numberOfLines = 0;
    marginLabel.attributedText = attrText;
    [scrollView addSubview:marginLabel];
    
    [marginLabel sizeToFit];
    [marginLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(scrollView);
        make.width.equalTo(@(marginLabel.wy_width + 10));
        make.top.equalTo(emojiLabel.mas_bottom).offset(50);
    }];
    
    [label layoutIfNeeded];
    
    NSArray *lines = [label.attributedText wy_stringPerLineWithControlWidth:label.wy_width];
    NSInteger numberOfRows = [label.attributedText wy_numberOfRowsWithControlWidth:label.wy_width];
    WYLog(@"每行显示的分别是 %@, 一共 %ld 行", lines, (long)numberOfRows);
    
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
    NSRange range = [attributed.string rangeOfString:string_font_50];
    if (range.location != NSNotFound) {
        string_font_50Index = range.location - 1;
    } else {
        string_font_50Index = 0; // 未找到的情况，可根据需求调整
    }
    NSArray<WYImageAttachmentOption *> *options = @[
        [[WYImageAttachmentOption alloc] initWithImage:image_font_30 size:CGSizeMake(20, 20) position:WYImageAttachmentPositionBefore positionValue:string_font_30 alignment:WYImageAttachmentAlignmentTop alignmentOffset:0 spacingBefore:0 spacingAfter:20],
        
        [[WYImageAttachmentOption alloc] initWithImage:image_font_30 size:CGSizeMake(10, 10) position:WYImageAttachmentPositionIndex positionValue:@1 alignment:WYImageAttachmentAlignmentTop alignmentOffset:0 spacingBefore:0 spacingAfter:20],
        
        [[WYImageAttachmentOption alloc] initWithImage:image_font_40 size:CGSizeMake(20, 20) position:WYImageAttachmentPositionAfter positionValue:string_font_40 alignment:WYImageAttachmentAlignmentCenter alignmentOffset:0 spacingBefore:10 spacingAfter:0],
        
        [[WYImageAttachmentOption alloc] initWithImage:image_font_50 size:CGSizeMake(20, 20) position:WYImageAttachmentPositionAfter positionValue:string_font_50 alignment:WYImageAttachmentAlignmentBottom alignmentOffset:0 spacingBefore:0 spacingAfter:0],
        
        [[WYImageAttachmentOption alloc] initWithImage:image_font_50 size:CGSizeMake(10, 10) position:WYImageAttachmentPositionIndex positionValue:@(string_font_50Index + 2) alignment:WYImageAttachmentAlignmentCustom alignmentOffset:-30 spacingBefore:0 spacingAfter:0]
    ];
    [attributed wy_fontsOfRanges:@{[UIFont systemFontOfSize:30]: string_font_30, [UIFont systemFontOfSize:40]: string_font_40, [UIFont systemFontOfSize:50]: string_font_50}];
    [attributed wy_insertImageWithAttachments:options];
    [attributed wy_lineSpacing:10];
    attachmentView.attributedText = attributed;
    [scrollView addSubview:attachmentView];
    [attachmentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@([UIDevice wy_screenWidth] - 30));
        make.centerX.equalTo(scrollView);
        make.top.equalTo(marginLabel.mas_bottom).offset(50);
    }];
    
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
    
    WYLog(@"spacing10 = %@, spacing15 = %@, spacing30 = %@, spacing20 = %@", spacing10, spacing15, spacing30, spacing20);
    
    NSMutableAttributedString *spacingAttributed = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n%@\n%@\n%@", spacing10, spacing15, spacing30, spacing20]];
    [spacingAttributed wy_lineSpacing:10 beforeString:spacing10 afterString:spacing15 alignment:NSTextAlignmentLeft];
    [spacingAttributed wy_lineSpacing:15 beforeString:spacing15 afterString:spacing30 alignment:NSTextAlignmentRight];
    [spacingAttributed wy_lineSpacing:30 beforeString:spacing30 afterString:spacing20 alignment:NSTextAlignmentLeft];
    [spacingAttributed wy_lineSpacing:50 subString:spacing20 alignment:NSTextAlignmentLeft];
    spacingView.attributedText = spacingAttributed;
    
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
        make.bottom.equalTo(scrollView).offset(-50);
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
}

- (WYMessageInfoOptions *)activityInfoWithPosition:(WYActivityPosition)position {
    WYMessageInfoOptions *option = [[WYMessageInfoOptions alloc] init];
    option.position = position;
    option.contentView = self.view;
    return option;
}

#pragma mark - WYRichTextDelegate

- (void)wy_didClickRichText:(NSString *)richText range:(NSRange)range index:(NSInteger)index {
    
    //WYLog(@"string = %@, range = %@, index = %ld", richText, NSStringFromRange(range), (long)index);
    //[WYActivity showInfo:[NSString stringWithFormat:@"string = %@, range = %@, index = %ld", richText, NSStringFromRange(range), (long)index] inView:self.view position:WYActivityPositionMiddle];
    if ([richText isEqualToString:@"必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。"]) {
        [WYActivity showScrollInfo:@"必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。"];
    }
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
