// Copyright © 2021 Metabolist. All rights reserved.

import UIKit

class SeparatorConfiguredTableViewCell: UITableViewCell {
    override func layoutSubviews() {
        super.layoutSubviews()

        if UIDevice.current.userInterfaceIdiom == .phone {
            separatorInset.left = 0
            separatorInset.right = 0
        } else {
            separatorInset.left = layoutMargins.left
            separatorInset.right = layoutMargins.right
        }
    }
}
