//
//  WYTestTextViewCell.h
//  ObjCVerify
//
//  Created by guanren on 2026/5/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WYTestTextViewCell : UITableViewCell

- (void)reloadWithClickEffectColor:(nullable UIColor *)clickEffectColor
                longPressEffectColor:(nullable UIColor *)longPressEffectColor
              overlaysOriginalBackground:(BOOL)overlaysOriginalBackground
          longPressMinimumDuration:(NSTimeInterval)longPressMinimumDuration
                  eventPenetration:(BOOL)eventPenetration
                     useCustomFont:(BOOL)useCustomFont randomText:(BOOL)randomText;

@end

NS_ASSUME_NONNULL_END
