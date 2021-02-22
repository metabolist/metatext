// Copyright © 2020 Metabolist. All rights reserved.

import Mastodon
import UIKit
import ViewModels

extension String {
    static var separator: Self {
        (Locale.autoupdatingCurrent.groupingSeparator ?? ",").appending(" ")
    }

    func height(width: CGFloat, font: UIFont) -> CGFloat {
        (self as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil)
            .height
    }

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

    func localizedBolding(displayName: String,
                          emojis: [Emoji],
                          label: AnimatedAttachmentLabel,
                          identityContext: IdentityContext) -> NSAttributedString {
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

        mutableString.insert(emojis: emojis, view: label, identityContext: identityContext)
        mutableString.resizeAttachments(toLineHeight: label.font.lineHeight)

        return mutableString
    }

    func appendingWithSeparator(_ string: Self) -> Self {
        appending(Self.separator).appending(string)
    }

    mutating func appendWithSeparator(_ string: Self) {
        append(Self.separator.appending(string))
    }
}
