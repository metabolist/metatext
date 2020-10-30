// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import UIKit

extension String {
    func countEmphasizedAttributedString(count: Int, highlighted: Bool = false) -> NSAttributedString {
        let countRange = (self as NSString).range(of: String.localizedStringWithFormat("%ld", count))

        let attributed = NSMutableAttributedString(
            string: self,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: highlighted ? UIColor.tertiaryLabel : UIColor.secondaryLabel
        ])
        attributed.addAttributes(
            [
                .font: UIFont.preferredFont(forTextStyle: .headline),
                .foregroundColor: highlighted ? UIColor.secondaryLabel : UIColor.label
            ],
            range: countRange)

        return attributed
    }

    func localizedBolding(displayName: String, emoji: [Emoji], label: UILabel) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(
            string: String.localizedStringWithFormat(
                NSLocalizedString(self, comment: ""),
                displayName))

        let range = (mutableString.string as NSString).range(of: displayName)

        if range.location != NSNotFound,
           let boldFontDescriptor = label.font.fontDescriptor.withSymbolicTraits([.traitBold]) {
            let boldFont = UIFont(descriptor: boldFontDescriptor, size: label.font.pointSize)

            mutableString.setAttributes([NSAttributedString.Key.font: boldFont], range: range)
        }

        mutableString.insert(emoji: emoji, view: label)
        mutableString.resizeAttachments(toLineHeight: label.font.lineHeight)

        return mutableString
    }
}
