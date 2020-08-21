// Copyright © 2020 Metabolist. All rights reserved.

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
}
