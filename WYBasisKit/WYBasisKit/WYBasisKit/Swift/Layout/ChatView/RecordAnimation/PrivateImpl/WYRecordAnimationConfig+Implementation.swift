//
//  WYRecordAnimationConfig+Implementation.swift
//  WYBasisKit
//

import UIKit
import AVFoundation

extension WYRecordAnimationConfig {
    var wy_audioBufferFrameCount: AVAudioFrameCount { AVAudioFrameCount(min(65_536, max(1, audioBufferFrameCount))) }

    static let recognitionSurfaceColor = UIColor { traits in
        traits.userInterfaceStyle == .dark ? .wy_hex("#25262A") : .wy_hex("#F6F6F6")
    }

    func wy_withChatBackground(_ background: UIColor?) -> Self {
        guard let background, recognitionOverlayBackgroundColor === Self.recognitionSurfaceColor else { return self }
        var config = self
        config.recognitionOverlayBackgroundColor = background
        if recognitionEmoji.backgroundColor === Self.recognitionSurfaceColor { config.recognitionEmoji.backgroundColor = background }
        if recognitionEmoji.headerBackgroundColor === Self.recognitionSurfaceColor { config.recognitionEmoji.headerBackgroundColor = config.recognitionEmoji.backgroundColor }
        return config
    }
}
