//
//  WYScrollText.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/11/1.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

@objc public protocol WYScrollTextDelegate {
    
    @objc optional func itemDidClick(_ itemIndex: Int)
}

public class WYScrollText: UIView {
    
    /// 点击事件代理(也可以通过传入block监听)
    public weak var delegate: WYScrollTextDelegate?
    
    /// 点击事件(也可以通过实现代理监听)
    public func didClickHandler(handler:((_ index: Int) -> Void)? = .none) {
        actionHandler = handler
    }
    
    /// 占位文本
    public var placeholder: String = WYLocalized("WYLocalizable_11", table: WYBasisKitConfig.kitLocalizableTable)
    
    /// 文本颜色
    public var textColor: UIColor = .black
    
    /// 文本字体
    public var textFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(12, WYBasisKitConfig.defaultScreenPixels))
    
    /// 轮播间隔，默认3s  为保证轮播流畅，该值要求最小为2s
    public var interval: TimeInterval = 3 {
        didSet {
            // 确保最小间隔为2秒
            if interval < 2 {
                interval = 2
            }
            
            // 只有当间隔时间真正改变时才更新定时器
            if oldValue != interval {
                updateTimerInterval()
            }
        }
    }
    
    /// 背景色, 默认透明色
    public var contentColor: UIColor = .clear {
        didSet {
            collectionView.backgroundColor = contentColor
        }
    }
    
    private var _textArray: [String]!
    public var textArray: [String]! {
        set {
            _textArray = NSMutableArray(array: newValue) as? [String]
            if _textArray.isEmpty == true {
                _textArray.append(placeholder)
            }
            
            _textArray.append(_textArray.first ?? "")
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.startTimer()
            }
        }
        
        get {
            return _textArray
        }
    }
    
    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 0 // 行间距
        flowLayout.minimumInteritemSpacing = 0 // 列间距
        
        let collectionview = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionview.showsVerticalScrollIndicator = false
        collectionview.showsHorizontalScrollIndicator = false
        collectionview.delegate = self
        collectionview.dataSource = self
        collectionview.backgroundColor = contentColor
        collectionview.register(SctolTextCell.self, forCellWithReuseIdentifier: "SctolTextCell")
        collectionview.isScrollEnabled = false
        collectionview.isPagingEnabled = true
        addSubview(collectionview)
        
        return collectionview
    }()
    
    private var actionHandler: ((_ index: Int) -> Void)?
    
    /// 当前文本下标
    private var textIndex: Int = 0
    
    /// 定时器
    private var timer: Timer?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // 设置collectionView的约束
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    /// 开启定时器
    private func startTimer() {
        // 确保定时器不存在且文本数组有内容
        guard timer == nil, let textArray = textArray, textArray.count > 1 else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block:{ [weak self] (timer: Timer) -> Void in
            self?.scroll()
        })
        
        // 把定时器加入到RunLoop里面，保证持续运行，不被表视图滑动事件这些打断
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    /// 停止定时器
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    /// 更新定时器间隔
    private func updateTimerInterval() {
        // 如果定时器存在且有效，则更新
        if let timer = timer, timer.isValid {
            // 停止当前定时器
            stopTimer()
            
            // 重新启动定时器
            startTimer()
        } else {
            // 如果定时器不存在，但文本数组有内容，则启动定时器
            if let textArray = textArray, textArray.count > 1 {
                startTimer()
            }
        }
    }
    
    private func scroll() {
        guard self.superview != nil, let textArray = textArray, textArray.count > 1 else {
            stopTimer()
            return
        }
        
        textIndex += 1
        
        if textIndex < textArray.count {
            collectionView.scrollToItem(at: IndexPath(item: textIndex, section: 0), at: .top, animated: true)
        }
        
        if textIndex >= (textArray.count - 1) {
            textIndex = 0
            // 使用DispatchQueue而不是perform，更安全
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredVertically, animated: false)
            }
        }
    }
    
    deinit {
        stopTimer()
    }
}

extension WYScrollText: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return textArray?.count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SctolTextCell", for: indexPath) as! SctolTextCell

        cell.textView.font = self.textFont
        cell.textView.textColor = self.textColor
        cell.textView.backgroundColor = contentColor
        cell.textView.text = textArray[indexPath.item]
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let textArray = textArray,
              !((textArray.count == 2) && (textArray.first == placeholder) && (textArray.last == placeholder)) else {
            return
        }
        
        if let actionHandler = actionHandler {
            actionHandler((textIndex == textArray.count-1) ? 0 : textIndex)
        }
        delegate?.itemDidClick?((textIndex == textArray.count-1) ? 0 : textIndex)
    }
}

class SctolTextCell: UICollectionViewCell {
    
    lazy var textView: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        self.contentView.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        return label
    }()
}
