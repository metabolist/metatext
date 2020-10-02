// Copyright © 2020 Metabolist. All rights reserved.

import UIKit

class LoadMoreCell: UITableViewCell {
    override func layoutSubviews() {
        super.layoutSubviews()

        separatorInset.left = UIDevice.current.userInterfaceIdiom == .phone ? 0 : layoutMargins.left
    }
}
