//
//  WYChatLuckyMoneyModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 红包、转账收款状态
@frozen public enum WYChatFundsState: Int {
    
    /// 待收款
    case unreceived = 0
    
    /// 已收款
    case received
    
    /// 超时退回
    case timeout
    
    /// 用户退回
    case `return`
}

/// 红包消息Model
public struct WYChatLuckyMoneyModel {
    
    /// id
    public var id: String
    
    /// 大封面
    public var fullCover: WYChatAssetsModel
    
    /// 小封面
    public var smallCover: WYChatAssetsModel
    
    /// 封面视频
    public var coverVideo: WYChatAssetsModel
    
    /// 金额
    public var amounts: String
    
    /// 红包个数(1为个人红包，否则为多人红包)
    public var numberOfLuckyMoney: Int
    
    /// 已抢红包个数
    public var numberOfRobbed: Int
    
    /// 红包已抢金额
    public var amountsStolen: Double
    
    /// 收款状态
    public var state: WYChatFundsState
    
    /// 备注
    public var remarks: String
    
    /// 说明(xx红包)
    public var notes: String
    
    /// 初始化方法
    public init(id: String = "",
                fullCover: WYChatAssetsModel = WYChatAssetsModel(),
                smallCover: WYChatAssetsModel = WYChatAssetsModel(),
                coverVideo: WYChatAssetsModel = WYChatAssetsModel(),
                amounts: String = "",
                numberOfLuckyMoney: Int = 1,
                numberOfRobbed: Int = 0,
                amountsStolen: Double = 0,
                state: WYChatFundsState = .unreceived,
                remarks: String = "",
                notes: String = "") {
        self.id = id
        self.fullCover = fullCover
        self.smallCover = smallCover
        self.coverVideo = coverVideo
        self.amounts = amounts
        self.numberOfLuckyMoney = numberOfLuckyMoney
        self.numberOfRobbed = numberOfRobbed
        self.amountsStolen = amountsStolen
        self.state = state
        self.remarks = remarks
        self.notes = notes
    }
}
