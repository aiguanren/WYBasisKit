//
//  WYChatTakePatModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 拍一拍model
public struct WYChatTakePatModel {
    
    /// 拍人者
    public var striking: WYChatUserModel
    
    /// 被拍者
    public var beaten: WYChatUserModel
    
    /// 被拍者拍一拍设置
    public var notes: String
    
    /// 初始化方法
    public init(striking: WYChatUserModel = WYChatUserModel(),
                beaten: WYChatUserModel = WYChatUserModel(),
                notes: String = "") {
        self.striking = striking
        self.beaten = beaten
        self.notes = notes
    }
}
