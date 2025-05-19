//
//  WYChatMoreView.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/4/3.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit
import WYBasisKit

public struct WYMoreViewConfig {
    
    /// 自定义More控件弹起或者收回时动画持续时长
    public var animateDuration: TimeInterval = 0.25
    
    /// 自定义More控件背景色
    public var backgroundColor: UIColor = .wy_hex("#f6f6f6")
    
    /// 自定义More控件滚动方向
    public var scrollDirection: UICollectionView.ScrollDirection = .horizontal
    
    /// 一页就可以显示所有item的时候，是否显示分页指示器(翻页模式开启时才显示分页指示器)
    public var pageControlHideForSingle: Bool = true
    
    /// 是否需要显示分页指示器
    public var showPageControl: Bool = true
    
    /// 分页指示器是否允许用户点击(翻页模式开启时才显示分页指示器)
    public var pageControlUserInteractionEnabled: Bool = true
    
    /// 自定义More控件是否需要翻页模式
    public var isPagingEnabled: Bool = true
    
    /// 自定义More控件数据源
    public var moreSource: [[String: String]] = []

    /// 自定义More控件的Inset
    public var contentInset: UIEdgeInsets = UIEdgeInsets(top: wy_screenWidth(10), left: wy_screenWidth(20), bottom: wy_screenWidth(20), right: wy_screenWidth(20))
    
    /// 自定义More控件内imageView的背景色
    public var imageViewBackgroundColor: UIColor = .white
    
    /// 自定义More控件内imageView的Size
    public var imageViewSize: CGSize = CGSize(width: wy_screenWidth(65), height: wy_screenWidth(60))
    
    /// 自定义More控件内imageView的圆角半径
    public var imageViewCornerRadius: CGFloat = wy_screenWidth(15)
    
    /// 自定义More控件内imageView的背景色
    public var imageBackgroundColor: UIColor = .white
    
    /// 自定义More控件内文本控件的字体、字号
    public var textViewFont: UIFont = .systemFont(ofSize: wy_screenWidth(13))
    
    /// 自定义More控件内文本控件的色值
    public var textColor: UIColor = .wy_hex("#1B1B1B")
    
    /// 自定义More控件内文本控件顶部距离图片控件底部的间距
    public var textTopOffset: CGFloat = wy_screenWidth(10)
    
    /// 自定义More控件内一行显示几个item
    public var itemMaxCountWithLine: NSInteger = 4
    
    /// scrollDirection == vertical时 自定义More控件内每页可以显示几列
    public var itemMaxCountWithColumn: NSInteger = 4
    
    /// 自定义More控件内一页最多显示几行
    public var itemMaxLineWithPage: NSInteger = 2
    
    /// 自定义More控件是否需要按照 itemMaxLineWithPage 来显示高度，false的话高度会自动计算
    public var maxHeightForever: Bool = false
    
    /// 自定义More控件内item的行间距
    public var minimumLineSpacing: CGFloat = wy_screenWidth(16)
    
    /// 分页控件原点位置
    public var pageControlPosition: CGPoint?
    
    public init() {}
}

public extension WYMoreViewConfig {
    
    /// 计算单个item的Size
    func moreItemSize() -> CGSize {
        return CGSize(width: imageViewSize.width, height: imageViewSize.height + textTopOffset + textViewFont.lineHeight)
    }
    
    /// 计算每页需要显示几行item
    func numberOfLinesInPage() -> NSInteger {
        return maxHeightForever ? itemMaxLineWithPage : min(itemMaxLineWithPage, NSInteger(ceil(CGFloat(moreSource.count) / CGFloat(itemMaxCountWithLine))))
    }
    
    /// 计算需要几页才能显示完毕所有Item
    func numberOfPages() -> NSInteger {
        return NSInteger(ceil(CGFloat(moreViewConfig.moreSource.count) / CGFloat((itemMaxLineWithPage * itemMaxCountWithColumn))))
    }
    
    /// 返回一个bool值，判断一页是否能否显示完毕所有的item
    func showTotalItemInPage() -> Bool {
        
        if scrollDirection == .horizontal {
            return moreViewConfig.moreSource.count <= (itemMaxLineWithPage * itemMaxCountWithLine)
            
        }else {
            return moreViewConfig.moreSource.count <= (itemMaxLineWithPage * itemMaxCountWithColumn)
        }
    }
    
    /// 计算自定义more控件高度
    func contentHeight() -> CGFloat {
        
        let lineSpace: CGFloat = (numberOfLinesInPage() > 1) ? (CGFloat((numberOfLinesInPage() - 1)) * minimumLineSpacing) : 0
        
        let moreHeight: CGFloat = contentInset.top + contentInset.bottom + lineSpace + (moreItemSize().height * CGFloat(numberOfLinesInPage()))
        
        return moreHeight
    }
    
    /// 获取默认的分页控制器原点位置
    func defaultPageControlPosition(_ pageControl: UIPageControl) -> CGPoint {
        
        let pageControlSize: CGSize = pageControl.size(forNumberOfPages: pageControl.numberOfPages)
        if scrollDirection == .horizontal {
            return CGPoint(x: (wy_screenWidth - pageControlSize.width) / 2, y: contentHeight() - pageControlSize.height - wy_screenWidth(15))
        }else {
            return CGPoint(x: wy_screenWidth - (pageControlSize.width / 2) - (pageControlSize.height / 2) - wy_screenWidth(15), y: (contentHeight() - pageControlSize.height) / 2)
        }
    }
}

/// 返回一个Bool值来判定各控件的点击或手势事件是否需要内部处理(默认返回True)
@objc public protocol WYMoreViewEventsHandler {
    /// 是否需要内部处理 cell 的点击事件
    @objc optional func canManagerMoreViewClickEvents(_ moreView: WYChatMoreView, _ itemIndex: NSInteger) -> Bool
}

@objc public protocol WYChatMoreViewDelegate {
    
    /// 监控cell点击事件
    @objc optional func didClickMoreViewAt(_ itemIndex: NSInteger)
}

public class WYChatMoreView: UIView {
    
    public weak var eventsHandler: WYMoreViewEventsHandler? = nil
    
    /// 点击事件代理
    public weak var delegate: WYChatMoreViewDelegate?
    
    public lazy var collectionView: UICollectionView = {
        
        let numberOfCountInLine: NSInteger = moreViewConfig.scrollDirection == .horizontal ? moreViewConfig.itemMaxCountWithLine : moreViewConfig.itemMaxCountWithColumn
        
        let minimumInteritemSpacing: CGFloat = (wy_screenWidth - moreViewConfig.contentInset.left - moreViewConfig.contentInset.right - (moreViewConfig.moreItemSize().width * CGFloat(numberOfCountInLine))) / CGFloat(numberOfCountInLine - 1)
        
        let flowLayout: WYCollectionViewFlowLayout = WYCollectionViewFlowLayout(delegate: self)
        flowLayout.itemSize = moreViewConfig.moreItemSize()
        flowLayout.minimumLineSpacing = moreViewConfig.minimumLineSpacing
        flowLayout.minimumInteritemSpacing = minimumInteritemSpacing
        flowLayout.scrollDirection = moreViewConfig.scrollDirection
        
        let collectionView: UICollectionView = UICollectionView.wy_shared(flowLayout: flowLayout, delegate: self, dataSource: self, superView: self)

        collectionView.register(WYMoreViewCell.self, forCellWithReuseIdentifier: "WYMoreViewCell")
        collectionView.isPagingEnabled = moreViewConfig.isPagingEnabled
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return collectionView
    }()
    
    public init() {
        super.init(frame: .zero)
        backgroundColor = moreViewConfig.backgroundColor
        self.collectionView.backgroundColor = moreViewConfig.backgroundColor
        self.pageControl?.backgroundColor = .clear
    }
    
    // 如果放scrollViewDidScroll里面的话，当从右往左滑动的时候就会出现刚一滑动就切换页码的问题
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if moreViewConfig.scrollDirection == .horizontal {
            pageControl?.currentPage = NSInteger(scrollView.contentOffset.x / wy_width)
        }else {
            pageControl?.currentPage = NSInteger(scrollView.contentOffset.y / wy_height)
        }
    }
    
    @objc public func switchCurrentPage(_ sender: UIPageControl) {
        if moreViewConfig.scrollDirection == .horizontal {
            collectionView.setContentOffset(CGPoint(x: CGFloat(sender.currentPage) * wy_width, y: 0), animated: true)
        }else {
            collectionView.setContentOffset(CGPoint(x: 0, y: CGFloat(sender.currentPage) * wy_height), animated: true)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

extension WYChatMoreView: UICollectionViewDelegate, UICollectionViewDataSource, WYCollectionViewFlowLayoutDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return moreViewConfig.moreSource.count
    }
    
    public func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, numberOfLinesIn section: Int) -> Int {
        return moreViewConfig.numberOfLinesInPage()
    }
    
    public func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, numberOfColumnsIn section: NSInteger) -> NSInteger {
        return moreViewConfig.itemMaxCountWithColumn
    }
    
    public func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return moreViewConfig.contentInset
    }
    
    public func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, horizontalScrollItemArrangementDirectionForSectionAt section: Int) -> Bool {
        return true
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: WYMoreViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "WYMoreViewCell", for: indexPath) as! WYMoreViewCell
        
        let itemSource: [String: String] = moreViewConfig.moreSource[indexPath.item]
        cell.iconView.image = UIImage.wy_find(itemSource.values.first ?? "")
        cell.titleView.text = itemSource.keys.first ?? ""
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard (eventsHandler?.canManagerMoreViewClickEvents?(self, indexPath.item) ?? true) else {
            return
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
        delegate?.didClickMoreViewAt?(indexPath.item)
    }
}

public extension WYChatMoreView {
    
    /// 分页控件
    var pageControl: UIPageControl? {
        
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.pageControl, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            guard (moreViewConfig.isPagingEnabled == true) && (moreViewConfig.showPageControl == true) else {
                return nil
            }
            guard let pagecontrol: UIPageControl = objc_getAssociatedObject(self, WYAssociatedKeys.pageControl) as? UIPageControl else {
                
                let pagecontrol = UIPageControl()
                pagecontrol.hidesForSinglePage = moreViewConfig.pageControlHideForSingle
                pagecontrol.isUserInteractionEnabled = moreViewConfig.pageControlUserInteractionEnabled
                pagecontrol.currentPage = 0
                pagecontrol.numberOfPages = moreViewConfig.numberOfPages()
                pagecontrol.addTarget(self, action: #selector(switchCurrentPage(_:)), for: .valueChanged)
                if #available(iOS 14.0, *) {
                    pagecontrol.backgroundStyle = .minimal
                }
                if moreViewConfig.scrollDirection == .vertical {
                    // 围绕中心旋转90度
                    pagecontrol.transform = CGAffineTransform(rotationAngle: Double.pi / 2)
                }
                addSubview(pagecontrol)
                
                objc_setAssociatedObject(self, WYAssociatedKeys.pageControl, pagecontrol, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
                updatePageControlStyle()
                
                let pageControlPosition: CGPoint = (moreViewConfig.pageControlPosition == nil) ? moreViewConfig.defaultPageControlPosition(pagecontrol) : moreViewConfig.pageControlPosition!
                
                pagecontrol.snp.makeConstraints { make in
                    make.left.equalToSuperview().offset(pageControlPosition.x)
                    make.top.equalToSuperview().offset(pageControlPosition.y)
                    make.size.equalTo(pagecontrol.size(forNumberOfPages: pagecontrol.numberOfPages))
                }
                return pagecontrol
            }
            return pagecontrol
        }
    }
    
    /**
     *  设置分页控件指示器的颜色
     *  不设置则为系统默认
     *
     *  @param defaultColor    其他页码的颜色
     *  @param currentColor    当前页码的颜色
     */
    func updatePageControl(defaultColor: UIColor, currentColor: UIColor) {
        pageControlSetting.defaultColor = defaultColor
        pageControlSetting.currentColor = currentColor
        
        DispatchQueue.main.async {
            self.updatePageControlStyle()
        }
    }
    
    /**
     *  设置分页控件指示器的图片
     *  iOS14以前两个图片必须同时设置，否则设置无效，iOS14及以后可以只设置其中一张
     *  不设置则为系统默认
     *
     *  @param defaultImage    其他页码的图片
     *  @param currentImage    当前页码的图片
     */
    func updatePageControl(defaultImage: UIImage? = nil, currentImage: UIImage? = nil) {
        pageControlSetting.currentImage = currentImage
        pageControlSetting.defaultImage = defaultImage
        
        DispatchQueue.main.async {
            self.updatePageControlStyle()
        }
    }
    
    /// 分页控制器设置选项
    private var pageControlSetting: (currentColor: UIColor?, defaultColor: UIColor?, currentImage: UIImage?, defaultImage: UIImage?) {
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.pageControlSetting, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.pageControlSetting) as? (currentColor: UIColor?, defaultColor: UIColor?, currentImage: UIImage?, defaultImage: UIImage?) ?? (currentColor: nil, defaultColor: nil, currentImage: nil, defaultImage: nil)
        }
    }
    
    /// 自定义设置分页控件图片及颜色
    private func updatePageControlStyle() {
        
        if pageControl?.hidesForSinglePage != moreViewConfig.pageControlHideForSingle {
            pageControl?.hidesForSinglePage = moreViewConfig.pageControlHideForSingle
        }
        
        if let defaultColor: UIColor = pageControlSetting.defaultColor {
            pageControl?.pageIndicatorTintColor = defaultColor
            pageControlSetting.defaultColor = nil
        }
        if let currentColor: UIColor = pageControlSetting.currentColor {
            pageControl?.currentPageIndicatorTintColor = currentColor
            pageControlSetting.currentColor = nil
        }
        
        if #available(iOS 14.0, *) {
            if let defaultImage: UIImage = pageControlSetting.defaultImage, let currentImage: UIImage = pageControlSetting.currentImage {
                for page: Int in 0..<(pageControl?.numberOfPages ?? 0) {
                    pageControl?.setIndicatorImage(page == pageControl?.currentPage ? currentImage : defaultImage, forPage: page)
                }
            }else {
                if let defaultImage: UIImage = pageControlSetting.defaultImage {
                    pageControl?.preferredIndicatorImage = defaultImage
                    pageControlSetting.defaultImage = nil
                }
                
                if let currentImage: UIImage = pageControlSetting.currentImage {
                    pageControl?.preferredIndicatorImage = currentImage
                    pageControlSetting.currentImage = nil
                }
            }
            
        }else {
            if let defaultImage: UIImage = pageControlSetting.defaultImage, let currentImage: UIImage = pageControlSetting.currentImage {
                pageControl?.setValue(defaultImage, forKey: "_pageImage")
                pageControl?.setValue(currentImage, forKey: "_currentPageImage")
                pageControlSetting.defaultImage = nil
                pageControlSetting.currentImage = nil
            }
        }
    }
    
    private struct WYAssociatedKeys {
        static let pageControl = UnsafeRawPointer(bitPattern: "pageControl".hashValue)!
        static let pageControlSetting = UnsafeRawPointer(bitPattern: "pageControlSetting".hashValue)!
    }
}
