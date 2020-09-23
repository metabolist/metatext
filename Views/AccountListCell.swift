// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

class AccountListCell: UITableViewCell {
    var viewModel: AccountViewModel?

    override func updateConfiguration(using state: UICellConfigurationState) {
        guard let viewModel = viewModel else { return }

        contentConfiguration = AccountContentConfiguration(viewModel: viewModel).updated(for: state)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let isPhoneIdiom = UIDevice.current.userInterfaceIdiom == .phone

        separatorInset.right = isPhoneIdiom ? 0 : layoutMargins.right
        separatorInset.left = isPhoneIdiom ? 0 : layoutMargins.left
    }
}
