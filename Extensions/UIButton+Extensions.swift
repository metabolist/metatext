// Copyright © 2020 Metabolist. All rights reserved.

import UIKit

extension UIButton {
    func setAttributedLocalizedTitle(localizationKey: String, count: Int) {
        let localizedTitle = String.localizedStringWithFormat(NSLocalizedString(localizationKey, comment: ""), count)

        setAttributedTitle(localizedTitle.countEmphasizedAttributedString(count: count), for: .normal)
        setAttributedTitle(
            localizedTitle.countEmphasizedAttributedString(count: count, highlighted: true),
            for: .highlighted)
    }
}
