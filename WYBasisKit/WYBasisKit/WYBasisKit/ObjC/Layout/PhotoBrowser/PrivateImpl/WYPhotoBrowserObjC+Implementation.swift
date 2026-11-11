//
//  WYPhotoBrowserObjC+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

#if canImport(WYBasisKitSwift)
import UIKit
import WYBasisKitSwift

/// 图片浏览器配置转换
extension WYPhotoBrowserObjC {
    /// 桥接配置转Swift配置(nil项保留Swift默认值)
    @nonobjc static func convertConfiguration(_ bridgeConfiguration: WYPhotoBrowserConfigurationObjC?) -> WYPhotoBrowserConfiguration {
        var configuration = WYPhotoBrowserConfiguration()
        if let bridgeConfiguration = bridgeConfiguration {
            configuration.scrollDirection = bridgeConfiguration.scrollDirection
            configuration.layoutStyle = bridgeConfiguration.layoutStyle
            configuration.stackedCardContentMode = bridgeConfiguration.stackedCardContentMode
            configuration.stackedCardCornerRadius = bridgeConfiguration.stackedCardCornerRadius
            configuration.stackedCardDragRotationAngle = bridgeConfiguration.stackedCardDragRotationAngle
            configuration.stackedCardRotationAngle = bridgeConfiguration.stackedCardRotationAngle
            configuration.stackedCardOffset = bridgeConfiguration.stackedCardOffset
            configuration.stackedCardCount = bridgeConfiguration.stackedCardCount
            configuration.isEmbedded = bridgeConfiguration.isEmbedded
            if bridgeConfiguration.multiPageRevealWidth >= 0 { configuration.multiPageRevealWidth = bridgeConfiguration.multiPageRevealWidth }
            if bridgeConfiguration.multiPageSpacing >= 0 { configuration.multiPageSpacing = bridgeConfiguration.multiPageSpacing }
            configuration.transformStyle = bridgeConfiguration.transformStyle
            configuration.transitionStyle = bridgeConfiguration.transitionStyle
            configuration.pageIndicatorStyle = bridgeConfiguration.pageIndicatorStyle
            configuration.originalLoadStyle = bridgeConfiguration.originalLoadStyle
            if bridgeConfiguration.doubleTapZoomScale > 0 { configuration.doubleTapZoomScale = bridgeConfiguration.doubleTapZoomScale }
            if bridgeConfiguration.maxZoomScale > 0 { configuration.maxZoomScale = bridgeConfiguration.maxZoomScale }
            configuration.allowsTapDismiss = bridgeConfiguration.allowsTapDismiss
            configuration.allowsDragDismiss = bridgeConfiguration.allowsDragDismiss
            if bridgeConfiguration.dragDismissThreshold > 0 { configuration.dragDismissThreshold = bridgeConfiguration.dragDismissThreshold }
            configuration.showsSaveAction = bridgeConfiguration.showsSaveAction
            if let customActions = bridgeConfiguration.customActions, customActions.isEmpty == false { configuration.customActions = customActions }
            if bridgeConfiguration.prefetchCount >= 0 { configuration.prefetchCount = bridgeConfiguration.prefetchCount }
            configuration.allowsLoopScrolling = bridgeConfiguration.allowsLoopScrolling
            if bridgeConfiguration.autoCarouselInterval > 0 { configuration.autoCarouselInterval = bridgeConfiguration.autoCarouselInterval }
            if let bridgeAppearance = bridgeConfiguration.appearance {
                var appearance = WYPhotoBrowserAppearance()
                if let color = bridgeAppearance.backgroundColor { appearance.backgroundColor = color }
                if let color = bridgeAppearance.pageIndicatorTextColor { appearance.pageIndicatorTextColor = color }
                if bridgeAppearance.pageIndicatorFontSize >= 0 { appearance.pageIndicatorFontSize = bridgeAppearance.pageIndicatorFontSize }
                if let color = bridgeAppearance.pageIndicatorDotColor { appearance.pageIndicatorDotColor = color }
                if let color = bridgeAppearance.pageIndicatorCurrentDotColor { appearance.pageIndicatorCurrentDotColor = color }
                if let icon = bridgeAppearance.playButtonIcon { appearance.playButtonIcon = icon }
                if let color = bridgeAppearance.playButtonIconColor { appearance.playButtonIconColor = color }
                if let color = bridgeAppearance.playButtonBackgroundColor { appearance.playButtonBackgroundColor = color }
                if let color = bridgeAppearance.livePhotoBadgeBackgroundColor { appearance.livePhotoBadgeBackgroundColor = color }
                if let color = bridgeAppearance.livePhotoBadgeTextColor { appearance.livePhotoBadgeTextColor = color }
                if bridgeAppearance.livePhotoBadgeFontSize >= 0 { appearance.livePhotoBadgeFontSize = bridgeAppearance.livePhotoBadgeFontSize }
                if let color = bridgeAppearance.progressRingColor { appearance.progressRingColor = color }
                if let color = bridgeAppearance.progressRingTrackColor { appearance.progressRingTrackColor = color }
                if let color = bridgeAppearance.progressLabelColor { appearance.progressLabelColor = color }
                if bridgeAppearance.progressLabelFontSize >= 0 { appearance.progressLabelFontSize = bridgeAppearance.progressLabelFontSize }
                if let color = bridgeAppearance.retryButtonBackgroundColor { appearance.retryButtonBackgroundColor = color }
                if let color = bridgeAppearance.retryButtonTextColor { appearance.retryButtonTextColor = color }
                if bridgeAppearance.retryButtonFontSize >= 0 { appearance.retryButtonFontSize = bridgeAppearance.retryButtonFontSize }
                if let color = bridgeAppearance.originalButtonBackgroundColor { appearance.originalButtonBackgroundColor = color }
                if let color = bridgeAppearance.originalButtonTextColor { appearance.originalButtonTextColor = color }
                if bridgeAppearance.originalButtonFontSize >= 0 { appearance.originalButtonFontSize = bridgeAppearance.originalButtonFontSize }
                if let color = bridgeAppearance.menuBackgroundColor { appearance.menuBackgroundColor = color }
                if let color = bridgeAppearance.menuTextColor { appearance.menuTextColor = color }
                if bridgeAppearance.menuFontSize >= 0 { appearance.menuFontSize = bridgeAppearance.menuFontSize }
                if let color = bridgeAppearance.menuHighlightBackgroundColor { appearance.menuHighlightBackgroundColor = color }
                if bridgeAppearance.menuCornerRadius >= 0 { appearance.menuCornerRadius = bridgeAppearance.menuCornerRadius }
                if let toast = bridgeAppearance.toastConfig { appearance.toastConfig = WYMessageInfoConfig(backgroundColor: toast.backgroundColor, textColor: toast.textColor, textFont: toast.textFont) }
                configuration.appearance = appearance
            }
        }
        return configuration
    }
}

func wy_photoBrowserBridge(_ value: WYPhotoBrowserConfiguration) -> WYPhotoBrowserConfigurationObjC {
    let result = WYPhotoBrowserConfigurationObjC()
    result.scrollDirection = value.scrollDirection
    result.layoutStyle = value.layoutStyle
    result.isEmbedded = value.isEmbedded
    result.stackedCardCount = value.stackedCardCount
    result.stackedCardOffset = value.stackedCardOffset
    result.stackedCardRotationAngle = value.stackedCardRotationAngle
    result.stackedCardDragRotationAngle = value.stackedCardDragRotationAngle
    result.stackedCardCornerRadius = value.stackedCardCornerRadius
    result.stackedCardContentMode = value.stackedCardContentMode
    result.multiPageRevealWidth = value.multiPageRevealWidth
    result.multiPageSpacing = value.multiPageSpacing
    result.transformStyle = value.transformStyle
    result.transitionStyle = value.transitionStyle
    result.pageIndicatorStyle = value.pageIndicatorStyle
    result.originalLoadStyle = value.originalLoadStyle
    result.doubleTapZoomScale = value.doubleTapZoomScale
    result.maxZoomScale = value.maxZoomScale
    result.allowsTapDismiss = value.allowsTapDismiss
    result.allowsDragDismiss = value.allowsDragDismiss
    result.dragDismissThreshold = value.dragDismissThreshold
    result.showsSaveAction = value.showsSaveAction
    result.customActions = value.customActions
    result.prefetchCount = value.prefetchCount
    result.allowsLoopScrolling = value.allowsLoopScrolling
    result.autoCarouselInterval = value.autoCarouselInterval
    let appearance = WYPhotoBrowserAppearanceObjC()
    appearance.backgroundColor = value.appearance.backgroundColor
    appearance.pageIndicatorTextColor = value.appearance.pageIndicatorTextColor
    appearance.pageIndicatorFontSize = value.appearance.pageIndicatorFontSize
    appearance.pageIndicatorDotColor = value.appearance.pageIndicatorDotColor
    appearance.pageIndicatorCurrentDotColor = value.appearance.pageIndicatorCurrentDotColor
    appearance.playButtonIcon = value.appearance.playButtonIcon
    appearance.playButtonIconColor = value.appearance.playButtonIconColor
    appearance.playButtonBackgroundColor = value.appearance.playButtonBackgroundColor
    appearance.livePhotoBadgeBackgroundColor = value.appearance.livePhotoBadgeBackgroundColor
    appearance.livePhotoBadgeTextColor = value.appearance.livePhotoBadgeTextColor
    appearance.livePhotoBadgeFontSize = value.appearance.livePhotoBadgeFontSize
    appearance.progressRingColor = value.appearance.progressRingColor
    appearance.progressRingTrackColor = value.appearance.progressRingTrackColor
    appearance.progressLabelColor = value.appearance.progressLabelColor
    appearance.progressLabelFontSize = value.appearance.progressLabelFontSize
    appearance.retryButtonBackgroundColor = value.appearance.retryButtonBackgroundColor
    appearance.retryButtonTextColor = value.appearance.retryButtonTextColor
    appearance.retryButtonFontSize = value.appearance.retryButtonFontSize
    appearance.originalButtonBackgroundColor = value.appearance.originalButtonBackgroundColor
    appearance.originalButtonTextColor = value.appearance.originalButtonTextColor
    appearance.originalButtonFontSize = value.appearance.originalButtonFontSize
    appearance.menuBackgroundColor = value.appearance.menuBackgroundColor
    appearance.menuTextColor = value.appearance.menuTextColor
    appearance.menuFontSize = value.appearance.menuFontSize
    appearance.menuHighlightBackgroundColor = value.appearance.menuHighlightBackgroundColor
    appearance.menuCornerRadius = value.appearance.menuCornerRadius
    if let toast = value.appearance.toastConfig { appearance.toastConfig = WYMessageInfoConfigObjC(backgroundColor: toast.backgroundColor, textColor: toast.textColor, textFont: toast.textFont) }
    result.appearance = appearance
    return result
}

#endif
