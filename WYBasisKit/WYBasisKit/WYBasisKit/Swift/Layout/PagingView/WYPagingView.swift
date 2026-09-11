//
//  WYPagingView.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/7.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

/// delegate回调
@objc public protocol WYPagingViewDelegate {

    /**
     * Controller页面(Item)切换回调(用户切页与数据源重载落位后都会触发，重载落位回同一页时isFirstDisplayed为false，业务可在回调里对比当前页关联的数据ID决定是否刷新)
     *
     * @param pagingView        当前WYPagingView的实例对象
     * @param pagingIndex       当前Controller在WYPagingView中的页面下标
     * @param isFirstDisplayed       当前Controller是否是第一次在WYPagingView中显示(可用来判断网络请求或页面UI加载时机，避免初始化WYPagingView时就请求所有的Controller的页面数据或者加载UI)，true表示第一次显示，否则为第二次及以后；Controller实例离开分页栏后再加回会重新按第一次显示处理
     */
    @objc(wy_pagingViewItemDidScroll:pagingIndex:isFirstDisplayed:)
    optional func wy_pagingViewItemDidScroll(_ pagingView: WYPagingView, pagingIndex: Int, isFirstDisplayed: Bool)

    /**
     * PagingView页面布局完成(首次layout与数据源重载都会触发)
     *
     * @param pagingView 当前WYPagingView的实例对象
     * @param pagingIndex 布局完成后落位显示的页面下标
     * @param isReload   本次布局是否由数据源重载引起(首次layout为false，删页/加页/换顺序等重新layout为true)
     */
    @objc(wy_pagingViewLayoutDidCompleted:pagingIndex:isReload:)
    optional func wy_pagingViewLayoutDidCompleted(_ pagingView: WYPagingView, pagingIndex: Int, isReload: Bool)

    /**
     * 点击了当前已选中的页面(可用于"再点当前页回到顶部/刷新"这类交互)
     *
     * @param pagingView 当前WYPagingView的实例对象
     * @param pagingIndex 被点击的页面下标
     */
    @objc(wy_pagingViewItemDidRepeatClick:pagingIndex:)
    optional func wy_pagingViewItemDidRepeatClick(_ pagingView: WYPagingView, pagingIndex: Int)

}

public class WYPagingView: UIView {

    /// 点击或滚动事件代理(也可以通过传入block监听)
    public weak var delegate: WYPagingViewDelegate?

    /**
     * 点击或滚动事件(也可以通过实现代理监听)
     *
     * @param handler 点击或滚动事件的block
     */
    public func itemDidScroll(handler: @escaping ((_ pagingView: WYPagingView, _ pagingIndex: Int, _ isFirstDisplayed: Bool) -> Void)) {
        clickOrScrollHandler = handler
    }

    /**
     * PagingView页面布局完成(也可以通过实现代理监听)
     *
     * @param handler 页面布局完成的block
     */
    public func itemDidLayout(handler: @escaping ((_ pagingView: WYPagingView, _ pagingIndex: Int, _ isReload: Bool) -> Void)) {
        itemDidLayoutHandler = handler
    }

    /**
     * 点击当前已选中页面(也可以通过实现代理监听)
     *
     * @param handler 点击当前已选中页面的block
     */
    public func itemDidRepeatClick(handler: @escaping ((_ pagingView: WYPagingView, _ pagingIndex: Int) -> Void)) {
        repeatClickHandler = handler
    }


    /// 分页栏的高度 默认45
    public var bar_height: CGFloat = UIDevice.wy_screenWidth(45, WYBasisKitConfig.defaultScreenPixels)

    /// 图片和文字显示模式
    public var buttonPosition: WYButtonPosition = .imageLeftTitleRight

    /// 分页栏左起始点距离(第一个标题栏距离屏幕边界的距离) 默认0
    public var bar_originlLeftOffset: CGFloat = 0

    /// 分页栏右起始点距离(最后一个标题栏距离屏幕边界的距离) 默认0
    public var bar_originlRightOffset: CGFloat = 0

    /// item距离分页栏顶部的偏移量，默认nil
    public var bar_itemTopOffset: CGFloat? = nil

    /**
     标题总占宽(含间距、bar_originlLeftOffset与bar_originlRightOffset)小于一屏时是否自动居中，默认false靠左显示，自适应与固定Item宽度均支持

     居中时如果设置了bar_originlLeftOffset/RightOffset，则精确保留bar_originlLeftOffset/RightOffset为两端边距，剩余空间全部均摊到Item之间的间距上

     居中时如果未设置bar_originlLeftOffset/RightOffset，则剩余空间均摊到Item间距和左右两端，两端至少保留bar_autoCenterMinSideSpacing，单个标题时会落在分页栏中间
     */
    public var bar_autoCenter: Bool = false

    /// 居中且未设置bar_originlLeftOffset与bar_originlRightOffset时，左右两端参与均摊的基础保留间距，默认0(两端基础边距与Item间距一起均摊剩余空间，设置bar_originlLeftOffset/RightOffset后本属性不再参与)
    public var bar_autoCenterMinSideSpacing: CGFloat = 0

    /// 左右分页栏之间的间距，默认20像素
    public var bar_dividingOffset: CGFloat = UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels)

    /// 内部按钮图片和文字的上下或左右间距 默认5
    public var barButton_dividingOffset: CGFloat = UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels)

    /// 分页控制器底部背景色(即分页控制器所在的scrollView的背景色) 默认白色
    public var bar_pagingContro_content_color: UIColor = .white

    /// 分页控制器背景色
    public var bar_pagingContro_bg_color: UIColor? = nil

    /// 分页控制器内容区是否需要弹跳效果
    public var bar_pagingContro_bounce: Bool = true
    
    /// 分页栏是否需要弹跳效果
    public var bar_bounce: Bool = true

    /// 分页栏默认背景色 默认白色
    public var bar_bg_defaultColor: UIColor = .white

    /// 分页栏Item宽度 默认对应每页标题文本宽度(若传入则整体使用传入宽度)
    public var bar_item_width: CGFloat = 0

    /// 分页栏Item高度 默认bar_height-bar_dividingStripHeight(若传入则整体使用传入高度)
    public var bar_item_height: CGFloat = 0

    /// 分页栏Item按钮内边距，默认.zero(如果bar_item_width和bar_item_height没传入的话，内部会智能调整)
    public var bar_item_insideMargins: UIEdgeInsets = .zero

    /// 分页栏Item按钮内部imageView大小Size，默认.zero(图片本身Size)，仅图文混排时生效，只有图片时可通过bar_item_insideMargins来控制其Size
    public var bar_item_imageViewSize: CGSize = .zero

    /// 分页栏Item图片显示模式，默认.scaleAspectFit(等比缩放完整显示，可改.scaleAspectFill裁剪填满/.scaleToFill拉伸填满等)
    public var bar_item_imageContentMode: UIView.ContentMode = .scaleAspectFit

    /// 分页栏item圆角半径, 默认0
    public var bar_item_cornerRadius: CGFloat = 0

    /// 分页栏item边框宽度, 默认0
    public var bar_item_borderWidth: CGFloat = 0

    /// 分页栏item Normal状态 边框颜色
    public var bar_item_normalBorderColor: UIColor?

    /// 分页栏item Selected状态 边框颜色
    public var bar_item_selectedBorderColor: UIColor?

    /// 分页栏item Normal状态 背景色 默认透明
    public var bar_item_bg_defaultColor: UIColor = .clear

    /// 分页栏item Selected状态 背景色 默认透明
    public var bar_item_bg_selectedColor: UIColor = .clear

    /// 分页栏标题 Normal状态 颜色 默认<#7B809E>
    public var bar_title_defaultColor: UIColor = .wy_hex("#7B809E")

    /// 分页栏标题 Selected状态 颜色 默认<#2D3952>
    public var bar_title_selectedColor: UIColor = .wy_hex("#2D3952")

    /// 分页栏底部分隔带背景色 默认<#F2F2F2>
    public var bar_dividingStripColor: UIColor = .wy_hex("#F2F2F2")

    /// 分页栏底部分隔带背景图 默认为空
    public var bar_dividingStripImage: UIImage? = nil

    /// 滑动线条背景色 默认<#2D3952>
    public var bar_scrollLineColor: UIColor = .wy_hex("#2D3952")

    /// 滑动线条背景图 默认为空
    public var bar_scrollLineImage: UIImage? = nil

    /// 滑动线条宽度 默认0(如传入的数值大于0，则使用传入的宽度，否则宽度会按照分页栏Item宽度来显示)
    public var bar_scrollLineWidth: CGFloat = 0

    /// 滑动线条距离分页栏底部的距离 默认0
    public var bar_scrollLineBottomOffset: CGFloat = 0

    /// 分隔带高度 默认2像素
    public var bar_dividingStripHeight: CGFloat = UIDevice.wy_screenWidth(2, WYBasisKitConfig.defaultScreenPixels)

    /// 滑动线条高度 默认2像素
    public var bar_scrollLineHeight: CGFloat = UIDevice.wy_screenWidth(2, WYBasisKitConfig.defaultScreenPixels)

    /// 滑动线条圆角半径，默认0(无圆角，想让线条两端呈半圆可传线条高度的一半)
    public var bar_scrollLineCornerRadius: CGFloat = 0

    /// 分页栏标题 Normal状态 字号 默认15号；
    public var bar_title_defaultFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))

    /// 分页栏标题 Selected状态 字号 默认15号；
    public var bar_title_selectedFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))

    /// 标题选中时的缩放系数，默认1(不缩放，大于1放大如1.2，小于1缩小，需大于0否则按1处理)
    public var bar_title_selectedScale: CGFloat = 1

    /// 当前选中的页面的Index，初始化时也可以用来设置默认选中第几个页面
    public var bar_selectedIndex: Int = 0

    /// 控制器是否需要左右滑动(默认支持)
    public var canScrollController: Bool = true

    /// 分页栏是否需要左右滑动(默认支持)
    public var canScrollBar: Bool = true

    /// 滑动线条是否需要支持跟随手指滑动(默认true)
    public var bar_scrollLineFollowFinger: Bool = true

    /// 相隔超过一页切换时内容是否依次滑动经过中间页(默认false直接落位仅指示线动画，相邻页切换没有中间页不受影响始终滑动)
    public var slideThroughIntermediatePages: Bool = false

    /// 传入的控制器数组
    public private(set) var controllers: [UIViewController] = []

    /// 传入的标题数组
    public private(set) var titles: [String] = []

    /// 传入的未选中的图片数组
    public private(set) var defaultImages: [UIImage] = []

    /// 传入的选中的图片数组
    public private(set) var selectedImages: [UIImage] = []

    /// 按钮栏所有按钮组件(库外只读，拆分到PrivateImpl的内部文件需要写入)
    public internal(set) var buttonItems: [WYPagingItem] = []

    /// 传入的父控制器
    public private(set) weak var superController: UIViewController?

    /**
     * 调用后开始布局(已布局的实例再次调用即为动态更新页面)
     *
     * @param controllers 控制器数组
     * @param titles 标题数组(传入时数量需与controllers一致)
     * @param defaultImages 未选中状态图片数组(可不传，传入时数量需与controllers一致)
     * @param selectedImages 选中状态图片数组(可不传，传入时数量需与controllers一致)
     * @param superViewController 父控制器
     */
    public func layout(controllers: [UIViewController], titles: [String] = [], defaultImages: [UIImage] = [], selectedImages: [UIImage] = [], superViewController: UIViewController) {

        // 防同步移除旧内容与异步重建之间出现一帧空白(动态修改title数量时会看到闪空，连续快速调用layout时还会因跳过清理而重复添加子视图):移除要与重建放进同一个主线程任务里
        Task { @MainActor in

            if !self.buttonItems.isEmpty || !self.controllers.isEmpty {
                // 移除所有子控件
                removeAllSubviewsAndReset()
            }

            self.isUserInteractionEnabled = true

            guard controllers.isEmpty == false else {
                fatalError("❌ 错误：传入的controllers为空")
            }

            // 防数量不匹配在布局循环里越界崩溃:标题/图片数组要么不传(视为空)，要么数量必须与controllers一致
            if (titles.isEmpty == false) && (titles.count != controllers.count) {
                fatalError("❌ 错误：传入的titles数量(\(titles.count))与controllers数量(\(controllers.count))不一致")
            }

            if (defaultImages.isEmpty == false) && (defaultImages.count != controllers.count) {
                fatalError("❌ 错误：传入的defaultImages数量(\(defaultImages.count))与controllers数量(\(controllers.count))不一致")
            }

            if (selectedImages.isEmpty == false) && (selectedImages.count != controllers.count) {
                fatalError("❌ 错误：传入的selectedImages数量(\(selectedImages.count))与controllers数量(\(controllers.count))不一致")
            }

            // 防标题与图片都为空时Item没有内容可显示:不提前拦截会在构建时报晦涩的"不支持的显示类型"
            if titles.isEmpty && defaultImages.isEmpty {
                fatalError("❌ 错误：titles与defaultImages不能都为空(至少传入一个，且数量与controllers一致)")
            }

            // 防离开分页栏的页残留"已显示过"标记(删掉再加回同一个控制器实例时isFirstDisplayed会误报false):被移出的实例在这里复位标记，重新进入分页栏时按第一次显示处理
            self.controllers.filter { controllers.contains($0) == false }.forEach { $0.wy_pageControllerIsLastDisplayed = false }

            self.controllers = controllers
            self.titles = titles
            self.defaultImages = defaultImages
            self.selectedImages = selectedImages
            self.superController = superViewController

            // 防动态修改title数量或顺序后选中的页错位:当前页还在新数组里时按控制器实例找回它的新位置，当前页被删掉时默认回第0页(调用方重设过bar_selectedIndex时不会记录实例，直接走下标)
            if let preservedController = self.preservedController {
                self.bar_selectedIndex = controllers.firstIndex(of: preservedController) ?? 0
            }
            self.preservedController = nil

            // 防bar_selectedIndex越界导致currentButtonItem未被赋值而崩溃(越界时收敛到新数量的最后一页)
            if (self.bar_selectedIndex > controllers.count - 1) { self.bar_selectedIndex = controllers.count - 1 }
            if (self.bar_selectedIndex < 0) { self.bar_selectedIndex = 0 }

            // 自动高度要扣除栏底部的全部装饰(分隔带与滑动线条取占位大者)，且上次自动算出的值要允许随装饰值变化重新推导
            let bottomDecorations: CGFloat = max(self.bar_dividingStripHeight, self.bar_scrollLineBottomOffset + self.bar_scrollLineHeight)

            if (self.bar_item_height <= 0) || (self.lastAutoItemHeight == self.bar_item_height) {
                self.bar_item_height = max(0, self.bar_height - bottomDecorations)
                self.lastAutoItemHeight = self.bar_item_height
            }

            self.layoutMethod()
        }
    }

    /**
     * 代码切换到指定页面(效果等同点击对应标题)
     *
     * @param index 目标页面下标(越界或等于当前页时不产生任何效果)
     * @param animated 是否带动画切换(相邻页内容滑动切换，相隔超过一页时内容是否依次滑动经过中间页由slideThroughIntermediatePages决定，false恒为内容直切)
     */
    public func switchToPage(at index: Int, animated: Bool = true) {

        // 防越界和切到当前页无意义:直接忽略这次切换
        guard (0..<buttonItems.count).contains(index), index != bar_selectedIndex else { return }

        if animated {
            // 走点击同一条路径(含动画滚动、选中态更新与切页回调)
            buttonItemClick(sender: buttonItems[index])
        } else {
            // 直切:先标记点击滚动防scrollViewDidScroll跟随抢位，再瞬间落位内容与选中态
            isClickScrolling = true
            controllerScrollView.setContentOffset(CGPoint(x: self.frame.size.width * CGFloat(index), y: 0), animated: false)
            isClickScrolling = false
            updateButtonItemProperty(currentItem: buttonItems[index])
        }
    }

    public init() { super.init(frame: .zero) }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override draw(_ rect: CGRect) {
     // Drawing code
     }
     */
}

/// PagingView按钮栏Item
public class WYPagingItem: UIButton {

    /// 标题View
    public var textView: UILabel?

    /// 图片View
    public var iconView: UIImageView?

    /// 内边距
    public private(set) var insideMargins: UIEdgeInsets = .zero

    /// Normal状态文本
    public private(set) var normalText: String?

    /// Selected状态文本
    public private(set) var selectedText: String?

    /// Normal状态图片
    public private(set) var normalImage: UIImage?

    /// Selected状态图片
    public private(set) var selectedImage: UIImage?

    /// Normal状态文本颜色
    public private(set) var normalTextColor: UIColor?

    /// Selected状态文本颜色
    public private(set) var selectedTextColor: UIColor?

    /// Normal状态文本字体
    public private(set) var normalTextFont: UIFont?

    /// Selected状态文本字体
    public private(set) var selectedTextFont: UIFont?

    /// 边框宽度
    public private(set) var borderWidth: CGFloat = 0

    /// 圆角半径
    public private(set) var cornerRadius: CGFloat = 0

    /// Normal状态边框颜色
    public private(set) var normalBorderColor: UIColor?

    /// Selected状态边框颜色
    public private(set) var selectedBorderColor: UIColor?

    /// Normal状态背景色
    public private(set) var normalBackgroundColor: UIColor = .clear

    /// Selected状态背景色
    public private(set) var selectedBackgroundColor: UIColor = .clear

    /**
     *  唯一初始化方法
     *  @param insideMargins           按钮内边距
     *  @param normalImage             按钮Normal状态图片
     *  @param selectedImage           按钮Selected状态图片
     *  @param imageViewSize           按钮图片ViewSize
     *  @param normalText              按钮Normal状态文本
     *  @param selectedText            按钮Selected状态文本
     *  @param normalTextColor         按钮Normal状态文本颜色
     *  @param selectedTextColor       按钮Selected状态文本颜色
     *  @param normalTextFont          按钮Normal状态文本字体字号
     *  @param selectedTextFont        按钮Selected状态文本字体字号
     *  @param buttonPosition          图片和文字显示模式
     *  @param dividingOffset          按钮内部图片和文字的上下或左右间距
     *  @param itemWidth               外部指定的Item固定宽度（0表示自适应）
     *  @param itemHeight              外部指定的Item固定高度（0表示自适应）
     *  @param borderWidth             边框宽度
     *  @param cornerRadius            圆角半径
     *  @param normalBorderColor       Normal状态边框颜色
     *  @param selectedBorderColor     Selected状态边框颜色
     *  @param normalBackgroundColor   Normal状态背景色
     *  @param selectedBackgroundColor Selected状态背景色
     */
    public init(insideMargins: UIEdgeInsets,
                normalImage: UIImage?,
                selectedImage: UIImage?,
                imageViewSize: CGSize,
                normalText: String?,
                selectedText: String?,
                normalTextColor: UIColor,
                selectedTextColor: UIColor,
                normalTextFont: UIFont,
                selectedTextFont: UIFont,
                buttonPosition: WYButtonPosition,
                dividingOffset: CGFloat,
                itemWidth: CGFloat = 0,
                itemHeight: CGFloat = 0,
                borderWidth: CGFloat = 0,
                cornerRadius: CGFloat = 0,
                normalBorderColor: UIColor?,
                selectedBorderColor: UIColor?,
                normalBackgroundColor: UIColor,
                selectedBackgroundColor: UIColor) {

        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.isUserInteractionEnabled = true

        // 保存状态数据
        self.normalText = normalText
        self.selectedText = selectedText
        self.normalImage = normalImage
        self.selectedImage = selectedImage
        self.normalTextColor = normalTextColor
        self.selectedTextColor = selectedTextColor
        self.normalTextFont = normalTextFont
        self.selectedTextFont = selectedTextFont
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.normalBorderColor = normalBorderColor
        self.selectedBorderColor = selectedBorderColor
        self.normalBackgroundColor = normalBackgroundColor
        self.selectedBackgroundColor = selectedBackgroundColor
        self.contentPosition = buttonPosition
        self.contentDividingOffset = dividingOffset
        self.contentImageViewSize = imageViewSize

        if cornerRadius > 0 {
            self.wy_rectCorner(.allCorners).wy_cornerRadius(cornerRadius)
        }

        if let borderColor = normalBorderColor, borderWidth > 0 {
            self.wy_borderWidth(borderWidth).wy_borderColor(borderColor)
        }

        // 设置默认背景色
        self.backgroundColor = normalBackgroundColor

        // 创建内容布局并取得最终内边距(智能边距/图文排布/尺寸下限约束，实现在PrivateImpl的WYPagingItem+Layout)
        self.insideMargins = setupContentLayout(insideMargins: insideMargins, itemWidth: itemWidth, itemHeight: itemHeight)

        // 外部强制固定尺寸
        if itemWidth > 0 {
            widthAnchor.constraint(equalToConstant: itemWidth).isActive = true
        }
        if itemHeight > 0 {
            heightAnchor.constraint(equalToConstant: itemHeight).isActive = true
        }
    }

    /// 设置WYPagingItem的选中状态
    public func setIsSelected(_ isSelected: Bool) {
        self.isSelected = isSelected

        // 切换图片
        if let iconView = iconView {
            iconView.image = isSelected ? selectedImage : normalImage
        }

        // 切换文本、颜色、字体
        if let textView = textView {
            textView.text = isSelected ? selectedText : normalText
            textView.textColor = isSelected ? selectedTextColor : normalTextColor
            textView.font = isSelected ? selectedTextFont : normalTextFont
        }

        // 切换边框颜色(圆角与边框互相独立，只设圆角没边框时圆角也要正常渲染)
        if cornerRadius > 0 {
            self.wy_rectCorner(.allCorners)
                .wy_cornerRadius(cornerRadius)
        }

        if borderWidth > 0, let borderColor = isSelected ? selectedBorderColor : normalBorderColor {
            self.wy_borderWidth(borderWidth)
                .wy_borderColor(borderColor)
        }

        // 切换背景色
        backgroundColor = isSelected ? selectedBackgroundColor : normalBackgroundColor

        // 字体随选中状态切换后按当前字号重新测量图文内容大小(两种字号不同时Item宽度精确跟随)
        updateTextContentSize()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
