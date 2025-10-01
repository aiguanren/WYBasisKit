//
//  WYLeftControllerHeaderView.m
//  ObjCVerify
//
//  Created by guanren on 2025/10/1.
//

#import "WYLeftControllerHeaderView.h"
#import <Masonry/Masonry.h>

@interface WYLeftControllerHeaderView()

@property (nonatomic, strong) UILabel *titleView;

@end

@implementation WYLeftControllerHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    _titleView = [[UILabel alloc] init];
    [self.contentView addSubview:_titleView];
    
    [_titleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
