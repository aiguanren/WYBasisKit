//
//  WYChatBasicCell.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/14.
//

import UIKit
import Kingfisher
import SnapKit

/// 通用聊天配置选项
public struct WYBasicChatConfig {
    
    /// 消息显示的最小时间跨度，默认300秒
    public var messageMinimumTimeSpan: Double = 300
    
    /// 消息发送失败后cell上显示的状态图标
    public var messageSendErrorImage: UIImage = UIImage.wy_find("WYChatError", inBundle: WYChatSourceBundle)
    
    /// 消息发送中cell上显示的状态图标
    public var messageSendingGif : WYGifInfo = UIImage.wy_animatedParse(name: "WYChatSending", inBundle: WYChatSourceBundle)!
    
    /// 消息发送状态图标size
    public var messageSendingStateSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(15), height: UIDevice.wy_screenWidth(15))
    
    /// 消息发送状态图标距离消息内容(气泡)边界的偏移量
    public var messageSendingStateOffset: CGFloat = UIDevice.wy_screenWidth(10)
    
    /// 默认头像(placeholder)
    public var defaultAvatar: UIImage = UIImage.wy_createImage(from: .wy_random)

    /// 头像contentMode
    public var avatarContentMode: UIView.ContentMode = .scaleAspectFit
    
    /// 显示昵称时头像距离cell的偏移量
    public var avatarOffset: (sendor: CGPoint, receive: CGPoint) = (
        
        sendor: CGPoint(x: UIDevice.wy_screenWidth(15), y: 0),
        
        receive: CGPoint(x: UIDevice.wy_screenWidth(15), y: 0))

    /// 头像size
    public var avatarSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(50), height: UIDevice.wy_screenWidth(50))

    /// 头像圆角半径
    public var avatarCornerRadius: CGFloat = UIDevice.wy_screenWidth(5)
    
    /// 单聊时是否显示昵称
    public var showNicknameForSingle: (sendor: Bool, receive: Bool) = (sendor: false, receive: false)
    
    /// 群聊时是否显示昵称
    public var showNicknameForGroup: (sendor: Bool, receive: Bool) = (sendor: false, receive: true)
    
    /// 单聊时昵称距离时间控件的偏移量
    public var nameViewOffsetForSingle: (sendor: CGPoint, receive: CGPoint) = (
        
        sendor: CGPoint(x: -UIDevice.wy_screenWidth(20), y: UIDevice.wy_screenWidth(20)),
        
        receive: CGPoint(x: UIDevice.wy_screenWidth(20), y: UIDevice.wy_screenWidth(20)))
    
    /// 群聊时昵称距离时间控件的偏移量
    public var nameViewOffsetForGroup: (sendor: CGPoint, receive: CGPoint) = (
        
        sendor: CGPoint(x: -UIDevice.wy_screenWidth(20), y: UIDevice.wy_screenWidth(20)),
        
        receive: CGPoint(x: UIDevice.wy_screenWidth(20), y: UIDevice.wy_screenWidth(20)))

    /// 昵称字体、字号
    public var nicknameFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(13))

    /// 昵称字体颜色
    public var nicknameColor: UIColor = .black
    
    /// 时间控件顶部距离cell的偏移量
    public var timeViewOffset: CGFloat = UIDevice.wy_screenWidth(10)

    /// 时间字体、字号
    public var timeFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(13))

    /// 时间字体颜色
    public var timeColor: UIColor = .black
    
    /// 时间是否显示 上午/下午 标识
    public var showAmPmSymbol: Bool = false
    
    /// 是否显示已读未读标识(仅限单聊)
    public var showReadMark: Bool = false
    
    /// 已读未读标识的字体
    public var readMarkFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(10))
    
    /// 已读未读标识的字体颜色
    public var readMarkColor: (browse: UIColor, unread: UIColor) = (browse: .lightGray, unread: .blue)
    
    /// 已读未读标识距离消息内容(气泡)边界的偏移量(y用于距离底部的偏移量)
    public var readMarkOffset: CGPoint = CGPoint(x: UIDevice.wy_screenWidth(5), y: UIDevice.wy_screenWidth(5))
    
    /// 已读未读标识的文本
    public var readMarkText: (browse: String, unread: String) = (browse: "已读", unread: "未读")
    
    public init() {}
}

public class WYChatBasicCell: UITableViewCell {
    
    /// 当前登录用户的用户ID
    public var userID: String = ""
    
    /// 消息model
    public var message: WYChatMessageModel = WYChatMessageModel()
    
    /// 布局配置
    private var config: WYBasicChatConfig = WYBasicChatConfig()
    
    /// 头像控件
    public lazy var avatarView: UIImageView = {
        let avatarView: UIImageView = UIImageView()
        contentView.addSubview(avatarView)
        return avatarView
    }()
    
    /// 昵称控件
    public lazy var nicknameView: UILabel = {
        let nicknameView: UILabel = UILabel()
        contentView.addSubview(nicknameView)
        return nicknameView
    }()
    
    /// 时间控件
    public lazy var timeView: UILabel = {
        let timeView: UILabel = UILabel()
        contentView.addSubview(timeView)
        return timeView
    }()
    
    /// 已读、未读状态控件
    public lazy var readMarkView: UILabel? = {
        guard config.showReadMark == true else {
            return nil
        }
        let readMarkView: UILabel = UILabel()
        contentView.addSubview(readMarkView)
        return readMarkView
    }()
    
    /// loading控件
    public lazy var loadingView: UIImageView = {
        let imageView = UIImageView()
        contentView.addSubview(imageView)
        return imageView
    }()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
    
    /// 数据(页面)刷新
    public func updateContent(config: WYBasicChatConfig) {
        
        self.config = config
        
        avatarView.wy_clearVisual()
        avatarView.contentMode = config.avatarContentMode
        loadImage(avatarView)
        
        nicknameView.font = config.nicknameFont
        nicknameView.text = message.sendor.name
        nicknameView.textAlignment = message.isSender(userID) ? .right : .left
        if message.isSender(userID) {
            if message.group == nil {
                nicknameView.textColor = config.showNicknameForSingle.sendor ? config.nicknameColor : .clear
            }else {
                nicknameView.textColor = config.showNicknameForGroup.sendor ? config.nicknameColor : .clear
            }
        }else {
            if message.group == nil {
                nicknameView.textColor = config.showNicknameForSingle.receive ? config.nicknameColor : .clear
            }else {
                nicknameView.textColor = config.showNicknameForGroup.receive ? config.nicknameColor : .clear
            }
        }
        nicknameView.backgroundColor = .clear
        
        timeView.text = message.timeFormat ?? sharedTimeText(message.timestamp, message.clientTimestamp ?? String.wy_sharedDeviceTimestamp(), message.lastMessageTimestamp)
        timeView.font = config.timeFont
        timeView.textColor = config.timeColor
        
        updateMessageState()
        
        updateConstraints()
    }
    
    public override func updateConstraints() {
        super.updateConstraints()
        
        timeView.snp.updateConstraints { make in
            make.centerX.equalToSuperview()
            if timeView.text?.isEmpty ?? true {
                make.top.equalToSuperview().offset(config.timeViewOffset)
                make.height.equalTo(0)
            }else {
                make.top.equalToSuperview().offset(config.timeViewOffset)
                make.height.equalTo(config.timeFont.lineHeight)
            }
        }
        
        nicknameView.snp.updateConstraints { make in
            make.height.equalTo(((nicknameView.textColor == .clear) ? 0 : config.nicknameFont.lineHeight))
            if message.isSender(userID) {
                make.left.equalToSuperview().offset(abs(chatTextConfig.basic.avatarOffset.receive.x) + config.avatarSize.width + abs(chatTextConfig.bubbleMaxOffset))
                if message.group == nil {
                    make.width.equalTo(sharedContentMaxWidth() - abs(chatTextConfig.bubbleOffsetForSingle.sendor.x))
                    make.top.equalTo(timeView.snp.bottom).offset((timeView.text?.isEmpty ?? true) ? 0 : config.nameViewOffsetForSingle.sendor.y)
                }else {
                    make.width.equalTo(sharedContentMaxWidth() - abs(chatTextConfig.bubbleOffsetForGroup.sendor.x))
                    make.top.equalTo(timeView.snp.bottom).offset((timeView .text?.isEmpty ?? true) ? 0 : config.nameViewOffsetForGroup.sendor.y)
                }
            }else {
                if message.group == nil {
                    
                    make.left.equalToSuperview().offset(abs(chatTextConfig.basic.avatarOffset.receive.x) + config.avatarSize.width + abs(config.nameViewOffsetForSingle.receive.x))
                    make.width.equalTo(sharedContentMaxWidth() - abs(chatTextConfig.bubbleOffsetForSingle.receive.x))
                    make.top.equalTo(timeView.snp.bottom).offset((timeView.text?.isEmpty ?? true) ? 0 : config.nameViewOffsetForSingle.receive.y)
                }else {
                    make.left.equalToSuperview().offset(abs(chatTextConfig.basic.avatarOffset.receive.x) + config.avatarSize.width + abs(config.nameViewOffsetForGroup.receive.x))
                    make.width.equalTo(sharedContentMaxWidth() - abs(chatTextConfig.bubbleOffsetForGroup.receive.x))
                    make.top.equalTo(timeView.snp.bottom).offset((timeView.text?.isEmpty ?? true) ? 0 : config.nameViewOffsetForGroup.receive.y)
                }
            }
        }
        
        avatarView.snp.updateConstraints { make in
            if message.isSender(userID) {
                make.top.equalTo(nicknameView.snp.bottom).offset(config.avatarOffset.sendor.y)
                make.left.equalToSuperview().offset(wy_width - config.avatarOffset.sendor.x - config.avatarSize.width)
            }else {
                make.top.equalTo(nicknameView.snp.bottom).offset(config.avatarOffset.receive.y)
                make.left.equalToSuperview().offset(config.avatarOffset.receive.x)
            }
            make.size.equalTo(config.avatarSize)
        }
        
        avatarView.wy_cornerRadius(config.avatarCornerRadius).wy_showVisual()
    }
    
    public func updateOtherConstraints(_ rely: UIView) {
        loadingView.snp.remakeConstraints { make in
            make.size.equalTo(config.messageSendingStateSize)
            make.centerY.equalTo(rely)
            if message.isSender(userID) {
                make.right.equalTo(rely.snp.left).offset(-config.messageSendingStateOffset)
            }else {
                make.left.equalTo(rely.snp.right).offset(config.messageSendingStateOffset)
            }
        }
        
        readMarkView?.snp.remakeConstraints { make in
            if message.isSender(userID) {
                make.right.equalTo(rely.snp.left).offset(-config.readMarkOffset.x)
            }else {
                make.left.equalTo(rely.snp.right).offset(config.readMarkOffset.x)
            }
            make.bottom.equalTo(rely).offset(-config.readMarkOffset.y)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    public override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

public extension WYChatBasicCell {
    
    func updateMessageState() {
        loadingView.isHidden = (message.sendState == .success)
        switch message.sendState {
        case .success:
            loadingView.stopAnimating()
            break
        case .sending, .notSent:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                
                self.loadingView.animationDuration = self.config.messageSendingGif.animationDuration.wy_convertTo(Double.self)
                self.loadingView.animationImages = self.config.messageSendingGif.animationImages
                self.loadingView.animationRepeatCount = 0
                self.loadingView.startAnimating()
            }
            break
        case .failed:
            loadingView.stopAnimating()
            loadingView.image = config.messageSendErrorImage
            break
        }
        
        readMarkView?.font = config.readMarkFont
        
        if message.readers.wy_convertTo(Double.self) > 0 {
            readMarkView?.textColor = config.readMarkColor.browse
            readMarkView?.text = config.readMarkText.browse
        }else {
            readMarkView?.textColor = config.readMarkColor.unread
            readMarkView?.text = config.readMarkText.unread
        }
    }
    
    func loadImage(_ imageView: UIImageView) {
         
        let imageCache = try! ImageCache(name: message.sendor.name, cacheDirectoryURL: createDirectory(directory: .cachesDirectory, subDirectory: "WYBasisKit/WYChatView/\(message.sendor.name)"))
        
        let urlString: String = message.sendor.avatar.downloadPath
        
        avatarView.kf.setImage(with: URL(string: urlString), placeholder: config.defaultAvatar, options: [.targetCache(imageCache)]) { [weak self] result in
            
            guard let self = self else { return }
            
            switch result {
            case .success(let source):
                imageView.image = source.image
                self.message.sendor.avatar.localPath = imageCache.cachePath(forKey: urlString)
                self.message.sendor.avatar.id = urlString.wy_sha256()
                self.message.sendor.avatar.name = urlString.wy_sha256()
                break
            case .failure(let error):
                WYLogManager.output("\(error)")
                break
            }
        }
    }
    
    /// 创建一个指定目录/文件夹
    func createDirectory(directory: FileManager.SearchPathDirectory, subDirectory: String) -> URL {
        
        let directoryURLs = FileManager.default.urls(for: directory,
                                                        in: .userDomainMask)
        
        let savePath = (directoryURLs.first ?? URL(fileURLWithPath: NSTemporaryDirectory())).appendingPathComponent(subDirectory)
        let isExists: Bool = FileManager.default.fileExists(atPath: savePath.path)
        
        if !isExists {
            guard let _ = try? FileManager.default.createDirectory(at: savePath, withIntermediateDirectories: true, attributes: nil) else {
                fatalError("创建 \(savePath) 路径失败")
            }
        }
        return savePath
    }
    
    /**
     *  依据message.timestamp显示格式化后的消息发送时间
     *  默认聊天消息时间显示说明
          1、当天的消息，以每5分钟为一个跨度显示时间，具体格式为：HH:mm，如 12:12
          2、昨天的消息，显示格式为：昨天 HH:mm，如 昨天 12:12
          3、消息超过2天、小于1周，显示星期+收发消息的时间，具体格式为：星期几 HH:mm，如    星期日 12:12
          4、消息大于1周且是今年的消息，显示格式为：MMdd HH:mm，如 12月12日 12:12
          5、消息时间不是今年的消息，显示格式为：yyyyMMdd HH:mm，如 2022年12月12日 12:12
     */
    func sharedTimeText(_ messageTimestamp: String, _ clientTimestamp: String = String.wy_sharedDeviceTimestamp(), _ lastMessageTimestamp: String, _ locale: Locale = Locale(identifier: "zh_CN")) -> String {
        
        let showTime: Bool = ((NumberFormatter().number(from: messageTimestamp)?.doubleValue ?? 0) - (NumberFormatter().number(from: lastMessageTimestamp)?.doubleValue ?? 0) >= config.messageMinimumTimeSpan)
        
        guard showTime == true else {
            return ""
        }

        let timeDistance: WYTimeDistance = String.wy_timeIntervalCycle(messageTimestamp, clientTimestamp)
        
        switch timeDistance {
        case .today:
            return messageTimestamp.wy_timestampConvertDate(.HM, config.showAmPmSymbol)
            
        case .yesterday:
            return (WYLocalized("昨天", table: WYBasisKitConfig.kitLocalizableTable) + " " + messageTimestamp.wy_timestampConvertDate(.HM, config.showAmPmSymbol))
            
        case .yesterdayBefore, .withinWeek:
            
            let whatDay: [String] = [
                messageTimestamp.wy_timestampConvertDate(.YMDHM, config.showAmPmSymbol),
                WYLocalized("星期日", table: WYBasisKitConfig.kitLocalizableTable),
                WYLocalized("星期一", table: WYBasisKitConfig.kitLocalizableTable),
                WYLocalized("星期二", table: WYBasisKitConfig.kitLocalizableTable),
                WYLocalized("星期三", table: WYBasisKitConfig.kitLocalizableTable),
                WYLocalized("星期四", table: WYBasisKitConfig.kitLocalizableTable),
                WYLocalized("星期五", table: WYBasisKitConfig.kitLocalizableTable),
                WYLocalized("星期六", table: WYBasisKitConfig.kitLocalizableTable)]
            
            return whatDay[messageTimestamp.wy_whatDay.rawValue] + (messageTimestamp.wy_whatDay == .unknown ? "" : (" " + messageTimestamp.wy_timestampConvertDate(.HM, config.showAmPmSymbol)))
            
        case .withinSameMonth, .withinSameYear:
            
            let mm: String = WYLocalized("月", table: WYBasisKitConfig.kitLocalizableTable)
            let dd: String = WYLocalized("日", table: WYBasisKitConfig.kitLocalizableTable)
            
            return messageTimestamp.wy_timestampConvertDate(.custom(format: "MM\(mm)dd\(dd) HH:mm"), config.showAmPmSymbol)
            
        default:
            
            let yyyy: String = WYLocalized("年", table: WYBasisKitConfig.kitLocalizableTable)
            let mm: String = WYLocalized("月", table: WYBasisKitConfig.kitLocalizableTable)
            let dd: String = WYLocalized("日", table: WYBasisKitConfig.kitLocalizableTable)
            
            return messageTimestamp.wy_timestampConvertDate(.custom(format: "yyyy\(yyyy)MM\(mm)dd\(dd) HH:mm"), config.showAmPmSymbol)
        }
    }
    
    // 获取内容(气泡图)的最大显示宽度
    func sharedContentMaxWidth() -> CGFloat {
        
        if message.isSender(userID) {
            
            if message.group == nil {
                
                return (wy_width - abs(chatTextConfig.basic.avatarOffset.sendor.x) - abs(chatTextConfig.basic.avatarOffset.receive.x) - (chatTextConfig.basic.avatarSize.width * 2.0) - abs(chatTextConfig.bubbleMaxOffset)) - abs(config.nameViewOffsetForSingle.sendor.x) + abs(chatTextConfig.bubbleOffsetForSingle.sendor.x)
                
            }else {
                
                return (wy_width - abs(chatTextConfig.basic.avatarOffset.sendor.x) - abs(chatTextConfig.basic.avatarOffset.receive.x) - (chatTextConfig.basic.avatarSize.width * 2.0) - abs(chatTextConfig.bubbleMaxOffset)) - abs(config.nameViewOffsetForGroup.sendor.x) + abs(chatTextConfig.bubbleOffsetForGroup.sendor.x)
            }
            
        }else {
            if message.group == nil {
                
                return (wy_width - abs(chatTextConfig.basic.avatarOffset.sendor.x) - abs(chatTextConfig.basic.avatarOffset.receive.x) - (chatTextConfig.basic.avatarSize.width * 2.0) - abs(chatTextConfig.bubbleMaxOffset)) - abs(config.nameViewOffsetForSingle.receive.x) + abs(chatTextConfig.bubbleOffsetForSingle.receive.x)
                
            }else {
                
                return (wy_width - abs(chatTextConfig.basic.avatarOffset.sendor.x) - abs(chatTextConfig.basic.avatarOffset.receive.x) - (chatTextConfig.basic.avatarSize.width * 2.0) - abs(chatTextConfig.bubbleMaxOffset)) - abs(config.nameViewOffsetForGroup.receive.x) + abs(chatTextConfig.bubbleOffsetForGroup.receive.x)
            }
        }
    }
}
