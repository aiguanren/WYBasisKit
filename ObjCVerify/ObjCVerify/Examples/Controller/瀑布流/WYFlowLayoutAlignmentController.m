//
//  WYFlowLayoutAlignmentController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/12.
//

#import "WYFlowLayoutAlignmentController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

// MARK: - CollectionReusableHeaderView
@interface CollectionReusableHeaderView : UICollectionReusableView

@end

@implementation CollectionReusableHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

@end

// MARK: - CollectionReusableFooterView
@interface CollectionReusableFooterView : UICollectionReusableView

@end

@implementation CollectionReusableFooterView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

@end

// MARK: - WidthAndHeightEqualCell
@interface WidthAndHeightEqualCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *textView;

@end

@implementation WidthAndHeightEqualCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor wy_random];
        
        self.textView = [[UILabel alloc] init];
        self.textView.font = [UIFont systemFontOfSize:15];
        self.textView.textColor = [UIColor whiteColor];
        self.textView.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.textView];
        [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];
    }
    return self;
}

@end

@interface WYFlowLayoutAlignmentController ()  <UICollectionViewDelegate, UICollectionViewDataSource, WYCollectionViewFlowLayoutDelegate>

@property (nonatomic, assign) BOOL isPagingEnabled;
@property (nonatomic, strong) NSArray<NSString *> *headerSource;
@property (nonatomic, strong) UICollectionView *horizontal;
@property (nonatomic, strong) UICollectionView *vertical;

@end

@implementation WYFlowLayoutAlignmentController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.isPagingEnabled = NO;
    self.headerSource = @[@"宽高相等"];
    
    self.horizontal.backgroundColor = [UIColor wy_random];
    self.vertical.backgroundColor = [UIColor wy_random];
}

- (UICollectionView *)horizontal {
    if (!_horizontal) {
        WYCollectionViewFlowLayout *flowLayout = [[WYCollectionViewFlowLayout alloc] init];
        flowLayout.delegate = self;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _horizontal = [UICollectionView wy_sharedWithFrame:CGRectZero flowLayout:flowLayout delegate:self dataSource:self backgroundColor:[UIColor whiteColor] superView:self.view];
        
        [_horizontal wy_register:WidthAndHeightEqualCell.class style:WYCollectionViewRegisterStyleCell];
        [_horizontal wy_register:CollectionReusableHeaderView.class style:WYCollectionViewRegisterStyleHeaderView];
        [_horizontal wy_register:CollectionReusableFooterView.class style:WYCollectionViewRegisterStyleFooterView];
        _horizontal.pagingEnabled = self.isPagingEnabled;
        [_horizontal mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view);
            make.top.equalTo(self.view).offset([UIDevice wy_navViewHeight]);
            make.height.equalTo(@([UIDevice wy_screenWidth:235]));
        }];
    }
    return _horizontal;
}

- (UICollectionView *)vertical {
    if (!_vertical) {
        
        _vertical = [UICollectionView wy_sharedWithFrame:CGRectZero flowLayout:[[WYCollectionViewFlowLayout alloc] initWithDelegate:self] delegate:self dataSource:self backgroundColor:[UIColor whiteColor] superView:self.view];
        
        [_vertical wy_register:WidthAndHeightEqualCell.class style:WYCollectionViewRegisterStyleCell];
        [_vertical wy_register:CollectionReusableHeaderView.class style:WYCollectionViewRegisterStyleHeaderView];
        [_vertical wy_register:CollectionReusableFooterView.class style:WYCollectionViewRegisterStyleFooterView];
        
        _vertical.pagingEnabled = self.isPagingEnabled;
        [_vertical mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self.view);
            make.top.equalTo(self.view).offset([UIDevice wy_navViewHeight] + [UIDevice wy_screenWidth:235]);
        }];
    }
    return _vertical;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 5;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
//    return 80;
    return [WYIntObjC wy_randomWithMinimum:1 maximum:129];
//    return 9;
//    return 169;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    WidthAndHeightEqualCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WidthAndHeightEqualCell" forIndexPath:indexPath];
    cell.textView.text = [NSString stringWithFormat:@"%ld", (long)indexPath.item + 1];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = ([kind isEqualToString:UICollectionElementKindSectionHeader]) ? @"CollectionReusableHeaderView" : @"CollectionReusableFooterView";
    return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:identifier forIndexPath:indexPath];
}

#pragma mark - WYCollectionViewFlowLayoutDelegate

- (CGSize)wy_collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath * _Nonnull)indexPath {
    
    if (collectionView == self.vertical) {
        WYFlowLayoutAlignment alignment = [self wy_collectionView:collectionView layout:collectionViewLayout flowLayoutAlignmentForSection:indexPath.section];
        if (alignment == WYFlowLayoutAlignmentDefault) {
            if (collectionView.pagingEnabled) {
                return CGSizeMake(35, 35);
            } else {
                // 因为设置header悬浮后，collectionView滑动时内部会不断进行刷新，所以这里不能写随机size，否则会出现刷新抖动情况
                BOOL hover = [self wy_collectionView:collectionView layout:collectionViewLayout hoverForHeaderForSection:indexPath.section];
                if (hover) {
                    return CGSizeMake(35, indexPath.row + 10);
                } else {
                    return CGSizeMake(35, [WYIntObjC wy_randomWithMinimum:35 maximum:135]);
                }
            }
        } else {
            if (collectionView.pagingEnabled) {
                return CGSizeMake(35, 35);
            }
            
            NSString *testString = [NSString wy_randomWithMinimux:1 maximum:20];
            UIFont *testFont = [UIFont systemFontOfSize:15];
            CGFloat lineSpacing = 5;
            
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:testString];
            [attributedString wy_lineSpacing:lineSpacing];
            [attributedString wy_fontsOfRanges:@{testFont: testString}];
            
            CGFloat stringWidth = [attributedString wy_calculateWidthWithControlHeight:testFont.lineHeight];
            UIEdgeInsets sectionInsets = [self wy_collectionView:collectionView layout:collectionViewLayout insetForSection:indexPath.section];
            CGFloat maxWidth = collectionView.frame.size.width - sectionInsets.left - sectionInsets.right;
            CGFloat testWidth = (stringWidth > maxWidth) ? maxWidth : stringWidth;
            
            CGFloat testHeight = 35;
            if (stringWidth > maxWidth) {
                NSInteger layoutLine = [self wy_collectionView:collectionView layout:collectionViewLayout itemNumberOfLinesForSection:indexPath.section];
                NSInteger textLine = [attributedString wy_numberOfRowsWithControlWidth:maxWidth];
                
                if (layoutLine == 0) {
                    testHeight = textLine * (testFont.lineHeight + lineSpacing) - lineSpacing;
                } else {
                    testHeight = MIN(layoutLine, textLine) * (testFont.lineHeight + lineSpacing) - lineSpacing;
                }
                testHeight = [attributedString wy_calculateHeightWithControlWidth:maxWidth];
            }
            return CGSizeMake(testWidth, testHeight);
        }
    } else {
        if (collectionView.pagingEnabled) {
            return CGSizeMake(35, 35);
        }
        return CGSizeMake([WYIntObjC wy_randomWithMinimum:35 maximum:135], 35);
    }
}

- (NSInteger)wy_collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout numberOfLinesInSection:(NSInteger)section {
    return 5;
}

- (NSInteger)wy_collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout numberOfColumnsInSection:(NSInteger)section {
    return 8;
}

- (CGFloat)wy_collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSection:(NSInteger)section {
    return 10;
}

- (CGFloat)wy_collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSection:(NSInteger)section {
    return 10;
}

- (NSInteger)wy_collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout itemNumberOfLinesForSection:(NSInteger)section {
    return 3;
}

- (UIEdgeInsets)wy_collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSection:(NSInteger)section {
    return UIEdgeInsetsMake(10, 10, 10, 10);
    //return UIEdgeInsetsMake(15 + (section * 5), 15 + (section * 5), 15 + (section * 5), 15 + (section * 5));
}

- (enum WYFlowLayoutAlignment)wy_collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout flowLayoutAlignmentForSection:(NSInteger)section {
    return WYFlowLayoutAlignmentDefault;
}

- (BOOL)wy_collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout horizontalScrollItemArrangementDirectionForSection:(NSInteger)section {
    return YES;
}

- (BOOL)wy_collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout hoverForHeaderForSection:(NSInteger)section {
    WYFlowLayoutAlignment alignment = [self wy_collectionView:collectionView layout:collectionViewLayout flowLayoutAlignmentForSection:section];
    if (alignment != WYFlowLayoutAlignmentDefault) {
        return NO;
    }
    return YES;
}

- (CGFloat)wy_collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout spacingBetweenHeaderAndLastPartitionFooter:(NSInteger)section {
    return section * 10;
}

- (CGSize)wy_collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (collectionView.pagingEnabled || collectionView == self.horizontal) {
        return CGSizeZero;
    }
    return CGSizeMake([UIDevice wy_screenWidth], 50);
}

- (CGSize)wy_collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (collectionView.pagingEnabled || collectionView == self.horizontal) {
        return CGSizeZero;
    }
    return CGSizeMake([UIDevice wy_screenWidth], 50);
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    WYLog(@"是否为用户在滑动: %@", scrollView.wy_isUserSliding ? @"YES" : @"NO");
    WYLog(@"当前滑动方向: %ld", scrollView.wy_slidingDirection);
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
