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
    
    /// 水平方向内容页视图数量（Int.max表示无限数量）
    var numberOfHorizontalContent: UISegmentedControl = UISegmentedControl(items: ["0", "1", "2", "3", "4", "5", "∞"])
    
    /// 垂直方向内容页视图数量（Int.max表示无限数量）
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

    /// 轻扫跨轴直切的速度阈值滑杆(0~5000超出组件钳制区间[50,3000]的部分会被自动钳到边界，默认500，调低更灵敏调高更保守，实时写入contentScrollView.crossAxisFlickVelocityThreshold)
    var flickVelocityThreshold: UISlider = UISlider()
    var flickVelocityValue: UILabel = UILabel()

    /// 跨轴切换呈现样式选择器(瞬时/滑动/渐变/缩放，默认瞬时，写入contentScrollView.crossAxisSwitchStyle；用跨轴轻扫或指定方向切换观察效果)
    var crossAxisSwitchStyleSegment: UISegmentedControl = UISegmentedControl(items: ["瞬时", "滑动", "渐变", "缩放"])

    /// 跨轴切换动画时长滑杆(0~3.0超出组件钳制区间[0.1,2.0]的部分会被自动钳到边界，默认0.25，仅滑动/渐变/缩放生效，实时写入contentScrollView.crossAxisSwitchDuration，标签显示钳制后的实际值)
    var switchDuration: UISlider = UISlider()
    var switchDurationValue: UILabel = UILabel()

    /// 缩放切入比例滑杆(0.5~3.0超出组件钳制区间[1.0,2.0]的部分会被自动钳到边界，默认1.15，仅缩放模式生效，实时写入contentScrollView.crossAxisSwitchZoomScale，标签显示钳制后的实际值)
    var zoomScale: UISlider = UISlider()
    var zoomScaleValue: UILabel = UILabel()
    
    /// 水平方向是否支持滑动
    var horizontalSliderEnabled: UISwitch = UISwitch()

    /// 垂直方向是否支持滑动
    var verticalSliderEnabled: UISwitch = UISwitch()
    
    /// 是否需要无限轮播
    var unlimitedCarousel: UISwitch = UISwitch()
    
    /**
     *  是否需要自动轮播，默认false(不自动轮播，业务想要自动轮播显式开启)
     *  开启后组件会在首次展示时自动开表；关闭/stopTimer后需显式startTimer才恢复
     */
    var automaticCarousel: UISwitch = UISwitch()
    
    /**
     *  开启或者关闭定时器
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

    /// 水平方向各下标对应的图片
    let pageImages: [UIImage] = [UIImage(named: "banner_0")!,
                                 UIImage(named: "banner_1")!,
                                 UIImage(named: "banner_2")!,
                                 UIImage(named: "banner_3")!,
                                 UIImage(named: "banner_4")!,
                                 UIImage(named: "banner_5")!,
                                 UIImage(named: "banner_6")!,
                                 UIImage(named: "banner_7")!,
                                 UIImage(named: "banner_8")!,
                                 UIImage(named: "banner_9")!]

    /// 垂直方向各下标对应的视频地址
    let pageVideoList: [String] = [
        "https://files.cochat.lenovo.com/download/dbb26a06-4604-3d2b-bb2c-6293989e63a7/55deb281e01b27194daf6da391fdfe83.mp4",
        "http://www.w3school.com.cn/i/movie.mp4",
        URL(fileURLWithPath: Bundle.main.path(forResource: "mpeg4_local", ofType: "mp4").wy_safe).absoluteString,
        "http://vjs.zencdn.net/v/oceans.mp4",
        "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
        "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8",
        "https://live.metshop.top/douyu/9220456",
        "https://live.metshop.top/huya/11342412",
        "https://live.metshop.top/huya/11342421",
        "https://live.metshop.top/douyu/1713615",
        "https://live.metshop.top/douyu/9171887",
        "https://live.metshop.top/douyu/9456028",
        "https://live.metshop.top/huya/11352881",
        "https://live.metshop.top/huya/11342390",
        "https://live.metshop.top/huya/11352876"]
    /// 按下标取水平方向图片：下标对数组长度取模(∞数量+无限轮播时reserveHorizontalIndex可能环绕成极大值，裸下标会越界闪退)
    func imageForHorizontalPage(at index: Int) -> UIImage {
        return pageImages[index % pageImages.count]
    }

    /// 按下标取垂直方向视频地址：下标对数组长度取模(∞数量+无限轮播时reserveVerticalIndex可能环绕成极大值，裸下标会越界闪退)
    func videoForVerticalPage(at index: Int) -> String {
        return pageVideoList[index % pageVideoList.count]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        addSubView()
        configSubView()
    }
    
    func configSubView() {
        
        for i in 0...1 {
            let horizontal: UIImageView = UIImageView()
            horizontal.contentMode = .scaleAspectFill
            horizontal.clipsToBounds = true
            horizontal.tag = 100 + i
            horizontalViews.append(horizontal)

            let vertical: WYMediaPlayer = WYMediaPlayer()
            vertical.delegate = self
            vertical.backgroundColor = .black
            vertical.shouldUseFirstFrameAsPoster = true
            vertical.tag = 200 + i
            verticalViews.append(vertical)
        }
        
        contentScrollView.backgroundColor = .wy_random
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

        nextContentDirection.selectedSegmentIndex = 0
        lastContentDirection.selectedSegmentIndex = 0
        switchContentDirection.selectedSegmentIndex = 0
        
        standingTime.value = 3
        standingTime.minimumValue = 0
        standingTime.maximumValue = 5
        standingTime.addTarget(self, action: #selector(standingTimeChanged(sender:)), for: .valueChanged)

        standingTimeValue.textColor = .black
        standingTimeValue.text = "3.0"

        flickVelocityThreshold.value = 500
        flickVelocityThreshold.minimumValue = 0
        flickVelocityThreshold.maximumValue = 5000
        flickVelocityThreshold.addTarget(self, action: #selector(flickVelocityChanged(sender:)), for: .valueChanged)

        flickVelocityValue.textColor = .black
        flickVelocityValue.text = "500"

        crossAxisSwitchStyleSegment.selectedSegmentIndex = 0
        crossAxisSwitchStyleSegment.addTarget(self, action: #selector(crossAxisSwitchStyleChanged(sender:)), for: .valueChanged)

        switchDuration.value = 0.25
        switchDuration.minimumValue = 0
        switchDuration.maximumValue = 3
        switchDuration.addTarget(self, action: #selector(switchDurationChanged(sender:)), for: .valueChanged)

        switchDurationValue.textColor = .black
        switchDurationValue.text = "0.25"

        zoomScale.value = 1.15
        zoomScale.minimumValue = 0.5
        zoomScale.maximumValue = 3
        zoomScale.addTarget(self, action: #selector(zoomScaleChanged(sender:)), for: .valueChanged)

        zoomScaleValue.textColor = .black
        zoomScaleValue.text = "1.15"
        
        horizontalSliderEnabled.isOn = true
        verticalSliderEnabled.isOn = true
        unlimitedCarousel.isOn = true
        // 与组件默认值一致(automaticCarousel默认false，不自动轮播；业务想要自动轮播显式开启，开启后组件会在首次展示时自动开表)
        automaticCarousel.isOn = false
        // automaticCarousel默认关闭，挂载时不会自动开表，开关显示off与实际计时器状态一致
        startOrStopTimer.isOn = false

        for switchView in [horizontalSliderEnabled, verticalSliderEnabled, unlimitedCarousel, automaticCarousel, startOrStopTimer] {
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 离开测试页停止所有播放器，避免视频在后台继续发声、耗流
        verticalViews.forEach { ($0 as? WYMediaPlayer)?.stop(false) }
    }

    deinit {
        // 页面销毁时释放播放器全部资源(与WYTestLiveStreamingController的deinit处理一致)
        verticalViews.forEach { ($0 as? WYMediaPlayer)?.releaseAll() }
        
        WYLogManager.output("WYTestInfiniteSwitchController deinit")
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
                contentScrollView.horizontalOrVerticalDisplay(currentView: horizontalViews.first!, reserveView: horizontalViews.last!)
                break
            case .topOrBottom:
                contentScrollView.horizontalOrVerticalDisplay(currentView: verticalViews.first!, reserveView: verticalViews.last!)
                break
            case .omnidirectional:
                contentScrollView.omnidirectionalDisplay(currentHorizontalView: horizontalViews.first!, reserveHorizontalView: horizontalViews.last!, currentVerticalView: verticalViews.first!, reserveVerticalView: verticalViews.last!)
                break
            }
            
        }else if sender == prioritySlidingDirection {
            contentScrollView.prioritySlidingDirection = [.leftOrRight, .topOrBottom, .omnidirectional][sender.selectedSegmentIndex]
        }
    }
    
    /// 从方向选择器安全取值：未选中(selectedSegmentIndex为-1)或越界时返回默认的"左右"，避免数组下标越界闪退
    private func selectedDirection(of segmentedControl: UISegmentedControl) -> WYContentSlidingDirection {
        let directions: [WYContentSlidingDirection] = [.leftOrRight, .topOrBottom, .omnidirectional]
        let index = segmentedControl.selectedSegmentIndex
        return (index >= 0 && index < directions.count) ? directions[index] : .leftOrRight
    }

    @objc func buttonClick(sender: UIButton) {
        if sender == nextContent {
            contentScrollView.nextContent(selectedDirection(of: nextContentDirection))
        }else if sender == lastContent {
            contentScrollView.lastContent(selectedDirection(of: lastContentDirection))
        }else if sender == switchContent {
            contentScrollView.switchContent(selectedDirection(of: switchContentDirection), index: &switchContentIndex)
        }
    }
    
    @objc func standingTimeChanged(sender: UISlider) {
        standingTime.value = floor(sender.value)
        standingTimeValue.text = "\(standingTime.value)"
        contentScrollView.standingTime = TimeInterval(standingTime.value)
    }

    @objc func flickVelocityChanged(sender: UISlider) {
        flickVelocityThreshold.value = floor(sender.value)
        flickVelocityValue.text = "\(Int(flickVelocityThreshold.value))"
        contentScrollView.crossAxisFlickVelocityThreshold = CGFloat(flickVelocityThreshold.value)
    }

    @objc func crossAxisSwitchStyleChanged(sender: UISegmentedControl) {
        contentScrollView.crossAxisSwitchStyle = WYContentSwitchStyle(rawValue: sender.selectedSegmentIndex) ?? .instant
    }

    @objc func switchDurationChanged(sender: UISlider) {
        contentScrollView.crossAxisSwitchDuration = TimeInterval(sender.value)
        // 标签显示钳制后的实际值：滑到0.1以下/2.0以上可直观看到被组件钳到边界
        switchDurationValue.text = String(format: "%.2f", contentScrollView.crossAxisSwitchDuration)
    }

    @objc func zoomScaleChanged(sender: UISlider) {
        contentScrollView.crossAxisSwitchZoomScale = CGFloat(sender.value)
        // 标签显示钳制后的实际值：滑到1.0以下/2.0以上可直观看到被组件钳到边界
        zoomScaleValue.text = String(format: "%.2f", contentScrollView.crossAxisSwitchZoomScale)
    }

    @objc func switchSwitched(sender: UISwitch) {
        if sender == horizontalSliderEnabled {
            contentScrollView.horizontalSliderEnabled = sender.isOn
        }else if sender == verticalSliderEnabled {
            contentScrollView.verticalSliderEnabled = sender.isOn
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
        
        let horizontalSliderEnabledView: UIView = createDescContentView(desc: "水平方向是否支持滑动(仅内容页数量大于1时生效，单页不可滑)，默认true", controView: horizontalSliderEnabled)
        operatioView.addSubview(horizontalSliderEnabledView)
        horizontalSliderEnabledView.snp.makeConstraints { make in
            make.top.equalTo(standingTimeView.snp.bottom).offset(35)
            make.width.centerX.equalTo(standingTimeView)
        }

        let verticalSliderEnabledView: UIView = createDescContentView(desc: "垂直方向是否支持滑动(仅内容页数量大于1时生效，单页不可滑)，默认true", controView: verticalSliderEnabled)
        operatioView.addSubview(verticalSliderEnabledView)
        verticalSliderEnabledView.snp.makeConstraints { make in
            make.top.equalTo(horizontalSliderEnabledView.snp.bottom).offset(35)
            make.width.centerX.equalTo(horizontalSliderEnabledView)
        }

        let unlimitedCarouselView: UIView = createDescContentView(desc: "是否需要无限轮播", controView: unlimitedCarousel)
        operatioView.addSubview(unlimitedCarouselView)
        unlimitedCarouselView.snp.makeConstraints { make in
            make.top.equalTo(verticalSliderEnabledView.snp.bottom).offset(35)
            make.width.centerX.equalTo(verticalSliderEnabledView)
        }
        
        let automaticCarouselView: UIView = createDescContentView(desc: "是否需要自动轮播，默认false，开启后首次展示自动开表，关闭或stopTimer后需显式startTimer恢复", controView: automaticCarousel)
        operatioView.addSubview(automaticCarouselView)
        automaticCarouselView.snp.makeConstraints { make in
            make.top.equalTo(unlimitedCarouselView.snp.bottom).offset(35)
            make.width.centerX.equalTo(unlimitedCarouselView)
        }
        
        let startOrStopTimerView: UIView = createDescContentView(desc: "开启或者关闭定时器", controView: startOrStopTimer)
        operatioView.addSubview(startOrStopTimerView)
        startOrStopTimerView.snp.makeConstraints { make in
            make.top.equalTo(automaticCarouselView.snp.bottom).offset(35)
            make.width.centerX.equalTo(automaticCarouselView)
        }

        let flickVelocityView: UIView = createDescContentView(desc: "轻扫跨轴直切速度阈值(pt/s，默500，滑杆0~5000可测钳制：低于50/高于3000会被组件自动钳到边界，仅影响全向模式)", controView: flickVelocityThreshold, valueView: flickVelocityValue)
        operatioView.addSubview(flickVelocityView)
        flickVelocityView.snp.makeConstraints { make in
            make.top.equalTo(startOrStopTimerView.snp.bottom).offset(35)
            make.width.centerX.equalTo(startOrStopTimerView)
        }

        let crossAxisSwitchStyleView: UIView = createDescContentView(desc: "跨轴切换呈现样式(默认瞬时；滑动=当前页滑出目标页滑入，渐变=目标页淡入覆盖，缩放=目标页缩放归位淡入；同样作用于跨轴轻扫直切，同轴切换不受影响)", controView: crossAxisSwitchStyleSegment)
        operatioView.addSubview(crossAxisSwitchStyleView)
        crossAxisSwitchStyleView.snp.makeConstraints { make in
            make.top.equalTo(flickVelocityView.snp.bottom).offset(35)
            make.width.centerX.equalTo(flickVelocityView)
        }

        let switchDurationView: UIView = createDescContentView(desc: "跨轴切换动画时长(秒，默认0.25，滑杆0~3可测钳制：低于0.1/高于2.0会被组件自动钳到边界，仅滑动/渐变/缩放生效)", controView: switchDuration, valueView: switchDurationValue)
        operatioView.addSubview(switchDurationView)
        switchDurationView.snp.makeConstraints { make in
            make.top.equalTo(crossAxisSwitchStyleView.snp.bottom).offset(35)
            make.width.centerX.equalTo(crossAxisSwitchStyleView)
        }

        let zoomScaleView: UIView = createDescContentView(desc: "缩放切入的缩放比例(默认1.15，进入页从该值缩放归位、退场页放大至该值淡出，滑杆0.5~3可测钳制：低于1.0/高于2.0会被组件自动钳到边界，1.0时无缩放退化为渐变，仅缩放模式生效)", controView: zoomScale, valueView: zoomScaleValue)
        operatioView.addSubview(zoomScaleView)
        zoomScaleView.snp.makeConstraints { make in
            make.top.equalTo(switchDurationView.snp.bottom).offset(35)
            make.width.centerX.equalTo(switchDurationView)
        }

        let nextContentView: UIView = createDescContentViews(desc: "切换指定方向下一个内容页面(不支持直接传入direction为omnidirectional)", controViews: [nextContent, nextContentDirection])
        operatioView.addSubview(nextContentView)
        nextContentView.snp.makeConstraints { make in
            make.top.equalTo(zoomScaleView.snp.bottom).offset(35)
            make.width.centerX.equalTo(zoomScaleView)
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
        //wy_print("监听到ContentScrollView的偏移量事件\n当前X：\(offset.x)\n当前Y：\(offset.y)\n滑动方向：\(direction)\n当前滑动的Index：\(index)\n当前正在显示的用户传入的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)：\(currentView)\n当前预备显示的用户传入的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)：\(reserveView)\n水平方向Contents：\(horizontalViews)\n垂直方向Contents：\(verticalViews)")
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
        //wy_print("监听到ContentScrollView点击事件\n滑动方向：\(direction)\n当前滑动的Index：\(index)\n当前正在显示的用户传入的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)：\(currentView)\n当前预备显示的用户传入的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)：\(reserveView)\n水平方向Contents：\(horizontalViews)\n垂直方向Contents：\(verticalViews)")
        if direction == .up || direction == .down {
            guard let mediaPlayer: WYMediaPlayer = currentView as? WYMediaPlayer else { return }
            let isPlaying: Bool = mediaPlayer.ijkPlayer?.isPlaying() ?? false
            if isPlaying {
                mediaPlayer.pause()
            }else {
                mediaPlayer.play()
            }
        }
        
        if direction == .left || direction == .right {
        }
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
    func wy_contentScrollViewWillSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentHorizontalView: UIView?, reserveHorizontalView: UIView?, currentVerticalView: UIView?, reserveVerticalView: UIView?) {
        
        //wy_print("监听到ContentScrollView即将切换页面的事件\n滑动方向：\(direction)\n当前正在水平方向显示的View(用户传入的View)：\(currentHorizontalView)\n当前水平方向预备显示的View(用户传入的View)：\(reserveHorizontalView)\n当前正在垂直方向显示的View(用户传入的View)：\(currentVerticalView)\n当前垂直方向预备显示的View(用户传入的View)：\(reserveVerticalView)\n水平方向Contents：\(horizontalViews)\n垂直方向Contents：\(verticalViews)")
        
        let reserveHorizontalView: UIImageView? = reserveHorizontalView as? UIImageView
        
        let currentVerticalView: WYMediaPlayer? = currentVerticalView as? WYMediaPlayer
        let reserveVerticalView: WYMediaPlayer? = reserveVerticalView as? WYMediaPlayer
        
        if direction == .up || direction == .down {
            
            //wy_print("reserveVerticalView?.mediaUrl = \(reserveVerticalView!.mediaUrl)\nvideoForVerticalPage(at: contentScrollView.reserveVerticalIndex) = \(videoForVerticalPage(at: contentScrollView.reserveVerticalIndex))\nreserveVerticalView?.state = \(reserveVerticalView!.state)")
            
            // 地址已在预备页上则只按预备页处理(在播的暂停、缓冲中的照常缓冲)，否则换源加载；取值走取模方法防∞模式环绕下标越界
            if let playUrl: String = reserveVerticalView?.mediaUrl, playUrl == videoForVerticalPage(at: contentScrollView.reserveVerticalIndex) {
                reserveVerticalView?.pause()
            }else {
                reserveVerticalView?.prepare(with: videoForVerticalPage(at: contentScrollView.reserveVerticalIndex))
            }
        }
        
        if direction == .left || direction == .right {
            // 切换为图片后也要暂停播放
            currentVerticalView?.pause()
            reserveVerticalView?.pause()
            
            // 取值走取模方法防∞模式环绕下标越界
            reserveHorizontalView?.image = imageForHorizontalPage(at: contentScrollView.reserveHorizontalIndex)
        }
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
    func wy_contentScrollViewDidSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentHorizontalView: UIView?, reserveHorizontalView: UIView?, currentVerticalView: UIView?, reserveVerticalView: UIView?) {
        //wy_print("监听ContentScrollView页面已经切换完成的事件(contentSlidingDirection == omnidirectional时可用)\n滑动方向：\(direction)\n当前正在水平方向显示的View(用户传入的View)：\(currentHorizontalView)\n当前水平方向预备显示的View(用户传入的View)：\(reserveHorizontalView)\n当前正在垂直方向显示的View(用户传入的View)：\(currentVerticalView)\n当前垂直方向预备显示的View(用户传入的View)：\(reserveVerticalView)\n水平方向Contents：\(horizontalViews)\n垂直方向Contents：\(verticalViews)")
        
        let currentHorizontalView: UIImageView? = currentHorizontalView as? UIImageView
        
        let currentVerticalView: WYMediaPlayer? = currentVerticalView as? WYMediaPlayer
        let reserveVerticalView: WYMediaPlayer? = reserveVerticalView as? WYMediaPlayer
        
        if direction == .up || direction == .down {
            // 此时这里的reservePlayer就是上一次显示的player，所以这里要先stop或者暂停上一次的播放
            reserveVerticalView?.pause()

            // 当前页必须按currentVerticalIndex加载(补发didSwitch时reserveVerticalIndex还是残留值，用它会串台)；取值走取模方法防∞模式环绕下标越界
            if let playUrl: String = currentVerticalView?.mediaUrl, playUrl == videoForVerticalPage(at: contentScrollView.currentVerticalIndex) {
                currentVerticalView?.play()
            }else {
                currentVerticalView?.play(with: videoForVerticalPage(at: contentScrollView.currentVerticalIndex))
            }
        }
        
        if direction == .left || direction == .right {
            currentVerticalView?.pause()
            reserveVerticalView?.pause()
            // 取值走取模方法防∞模式环绕下标越界
            currentHorizontalView?.image = imageForHorizontalPage(at: contentScrollView.currentHorizontalIndex)
        }
    }
}

extension WYTestInfiniteSwitchController: WYMediaPlayerDelegate {
    /// 播放器状态回调
    func wy_mediaPlayerStateDidChanged(_ player: WYMediaPlayer, state: WYMediaPlayerState) {
        if state == .ready {
            WYLogManager.output("可以播放了")
        }
        switch state {
        case .rendered, .ready, .playing, .interrupted, .playable, .ended, .userExited, .error, .playUrlEmpty, .paused:
            WYActivity.dismissLoading(in: player, animate: false)
        default:
            WYActivity.showLoading(in: player, animation: .gifOrApng, config: WYActivityConfig.concise)
        }
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
