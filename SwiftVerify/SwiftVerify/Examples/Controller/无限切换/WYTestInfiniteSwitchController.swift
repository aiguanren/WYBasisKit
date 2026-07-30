//
//  WYTestInfiniteSwitchController.swift
//  SwiftVerify
//
//  Created by guanren on 2026/7/20.
//

import UIKit
import SnapKit

class WYTestInfiniteSwitchController: UIViewController {
    
    /// 无限滚动View
    var contentScrollView: WYContentScrollView = WYContentScrollView()
    
    /// 底部操作View
    var operatioView: UIScrollView = UIScrollView()
    
    /**
     *  水平方向内容页视图数量（Int.max表示无限数量）
     *  当设置Int.max时，会强制设置automaticCarousel和unlimitedCarousel为false
     */
    var numberOfHorizontalContent: UISegmentedControl = UISegmentedControl(items: ["0", "1", "2", "3", "4", "5", "∞"])
    
    /**
     *  垂直方向内容页视图数量（Int.max表示无限数量）
     *  当设置Int.max时，会强制设置automaticCarousel和unlimitedCarousel为false
     */
    var numberOfVerticalContent: UISegmentedControl = UISegmentedControl(items: ["0", "1", "2", "3", "4", "5", "∞"])
    
    /// 支持的滑动方向
    var contentSlidingDirection: UISegmentedControl = UISegmentedControl(items: ["左右", "上下", "全向"])
    
    /// 当contentSlidingDirection == .omnidirectional时，优先支持哪个滑动方向，默认左右滑动(不支持设置为.omnidirectional)
    var prioritySlidingDirection: UISegmentedControl = UISegmentedControl(items: ["左右", "上下", "全向"])
    
    /**
     *  自动轮播时每一页停留时间，默认为3s，最少1s
     *  当设置的值小于1s时，则为默认值
     *  contentSlidingDirection == omnidirectional时不会生效，且会强制停止计时器
     */
    var standingTime: UISlider = UISlider()
    var standingTimeValue: UILabel = UILabel()
    
    /// 水平方向只有一张图片时，是否需要支持滑动，默认false
    var horizontalSliderForSinglePage: UISwitch = UISwitch()
    
    /// 垂直方向只有一张图片时，是否需要支持滑动，默认false
    var verticalSliderForSinglePage: UISwitch = UISwitch()
    
    /// 水平方向有多个内容页面时，是否需要支持滑动(contentSlidingDirection == omnidirectional时固定为false)
    var horizontalSliderForMultiPage: UISwitch = UISwitch()
    
    /// 垂直方向有多个内容页面时，是否需要支持滑动(contentSlidingDirection == omnidirectional时固定为false)
    var verticalSliderForMultiPage: UISwitch = UISwitch()
    
    /**
     *  是否需要无限轮播，除contentSlidingDirection == omnidirectional时固定为false外，其余默认开启
     *  当设置false时，会强制设置automaticCarousel为false
     */
    var unlimitedCarousel: UISwitch = UISwitch()
    
    /**
     *  是否需要自动轮播，除contentSlidingDirection == omnidirectional时固定为false外，其余默认开启
     *  当设置false时，会关闭定时器
     */
    var automaticCarousel: UISwitch = UISwitch()
    
    /**
     *  开启或者关闭定时器(不支持contentSlidingDirection == omnidirectional时调用)
     */
    var startOrStopTimer: UISwitch = UISwitch()
    
    /// 切换指定方向下一个内容页面(不支持直接传入direction为omnidirectional)
    var nextContent: UIButton = UIButton(type: .custom)
    var nextContentDirection: UISegmentedControl = UISegmentedControl(items: ["左右", "上下", "全向"])
    
    /// 切换指定方向上一个内容页面(不支持直接传入direction为omnidirectional)
    var lastContent: UIButton = UIButton(type: .custom)
    var lastContentDirection: UISegmentedControl = UISegmentedControl(items: ["左右", "上下", "全向"])
    
    /// 切换到指定方向指定下标处(不支持直接传入direction为omnidirectional)
    var switchContent: UIButton = UIButton(type: .custom)
    var switchContentDirection: UISegmentedControl = UISegmentedControl(items: ["左右", "上下", "全向"])
    var switchContentPicker: UIPickerView = UIPickerView()
    var switchContentIndex: Int = 0
    
    /// 水平方向Contents
    var horizontalViews: [UIView] = []
    
    /// 垂直方向Contents
    var verticalViews: [UIView] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        addSubView()
        configSubView()
    }
    
    func configSubView() {
        
        for _ in 0...1 {
            let horizontal: UIImageView = UIImageView()
            horizontal.backgroundColor = .wy_random
            horizontalViews.append(horizontal)
            
            let vertical: WYMediaPlayer = WYMediaPlayer()
            vertical.backgroundColor = .wy_random
            verticalViews.append(vertical)
        }
        
        contentScrollView.contentDelegate = self
        
        operatioView.showsHorizontalScrollIndicator = false
        operatioView.contentInsetAdjustmentBehavior = .never
        
        numberOfHorizontalContent.selectedSegmentIndex = 6
        segmentedControlChange(sender: numberOfHorizontalContent)
        
        numberOfVerticalContent.selectedSegmentIndex = 6
        segmentedControlChange(sender: numberOfVerticalContent)
        
        contentSlidingDirection.selectedSegmentIndex = 0
        segmentedControlChange(sender: contentSlidingDirection)
        
        prioritySlidingDirection.selectedSegmentIndex = 0
        segmentedControlChange(sender: prioritySlidingDirection)
        
        for segmentedControl in [numberOfHorizontalContent, numberOfVerticalContent, contentSlidingDirection, prioritySlidingDirection, nextContentDirection, lastContentDirection, switchContentDirection] {
            segmentedControl.addTarget(self, action: #selector(segmentedControlChange(sender:)), for: .valueChanged)
        }
        
        standingTime.value = 3
        standingTime.minimumValue = 0
        standingTime.maximumValue = 5
        standingTime.addTarget(self, action: #selector(standingTimeChanged(sender:)), for: .valueChanged)
        
        standingTimeValue.textColor = .black
        standingTimeValue.text = "3.0"
        
        horizontalSliderForSinglePage.isOn = false
        verticalSliderForSinglePage.isOn = false
        horizontalSliderForMultiPage.isOn = true
        verticalSliderForMultiPage.isOn = true
        unlimitedCarousel.isOn = true
        automaticCarousel.isOn = true
        
        for switchView in [horizontalSliderForSinglePage, verticalSliderForSinglePage,horizontalSliderForMultiPage,verticalSliderForMultiPage, unlimitedCarousel, automaticCarousel, startOrStopTimer] {
            switchView.addTarget(self, action: #selector(switchSwitched(sender:)), for: .valueChanged)
            
            if switchView != startOrStopTimer {
                switchSwitched(sender: switchView)
            }
        }
        
        
        for button in [nextContent, lastContent, switchContent] {
            button.setTitleColor(.black, for: .normal)
            button.addTarget(self, action: #selector(buttonClick(sender:)), for: .touchUpInside)
        }
        
        switchContentPicker.delegate = self
        switchContentPicker.dataSource = self
    }
    
    @objc func segmentedControlChange(sender: UISegmentedControl) {
        if sender == numberOfHorizontalContent {
            contentScrollView.numberOfHorizontalContent = [0, 1, 2, 3, 4, 5, Int.max][sender.selectedSegmentIndex]
        }else if sender == numberOfVerticalContent {
            contentScrollView.numberOfVerticalContent = [0, 1, 2, 3, 4, 5, Int.max][sender.selectedSegmentIndex]
        }else if sender == contentSlidingDirection {
            contentScrollView.contentSlidingDirection = [.leftOrRight, .topOrBottom, .omnidirectional][sender.selectedSegmentIndex]
            switch contentScrollView.contentSlidingDirection {
            case .leftOrRight:
                if !contentScrollView.hasHorizontalDisplayView {
                    contentScrollView.horizontalOrVerticalDisplay(currentView: horizontalViews.first!, reserveView: horizontalViews.last!)
                }
                break
            case .topOrBottom:
                if !contentScrollView.hasVerticalDisplayView {
                    contentScrollView.horizontalOrVerticalDisplay(currentView: verticalViews.first!, reserveView: verticalViews.last!)
                }
                break
            case .omnidirectional:
                if !((contentScrollView.hasHorizontalDisplayView) && (contentScrollView.hasVerticalDisplayView)) {
                    contentScrollView.omnidirectionalDisplay(currentHorizontalView: horizontalViews.first!, reserveHorizontalView: horizontalViews.last!, currentVerticalView: verticalViews.first!, reserveVerticalView: verticalViews.last!)
                }
                break
            }
        }else if sender == prioritySlidingDirection {
            contentScrollView.prioritySlidingDirection = [.leftOrRight, .topOrBottom, .omnidirectional][sender.selectedSegmentIndex]
        }
    }
    
    @objc func buttonClick(sender: UIButton) {
        if sender == nextContent {
            contentScrollView.nextContent([.leftOrRight, .topOrBottom, .omnidirectional][nextContentDirection.selectedSegmentIndex])
        }else if sender == lastContent {
            contentScrollView.lastContent([.leftOrRight, .topOrBottom, .omnidirectional][lastContentDirection.selectedSegmentIndex])
        }else if sender == switchContent {
            contentScrollView.switchContent([.leftOrRight, .topOrBottom, .omnidirectional][switchContentDirection.selectedSegmentIndex], index: &switchContentIndex)
        }
    }
    
    @objc func standingTimeChanged(sender: UISlider) {
        standingTime.value = floor(sender.value)
        standingTimeValue.text = "\(standingTime.value)"
        contentScrollView.standingTime = TimeInterval(standingTime.value)
    }
    
    @objc func switchSwitched(sender: UISwitch) {
        if sender == horizontalSliderForSinglePage {
            contentScrollView.horizontalSliderForSinglePage = sender.isOn
        }else if sender == verticalSliderForSinglePage {
            contentScrollView.verticalSliderForSinglePage = sender.isOn
        }else if sender == horizontalSliderForMultiPage {
            contentScrollView.horizontalSliderForMultiPage = sender.isOn
        }else if sender == verticalSliderForMultiPage {
            contentScrollView.verticalSliderForMultiPage = sender.isOn
        }else if sender == unlimitedCarousel {
            contentScrollView.unlimitedCarousel = sender.isOn
        }else if sender == automaticCarousel {
            contentScrollView.automaticCarousel = sender.isOn
        }else if sender == startOrStopTimer {
            if sender.isOn {
                contentScrollView.startTimer()
            }else {
                contentScrollView.stopTimer()
            }
        }
    }
    
    func addSubView() {
        view.addSubview(contentScrollView)
        contentScrollView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(UIDevice.wy_navViewHeight)
        }
        
        view.addSubview(operatioView)
        operatioView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(contentScrollView.snp.bottom)
            make.height.equalTo((UIDevice.wy_screenHeight - UIDevice.wy_navViewHeight - UIDevice.wy_tabbarSafetyZone) / 2)
            make.bottom.equalToSuperview().offset(UIDevice.wy_tabbarSafetyZone)
        }
        
        let numberOfHorizontalContentView: UIView = createDescContentView(desc: "水平方向内容页视图数量（∞：表示无限数量(Int.Max)）", controView: numberOfHorizontalContent)
        operatioView.addSubview(numberOfHorizontalContentView)
        numberOfHorizontalContentView.snp.makeConstraints { make in
            make.width.equalTo(UIDevice.wy_screenWidth - 20)
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
        }
        
        let numberOfVerticalContentView: UIView = createDescContentView(desc: "垂直方向内容页视图数量（∞：表示无限数量(Int.Max)）", controView: numberOfVerticalContent)
        operatioView.addSubview(numberOfVerticalContentView)
        numberOfVerticalContentView.snp.makeConstraints { make in
            make.top.equalTo(numberOfHorizontalContentView.snp.bottom).offset(35)
            make.width.centerX.equalTo(numberOfHorizontalContentView)
        }
        
        let contentSlidingDirectionView: UIView = createDescContentView(desc: "支持的滑动方向", controView: contentSlidingDirection)
        operatioView.addSubview(contentSlidingDirectionView)
        contentSlidingDirectionView.snp.makeConstraints { make in
            make.top.equalTo(numberOfVerticalContentView.snp.bottom).offset(35)
            make.width.centerX.equalTo(numberOfVerticalContentView)
        }
        
        let prioritySlidingDirectionView: UIView = createDescContentView(desc: "当contentSlidingDirection == .omnidirectional时，优先支持哪个滑动方向，默认左右滑动(不支持设置为.omnidirectional)", controView: prioritySlidingDirection)
        operatioView.addSubview(prioritySlidingDirectionView)
        prioritySlidingDirectionView.snp.makeConstraints { make in
            make.top.equalTo(contentSlidingDirectionView.snp.bottom).offset(35)
            make.width.centerX.equalTo(contentSlidingDirectionView)
        }
        
        /**
         *  自动轮播时每一页停留时间，默认为3s，最少1s
         *  当设置的值小于1s时，则为默认值
         *  contentSlidingDirection == omnidirectional时不会生效，且会强制停止计时器
         */
        let standingTimeView: UIView = createDescContentView(desc: "自动轮播时每一页停留时间，默认为3s，最少1s，当设置的值小于1s时，则为默认值，contentSlidingDirection == omnidirectional时不会生效，且会强制停止计时器", controView: standingTime, valueView: standingTimeValue)
        operatioView.addSubview(standingTimeView)
        standingTimeView.snp.makeConstraints { make in
            make.top.equalTo(prioritySlidingDirectionView.snp.bottom).offset(35)
            make.width.centerX.equalTo(prioritySlidingDirectionView)
        }
        
        let horizontalSliderForSinglePageView: UIView = createDescContentView(desc: "水平方向只有一张图片时，是否需要支持滑动，默认false", controView: horizontalSliderForSinglePage)
        operatioView.addSubview(horizontalSliderForSinglePageView)
        horizontalSliderForSinglePageView.snp.makeConstraints { make in
            make.top.equalTo(standingTimeView.snp.bottom).offset(35)
            make.width.centerX.equalTo(standingTimeView)
        }
        
        let verticalSliderForSinglePageView: UIView = createDescContentView(desc: "垂直方向只有一张图片时，是否需要支持滑动，默认false", controView: verticalSliderForSinglePage)
        operatioView.addSubview(verticalSliderForSinglePageView)
        verticalSliderForSinglePageView.snp.makeConstraints { make in
            make.top.equalTo(horizontalSliderForSinglePageView.snp.bottom).offset(35)
            make.width.centerX.equalTo(horizontalSliderForSinglePageView)
        }
        
        let horizontalSliderForMultiPageView: UIView = createDescContentView(desc: "水平方向有多个内容页面时，是否需要支持滑动(contentSlidingDirection == omnidirectional时固定为false)", controView: horizontalSliderForMultiPage)
        operatioView.addSubview(horizontalSliderForMultiPageView)
        horizontalSliderForMultiPageView.snp.makeConstraints { make in
            make.top.equalTo(verticalSliderForSinglePageView.snp.bottom).offset(35)
            make.width.centerX.equalTo(verticalSliderForSinglePageView)
        }
        
        let verticalSliderForMultiPageView: UIView = createDescContentView(desc: "垂直方向有多个内容页面时，是否需要支持滑动(contentSlidingDirection == omnidirectional时固定为false)", controView: verticalSliderForMultiPage)
        operatioView.addSubview(verticalSliderForMultiPageView)
        verticalSliderForMultiPageView.snp.makeConstraints { make in
            make.top.equalTo(horizontalSliderForMultiPageView.snp.bottom).offset(35)
            make.width.centerX.equalTo(horizontalSliderForMultiPageView)
        }
        
        let unlimitedCarouselView: UIView = createDescContentView(desc: "是否需要无限轮播，除contentSlidingDirection == omnidirectional时固定为false外，其余默认开启，当设置false时，会强制设置automaticCarousel为false", controView: unlimitedCarousel)
        operatioView.addSubview(unlimitedCarouselView)
        unlimitedCarouselView.snp.makeConstraints { make in
            make.top.equalTo(verticalSliderForMultiPageView.snp.bottom).offset(35)
            make.width.centerX.equalTo(verticalSliderForMultiPageView)
        }
        
        let automaticCarouselView: UIView = createDescContentView(desc: "是否需要自动轮播，除contentSlidingDirection == omnidirectional时固定为false外，其余默认开启，当设置false时，会关闭定时器", controView: automaticCarousel)
        operatioView.addSubview(automaticCarouselView)
        automaticCarouselView.snp.makeConstraints { make in
            make.top.equalTo(unlimitedCarouselView.snp.bottom).offset(35)
            make.width.centerX.equalTo(unlimitedCarouselView)
        }
        
        let startOrStopTimerView: UIView = createDescContentView(desc: "开启或者关闭定时器(不支持contentSlidingDirection == omnidirectional时调用)", controView: startOrStopTimer)
        operatioView.addSubview(startOrStopTimerView)
        startOrStopTimerView.snp.makeConstraints { make in
            make.top.equalTo(automaticCarouselView.snp.bottom).offset(35)
            make.width.centerX.equalTo(automaticCarouselView)
        }
        
        let nextContentView: UIView = createDescContentViews(desc: "切换指定方向下一个内容页面(不支持直接传入direction为omnidirectional)", controViews: [nextContent, nextContentDirection])
        operatioView.addSubview(nextContentView)
        nextContentView.snp.makeConstraints { make in
            make.top.equalTo(startOrStopTimerView.snp.bottom).offset(35)
            make.width.centerX.equalTo(startOrStopTimerView)
        }
        
        let lastContentView: UIView = createDescContentViews(desc: "切换指定方向上一个内容页面(不支持直接传入direction为omnidirectional)", controViews: [lastContent, lastContentDirection])
        operatioView.addSubview(lastContentView)
        lastContentView.snp.makeConstraints { make in
            make.top.equalTo(nextContentView.snp.bottom).offset(35)
            make.width.centerX.equalTo(nextContentView)
        }
        
        let switchContentView: UIView = createDescContentViews(desc: "切换到指定方向指定下标处(不支持直接传入direction为omnidirectional)", controViews: [switchContent, switchContentDirection, switchContentPicker])
        operatioView.addSubview(switchContentView)
        switchContentView.snp.makeConstraints { make in
            make.top.equalTo(lastContentView.snp.bottom).offset(35)
            make.width.centerX.equalTo(lastContentView)
            make.bottom.equalToSuperview().offset(-100)
        }
        
        switchContentView.layoutIfNeeded()
        operatioView.contentSize = CGSize(width: UIDevice.wy_screenWidth, height: switchContentView.wy_bottom)
    }
    
    func createDescContentView(desc: String, controView: UIView?, valueView: UIView? = nil) -> UIView {
        
        let contentView = UIView()
        
        let descView: UILabel = cerateDescView(desc, superView: contentView)
        
        if let controView = controView {
            contentView.addSubview(controView)
            controView.snp.makeConstraints { make in
                make.left.bottom.equalToSuperview()
                make.height.equalTo(25)
                if controView is UISwitch {
                    make.top.equalTo(descView.snp.bottom).offset(5)
                    make.width.equalTo(80)
                }else if controView is UILabel {
                    make.centerY.equalTo(descView)
                    make.width.equalToSuperview().offset(-30)
                }else if valueView != nil {
                    make.top.equalTo(descView.snp.bottom).offset(5)
                    make.width.equalToSuperview().offset(-55)
                }else {
                    make.top.equalTo(descView.snp.bottom).offset(5)
                    make.width.equalToSuperview()
                }
            }
        }
        
        if let valueView = valueView {
            contentView.addSubview(valueView)
            if let controView = controView {
                valueView.snp.makeConstraints { make in
                    make.left.equalTo(controView.snp.right).offset(10)
                    make.centerY.equalTo(controView)
                }
            }else {
                descView.snp.updateConstraints { make in
                    make.width.equalToSuperview().offset(-55)
                }
                valueView.snp.makeConstraints { make in
                    make.left.equalTo(descView.snp.right).offset(10)
                    make.centerY.equalTo(descView)
                }
            }
        }
        
        return contentView
    }
    
    func createDescContentViews(desc: String, controViews: [UIView]) -> UIView {
        let contentView = UIView()
        
        let descView: UILabel = cerateDescView(desc, superView: contentView)
        
        var contentlastView: UIView? = nil
        for controView in controViews {
            if controView is UIButton {
                (controView as! UIButton).setTitle("切换", for: .normal)
            }
            contentView.addSubview(controView)
            controView.snp.makeConstraints { make in
                if let lastView = contentlastView {
                    make.left.equalTo(lastView.snp.right).offset(10)
                }else {
                    make.left.equalToSuperview()
                }
                
                if controView is UISegmentedControl {
                    make.width.equalTo(UIDevice.wy_screenWidth - 20 - 160)
                } else if controView is UIPickerView {
                    make.width.equalTo(90)
                    make.height.equalTo(100)
                    make.bottom.equalToSuperview()
                } else {
                    make.width.equalTo(60)
                }
                if !controViews.contains(switchContentDirection) {
                    make.height.equalTo(25)
                    make.bottom.equalToSuperview()
                }
                
                make.top.equalTo(descView.snp.bottom).offset(5)
                
                contentlastView = controView
            }
        }
        
        return contentView
    }
    
    func cerateDescView(_ desc: String, superView: UIView) -> UILabel {
        
        let descView: UILabel = UILabel()
        descView.text = desc
        descView.numberOfLines = 0
        descView.textColor = .black
        descView.textAlignment = .left
        superView.addSubview(descView)
        descView.snp.makeConstraints { make in
            make.left.top.width.right.equalToSuperview()
        }
        
        return descView
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension WYTestInfiniteSwitchController: WYContentScrollViewDelegate {
    
    /**
     *  监听ContentScrollView的偏移量变化事件
     *
     *  @param contentScrollView  当前WYContentScrollView的实例对象
     *
     *  @param offset             当前的偏移量
     *
     *  @param direction          当前的滑动方向
     *
     *  @param currentView        当前正在显示的用户传入的View
     (左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *
     *  @param reserveView        当前预备显示的用户传入的View
     (左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *
     *  @param index              当前滑动的Index
     */
    func wy_contentScrollViewDidScroll(_ contentScrollView: WYContentScrollView, offset: CGPoint, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView, index: Int) {
        wy_print("监听到ContentScrollView的偏移量事件\n当前X：\(offset.x)\n当前Y：\(offset.y)\n滑动方向：\(direction)\n当前滑动的Index：\(index)\n当前正在显示的用户传入的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)：\(currentView)\n当前预备显示的用户传入的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)：\(reserveView)\n水平方向Contents：\(horizontalViews)\n垂直方向Contents：\(verticalViews)")
    }
    
    /**
     *  监听ContentScrollView的点击事件
     *
     *  @param contentScrollView  当前WYContentScrollView的实例对象
     *
     *  @param direction          当前的滑动方向
     *
     *  @param currentView        当前正在显示的用户传入的View
     (左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *
     *  @param reserveView        当前预备显示的用户传入的View
     (左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *
     *  @param index              当前点击的Index
     */
    func wy_contentScrollViewDidClick(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView, index: Int) {
        wy_print("监听到ContentScrollView点击事件\n滑动方向：\(direction)\n当前滑动的Index：\(index)\n当前正在显示的用户传入的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)：\(currentView)\n当前预备显示的用户传入的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)：\(reserveView)\n水平方向Contents：\(horizontalViews)\n垂直方向Contents：\(verticalViews)")
    }
    
    /**
     *  监听ContentScrollView即将切换页面的事件
     (contentSlidingDirection != omnidirectional时可用)
     *
     *  @param contentScrollView  当前WYContentScrollView的实例对象
     *
     *  @param direction          当前的滑动方向
     *
     *  @param currentView        当前正在显示的用户传入的View
     (左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *
     *  @param reserveView        当前预备显示的用户传入的View
     (左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     */
    func wy_contentScrollViewWillSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView) {
        wy_print("监听到ContentScrollView即将切换页面的事件(contentSlidingDirection != omnidirectional时可用)\n滑动方向：\(direction)\n当前正在显示的用户传入的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)：\(currentView)\n当前预备显示的用户传入的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)：\(reserveView)\n水平方向Contents：\(horizontalViews)\n垂直方向Contents：\(verticalViews)")
    }
    
    /**
     *  监听ContentScrollView页面已经切换完成的事件
     (contentSlidingDirection != omnidirectional时可用)
     *
     *  @param contentScrollView  当前WYContentScrollView的实例对象
     *
     *  @param direction          当前的滑动方向
     *
     *  @param currentView        当前正在显示的用户传入的View
     (左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *
     *  @param reserveView        当前预备显示的用户传入的View
     (左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     */
    func wy_contentScrollViewDidSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView) {
        wy_print("监听到ContentScrollView页面已经切换完成的事件(contentSlidingDirection != omnidirectional时可用)\n滑动方向：\(direction)\n当前正在显示的用户传入的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)：\(currentView)\n当前预备显示的用户传入的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)：\(reserveView)\n水平方向Contents：\(horizontalViews)\n垂直方向Contents：\(verticalViews)")
    }
    
    /**
     *  监听ContentScrollView即将切换页面的事件
     (contentSlidingDirection == omnidirectional时可用)
     *
     *  @param contentScrollView     当前WYContentScrollView的实例对象
     *
     *  @param direction             当前的滑动方向
     *
     *  @param currentHorizontalView 当前正在水平方向显示的View(用户传入的View)
     *
     *  @param reserveHorizontalView 当前水平方向预备显示的View(用户传入的View)
     *
     *  @param currentVerticalView   当前正在垂直方向显示的View(用户传入的View)
     *
     *  @param reserveVerticalView   当前垂直方向预备显示的View(用户传入的View)
     */
    func wy_contentScrollViewWillSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentHorizontalView: UIView, reserveHorizontalView: UIView, currentVerticalView: UIView, reserveVerticalView: UIView) {
        wy_print("监听到ContentScrollView即将切换页面的事件(contentSlidingDirection == omnidirectional时可用)\n滑动方向：\(direction)\n当前正在水平方向显示的View(用户传入的View)：\(currentHorizontalView)\n当前水平方向预备显示的View(用户传入的View)：\(reserveHorizontalView)\n当前正在垂直方向显示的View(用户传入的View)：\(currentVerticalView)\n当前垂直方向预备显示的View(用户传入的View)：\(reserveVerticalView)\n水平方向Contents：\(horizontalViews)\n垂直方向Contents：\(verticalViews)")
    }
    
    /**
     *  监听ContentScrollView页面已经切换完成的事件
     (contentSlidingDirection == omnidirectional时可用)
     *
     *  @param contentScrollView     当前WYContentScrollView的实例对象
     *
     *  @param direction             当前的滑动方向
     *
     *  @param currentHorizontalView 当前正在水平方向显示的View(用户传入的View)
     *
     *  @param reserveHorizontalView 当前水平方向预备显示的View(用户传入的View)
     *
     *  @param currentVerticalView   当前正在垂直方向显示的View(用户传入的View)
     *
     *  @param reserveVerticalView   当前垂直方向预备显示的View(用户传入的View)
     */
    func wy_contentScrollViewDidSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentHorizontalView: UIView, reserveHorizontalView: UIView, currentVerticalView: UIView, reserveVerticalView: UIView) {
        wy_print("监听ContentScrollView页面已经切换完成的事件(contentSlidingDirection == omnidirectional时可用)\n滑动方向：\(direction)\n当前正在水平方向显示的View(用户传入的View)：\(currentHorizontalView)\n当前水平方向预备显示的View(用户传入的View)：\(reserveHorizontalView)\n当前正在垂直方向显示的View(用户传入的View)：\(currentVerticalView)\n当前垂直方向预备显示的View(用户传入的View)：\(reserveVerticalView)\n水平方向Contents：\(horizontalViews)\n垂直方向Contents：\(verticalViews)")
    }
}

extension WYTestInfiniteSwitchController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    // 返回每一行显示的文字
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return ["0", "1", "2", "3", "4", "5"][row]
    }
    
    // 监听选中事件
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switchContentIndex = row
    }
    
    // 返回组件（列）的数量
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // 返回每一列的行数
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 6
    }
}
