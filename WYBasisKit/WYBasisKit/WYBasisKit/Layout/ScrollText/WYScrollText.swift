//
//  WYScrollText.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/11/1.
//  Copyright © 2020 官人. All rights reserved.
//

import SnapKit

@objc public protocol WYScrollTextDelegate {
    
    @objc optional func itemDidClick(_ itemIndex: NSInteger)
}

public class WYScrollText: UIView {
    
    /// 点击事件代理(也可以通过传入block监听)
    public weak var delegate: WYScrollTextDelegate?
    /// 点击事件(也可以通过实现代理监听)
    public func didClickHandler(handler:((_ index: NSInteger) -> Void)? = .none) {
        actionHandler = handler
    }
    /// 占位文本
    public var placeholder: String = WYLocalized("WYLocalizable_11", table: WYBasisKitConfig.kitLocalizableTable)
    /// 文本颜色
    public var textColor: UIColor = .black
    /// 文本字体
    public var textFont: UIFont = .systemFont(ofSize: wy_fontSize(12, WYBasisKitConfig.defaultScreenPixels))
    /// 轮播间隔，默认3s  为保证轮播流畅，该值要求最小为2s
    public var interval: TimeInterval = 3
    /// 背景色, 默认透明色
    public var contentColor: UIColor = .clear
    
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
        
        let collectionview = UICollectionView(frame: bounds, collectionViewLayout: flowLayout)
        collectionview.showsVerticalScrollIndicator = false
        collectionview.showsHorizontalScrollIndicator = false
        collectionview.delegate = self
        collectionview.dataSource = self
        collectionview.backgroundColor = contentColor
        collectionview.register(SctolTextCell.self, forCellWithReuseIdentifier: "SctolTextCell")
        collectionview.isScrollEnabled = false
        addSubview(collectionview)
        collectionview.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        return collectionview
    }()
    
    private var actionHandler: ((_ index: NSInteger) -> Void)?
    
    /// 当前文本下标
    private var textIndex: NSInteger = 0
    
    /// 定时器
    private var timer: Timer?
    
    /// 开启定时器
    private func startTimer() {
        
        if timer == nil {
            
            timer = Timer.scheduledTimer(withTimeInterval: (interval < 2) ? 2 : interval, repeats: true, block:{ [weak self] (timer: Timer) -> Void in
                self?.scroll()
            })
        }
        // 把定时器加入到RunLoop里面，保证持续运行，不被表视图滑动事件这些打断
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    /// 停止定时器
    private func stopTimer() {
        
        timer?.invalidate()
        timer = nil
    }
    
    private func scroll() {
        
        guard self.superview != nil else {
            stopTimer()
            return
        }
        
        textIndex += 1
        
        collectionView.scrollToItem(at: IndexPath(item: textIndex, section: 0), at: .top, animated: true)
        
        if textIndex >= (textArray.count-1) {
            
            textIndex = 0
            self.perform(#selector(scrollToFirstText), with: nil, afterDelay: 1)
        }
    }
    
    @objc private func scrollToFirstText() {
        
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredVertically, animated: false)
    }
    
    deinit {
        stopTimer()
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

extension WYScrollText: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: collectionView.bounds.self.width, height: collectionView.bounds.size.height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return textArray.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: SctolTextCell = collectionView.dequeueReusableCell(withReuseIdentifier: "SctolTextCell", for: indexPath) as! SctolTextCell

        cell.textView.font = self.textFont
        cell.textView.textColor = self.textColor
        cell.textView.backgroundColor = contentColor
        cell.textView.text = textArray[indexPath.item]
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        guard !((textArray.count == 2) && (textArray.first == placeholder) && (textArray.last == placeholder)) else {
            return
        }
        if actionHandler != nil {
            
            actionHandler!((textIndex == textArray.count-1) ? 0 : textIndex)
        }
        delegate?.itemDidClick?((textIndex == textArray.count-1) ? 0 : textIndex)
    }
}

class SctolTextCell: UICollectionViewCell {
    
    lazy var textView: UILabel = {
    
        let label = UILabel()
        label.textAlignment = .left
        self.contentView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        return label
    }()
}
