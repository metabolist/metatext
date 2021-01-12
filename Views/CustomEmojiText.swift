// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI
import struct Mastodon.Emoji

struct CustomEmojiText: UIViewRepresentable {
    private let attributedText: NSMutableAttributedString
    private let emojis: [Emoji]
    private let textStyle: UIFont.TextStyle

    init(text: String, emojis: [Emoji], textStyle: UIFont.TextStyle) {
        attributedText = NSMutableAttributedString(string: text)
        self.emojis = emojis
        self.textStyle = textStyle
    }

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()

        label.font = UIFont.preferredFont(forTextStyle: textStyle)
        attributedText.insert(emojis: emojis, view: label)
        attributedText.resizeAttachments(toLineHeight: label.font.lineHeight)
        label.attributedText = attributedText

        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {

    }
}
