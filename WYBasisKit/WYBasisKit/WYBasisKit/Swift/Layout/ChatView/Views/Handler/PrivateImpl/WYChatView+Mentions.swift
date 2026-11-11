//
//  WYChatView+Mentions.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 用户提及的文本位置与身份
extension WYChatView {
    private var wy_inputPlainText: String { chatInput.sharedEmojiAttributedText(attributed: chatInput.textView.attributedText).string }

    func wy_currentInputMentions() -> [WYChatMention] {
        guard !state.inputMentions.isEmpty else { return [] }
        wy_updateInputMentions(text: wy_inputPlainText)
        return state.inputMentions
    }

    private func wy_moveMentions(replacing range: NSRange, replacementLength: Int) {
        let end = NSMaxRange(range)
        let delta = replacementLength - range.length
        state.inputMentions = state.inputMentions.compactMap { value in
            var mention = value
            if NSMaxRange(mention.range) <= range.location { return mention }
            if mention.range.location < end { return nil }
            mention.range.location += delta
            return mention
        }
    }

    func wy_recordInputEdit(range: NSRange, replacement: String) {
        guard !state.inputMentions.isEmpty else { state.pendingMentionEdit = nil; return }
        let attributed = chatInput.textView.attributedText ?? NSAttributedString(string: "")
        guard range.location >= 0, range.location <= attributed.length, range.length >= 0, range.length <= attributed.length - range.location else { return }
        let old = wy_inputPlainText
        wy_updateInputMentions(text: old)
        let start = chatInput.sharedEmojiAttributedText(attributed: attributed.attributedSubstring(from: NSRange(location: 0, length: range.location))).string.utf16.count
        let length = chatInput.sharedEmojiAttributedText(attributed: attributed.attributedSubstring(from: range)).string.utf16.count
        state.pendingMentionEdit = (old, NSRange(location: start, length: length), replacement)
    }

    func wy_updateInputMentions(text: String) {
        guard !state.inputMentions.isEmpty else { state.pendingMentionEdit = nil; state.mentionText = text; return }
        if let edit = state.pendingMentionEdit {
            state.pendingMentionEdit = nil
            if state.mentionText == edit.old {
                wy_moveMentions(replacing: edit.range, replacementLength: edit.replacement.utf16.count)
                state.mentionText = (edit.old as NSString).replacingCharacters(in: edit.range, with: edit.replacement)
            }
        }
        let old = state.mentionText as NSString
        let new = text as NSString
        if old != new {
            var prefix = 0
            while prefix < min(old.length, new.length), old.character(at: prefix) == new.character(at: prefix) { prefix += 1 }
            var suffix = 0
            while suffix < min(old.length, new.length) - prefix, old.character(at: old.length - suffix - 1) == new.character(at: new.length - suffix - 1) { suffix += 1 }
            wy_moveMentions(replacing: NSRange(location: prefix, length: old.length - prefix - suffix), replacementLength: new.length - prefix - suffix)
        }
        state.inputMentions = state.inputMentions.filter { mention in
            mention.range.location >= 0 && mention.range.length >= 0 && mention.range.location <= new.length && mention.range.length <= new.length - mention.range.location && new.substring(with: mention.range) == mention.text
        }
        state.mentionText = text
    }

    func wy_applyInputDraft(_ text: String, mentions: [WYChatMention], replacesInput: Bool) -> Bool {
        let input = chatInput
        let editor = input.textView
        editor.unmarkText()
        let attributed = editor.attributedText ?? NSAttributedString(string: "")
        let location = replacesInput ? 0 : min(max(0, editor.selectedRange.location), attributed.length)
        let length = replacesInput ? attributed.length : min(max(0, editor.selectedRange.length), attributed.length - location)
        let start = input.sharedEmojiAttributedText(attributed: attributed.attributedSubstring(from: NSRange(location: 0, length: location))).string.utf16.count
        let selected = input.sharedEmojiAttributedText(attributed: attributed.attributedSubstring(from: NSRange(location: location, length: length))).string.utf16.count
        let current = wy_inputPlainText
        wy_updateInputMentions(text: current)
        let updated = (current as NSString).replacingCharacters(in: NSRange(location: start, length: selected), with: text)
        let value = input.sharedEmojiAttributed(string: updated)
        if configuration.input.inputTextLength > 0 && value.length > configuration.input.inputTextLength { return false }
        if input.textRowGreaterThan(row: configuration.input.inputTextMaximumNumberOfLines, attributedText: value) { return false }
        wy_moveMentions(replacing: NSRange(location: start, length: selected), replacementLength: text.utf16.count)
        for value in mentions {
            var mention = value
            guard mention.range.location >= 0, mention.range.length >= 0, mention.range.location <= text.utf16.count, mention.range.length <= text.utf16.count - mention.range.location, (text as NSString).substring(with: mention.range) == mention.text else { continue }
            mention.range.location += start
            state.inputMentions.append(mention)
        }
        state.mentionText = updated
        editor.attributedText = value
        input.textViewDidChange(editor, silence: true)
        let actual = wy_inputPlainText
        wy_updateInputMentions(text: actual)
        state.inputMentions.sort { $0.range.location < $1.range.location }
        let prefix = (actual as NSString).substring(to: min(actual.utf16.count, start + text.utf16.count))
        let cursor = min(editor.attributedText.length, input.sharedEmojiAttributed(string: prefix).length)
        editor.selectedRange = NSRange(location: cursor, length: 0)
        return true
    }

    func wy_activateInputDraft() {
        wy_setPanel(.done, dismissKeyboard: false)
        if chatInput.textView.isHidden { chatInput.textVoiceView.sendActions(for: .touchUpInside) }
        chatInput.textView.becomeFirstResponder()
        wy_textDidChanged(text: wy_inputPlainText)
    }

    func wy_insertMention(_ user: WYChatUserModel) -> Bool {
        guard !user.id.isEmpty else { return false }
        let token = configuration.basic.mentionPrefix + (user.name.isEmpty ? user.id : user.name)
        let mention = WYChatMention(user: user, text: token, range: NSRange(location: 0, length: token.utf16.count))
        guard wy_applyInputDraft(token + configuration.basic.mentionSuffix, mentions: [mention], replacesInput: false) else { return false }
        wy_activateInputDraft()
        return true
    }
}
