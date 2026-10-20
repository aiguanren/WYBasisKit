//
//  WYVideoPlayerShellViews.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// 控制壳的进度条(底轨加已缓冲段加已播段加拖点，拖动经回调抛出，只被默认壳使用)
final class WYVideoPlayerProgressView: UIView {

    /// 拖动中回调，参数为拖到的进度 0~1
    var onDragging: ((CGFloat) -> Void)?

    /// 拖动结束回调，参数为落定的进度 0~1
    var onDragEnd: ((CGFloat) -> Void)?

    /// 底轨颜色
    var trackColor: UIColor = UIColor(white: 1, alpha: 0.3) {
        didSet { trackLayer.backgroundColor = trackColor.cgColor }
    }

    /// 已缓冲段颜色
    var bufferColor: UIColor = UIColor(white: 1, alpha: 0.55) {
        didSet { bufferLayer.backgroundColor = bufferColor.cgColor }
    }

    /// 已播段颜色
    var playColor: UIColor = .systemBlue {
        didSet { playLayer.backgroundColor = playColor.cgColor }
    }

    /// 拖点颜色
    var thumbColor: UIColor = .white {
        didSet { thumbView.backgroundColor = thumbColor }
    }

    /// 当前播放进度 0~1(拖动中不跟随外部刷新)
    var progress: CGFloat = 0 {
        didSet { if isDragging == false { relayoutLayers() } }
    }

    /// 已缓冲进度 0~1
    var bufferProgress: CGFloat = 0 {
        didSet { relayoutLayers() }
    }

    /// 是否正在拖动
    private(set) var isDragging = false

    /// 底轨层
    private let trackLayer = CALayer()

    /// 已缓冲段层
    private let bufferLayer = CALayer()

    /// 已播段层
    private let playLayer = CALayer()

    /// 拖点视图(拖动时放大)
    private let thumbView = UIView()

    /// 触摸热区比可视轨道高，好按
    private let touchInset: CGFloat = UIDevice.wy_screenWidth(-14, WYBasisKitConfig.defaultScreenPixels)

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(trackLayer)
        layer.addSublayer(bufferLayer)
        layer.addSublayer(playLayer)
        thumbView.backgroundColor = .white
        thumbView.layer.cornerRadius = UIDevice.wy_screenWidth(7, WYBasisKitConfig.defaultScreenPixels)
        addSubview(thumbView)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        relayoutLayers()
    }

    /// 按当前进度排布各层
    private func relayoutLayers() {
        let barHeight: CGFloat = UIDevice.wy_screenHeight(3, WYBasisKitConfig.defaultScreenPixels)
        let y = (bounds.height - barHeight) / 2
        trackLayer.frame = CGRect(x: 0, y: y, width: bounds.width, height: barHeight)
        bufferLayer.frame = CGRect(x: 0, y: y, width: bounds.width * bufferProgress, height: barHeight)
        playLayer.frame = CGRect(x: 0, y: y, width: bounds.width * progress, height: barHeight)
        let thumbSize: CGFloat = isDragging ? UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels) : UIDevice.wy_screenWidth(14, WYBasisKitConfig.defaultScreenPixels)
        let thumbX = bounds.width * progress - thumbSize / 2
        thumbView.frame = CGRect(x: max(0, min(bounds.width - thumbSize, thumbX)), y: bounds.height / 2 - thumbSize / 2, width: thumbSize, height: thumbSize)
        thumbView.layer.cornerRadius = thumbSize / 2
    }

    /// 拖动进度
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        let ratio = max(0, min(1, location.x / max(bounds.width, 1)))
        switch gesture.state {
        case .began:
            isDragging = true
            progress = ratio
            onDragging?(ratio)
        case .changed:
            progress = ratio
            onDragging?(ratio)
        case .ended, .cancelled, .failed:
            isDragging = false
            progress = ratio
            onDragEnd?(ratio)
        default:
            break
        }
        relayoutLayers()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // 扩大触摸热区方便手指按中
        return bounds.insetBy(dx: touchInset, dy: touchInset).contains(point)
    }
}

/// 控制壳的选择菜单面板(倍速、清晰度、字幕共用的单列选项浮层，只被默认壳使用)
final class WYVideoPlayerMenuPanel: UIView {

    /// 选中某项回调，参数为下标
    var onSelect: ((Int) -> Void)?

    /// 点到面板外关闭回调
    var onDismissOutside: (() -> Void)?

    /// 面板背景色
    var panelBackgroundColor: UIColor = UIColor(white: 0, alpha: 0.75) {
        didSet { tableView.backgroundColor = panelBackgroundColor }
    }

    /// 选中项颜色
    var selectedColor: UIColor = .systemBlue

    /// 未选中项颜色
    var normalColor: UIColor = .white

    /// 全部选项
    private var options: [String] = []

    /// 当前选中下标
    private var selectedIndex: Int = 0

    /// 选项列表
    private let tableView = UITableView(frame: .zero, style: .plain)

    /// 盖在底下的全屏点击层(点外关闭)
    private let dimmingView = UIControl()

    init() {
        super.init(frame: .zero)
        tableView.backgroundColor = panelBackgroundColor
        tableView.layer.cornerRadius = UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels)
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        dimmingView.addTarget(self, action: #selector(handleDimmingTap), for: .touchUpInside)
        addSubview(dimmingView)
        addSubview(tableView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        dimmingView.frame = bounds
        let rowHeight: CGFloat = UIDevice.wy_screenHeight(40, WYBasisKitConfig.defaultScreenPixels)
        let panelHeight = min(bounds.height - UIDevice.wy_screenHeight(24, WYBasisKitConfig.defaultScreenPixels), CGFloat(options.count) * rowHeight + UIDevice.wy_screenHeight(8, WYBasisKitConfig.defaultScreenPixels))
        tableView.frame = CGRect(x: bounds.width - UIDevice.wy_screenWidth(148, WYBasisKitConfig.defaultScreenPixels), y: UIDevice.wy_screenHeight(12, WYBasisKitConfig.defaultScreenPixels), width: UIDevice.wy_screenWidth(136, WYBasisKitConfig.defaultScreenPixels), height: panelHeight)
    }

    /**
     *  刷新并展示面板
     *
     *  @param options    全部选项文字
     *  @param selected   当前选中下标
     *
     */
    func show(options: [String], selected: Int) {
        self.options = options
        self.selectedIndex = selected
        tableView.reloadData()
        isHidden = false
        setNeedsLayout()
    }

    /// 关闭面板
    func dismiss() {
        isHidden = true
    }

    /// 点击面板外
    @objc private func handleDimmingTap() {
        dismiss()
        onDismissOutside?()
    }
}

extension WYVideoPlayerMenuPanel: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.textLabel?.text = options[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.font = .systemFont(ofSize: UIFont.wy_fontSize(13, WYBasisKitConfig.defaultScreenPixels))
        cell.textLabel?.textColor = (indexPath.row == selectedIndex) ? selectedColor : normalColor
        cell.accessoryType = (indexPath.row == selectedIndex) ? .checkmark : .none
        cell.tintColor = selectedColor
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        tableView.reloadData()
        dismiss()
        onSelect?(indexPath.row)
    }
}
