//
//  WYScrollViewObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/20.
//

import UIKit
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

@objc public extension UIScrollView {

    /// 手指是否正在拖动(按下并产生位移时为true，松手进入惯性阶段后为false)
    @objc(wy_isFingerDragging)
    var wy_isFingerDraggingObjC: Bool {
        return wy_isFingerDragging
    }

    /// 是否为用户触发的滑动(包含手指拖动和松手后的惯性滑动；不包含setContentOffset、scrollToTop、自动轮播等代码触发的滑动)
    @objc(wy_isUserSliding)
    var wy_isUserSlidingObjC: Bool {
        return wy_isUserSliding
    }

    /// 当前滑动来源(优先级为手指拖动或跟踪中→user，惯性减速中→deceleration，其余含代码滑动和完全静止→none；只需简单判断是否用户滑动时直接用wy_isUserSliding)
    @objc(wy_slidingSource)
    var wy_slidingSourceObjC: WYSlidingSource {
        return wy_slidingSource
    }

    /// 是否处于回弹(bounce)状态(仅在对应方向contentSize大于可视区域时才判断，避免内容不足时误判)
    @objc(wy_isReboundState)
    var wy_isReboundStateObjC: Bool {
        return wy_isReboundState
    }
    
    /**
     *  当前手指滑动方向(以block属性桥接带参方法，OC侧点语法调用scrollView.wy_slidingDirectionWithThreshold(0.5)，不传阈值时传0.5即可走默认)
     *
     *  通过对比本次与上一次的 contentOffset 计算位移方向，方向以手指滑动为准而非内容移动方向
     *  deltaX > 0（内容右移）→ 手指左滑 → .left；deltaX < 0（内容左移）→ 手指右滑 → .right；
     *  deltaY > 0（内容下移）→ 手指上滑 → .up；deltaY < 0（内容上移）→ 手指下滑 → .down
     *
     *  建议在 scrollViewDidScroll 中持续调用以获得实时结果
     *
     *  @param threshold 位移阈值，用于过滤轻微抖动，传0.5为默认值
     *  @return 当前有效滑动方向；首次调用、位移过小、非用户滑动(setContentOffset等代码触发的偏移跳变)、回弹期间均返回上一次有效方向(从未产生过有效方向则返回 .unknown)
     */
    @objc(wy_slidingDirectionWithThreshold)
    var wy_slidingDirectionObjC: @convention(block) (CGFloat) -> WYSlidingDirection {
        return { [weak self] threshold in
            guard let self = self else { return .unknown }
            return self.wy_slidingDirection(threshold: threshold)
        }
    }
}
