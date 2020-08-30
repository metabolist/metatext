// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import struct Mastodon.Emoji

struct CustomEmojiText: UIViewRepresentable {
    private let attributedText: NSMutableAttributedString
    private let emoji: [Emoji]
    private let textStyle: UIFont.TextStyle

    init(text: String, emoji: [Emoji], textStyle: UIFont.TextStyle) {
        attributedText = NSMutableAttributedString(string: text)
        self.emoji = emoji
        self.textStyle = textStyle
    }

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()

        label.font = UIFont.preferredFont(forTextStyle: textStyle)
        attributedText.insert(emoji: emoji, view: label)
        attributedText.resizeAttachments(toLineHeight: label.font.lineHeight)
        label.attributedText = attributedText

        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {

    }
}
