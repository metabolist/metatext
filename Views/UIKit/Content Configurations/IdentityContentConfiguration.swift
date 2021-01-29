// Copyright © 2021 Metabolist. All rights reserved.

import UIKit
import ViewModels

struct IdentityContentConfiguration {
    let viewModel: IdentityViewModel
}

extension IdentityContentConfiguration: UIContentConfiguration {
    func makeContentView() -> UIView & UIContentView {
        IdentityView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> IdentityContentConfiguration {
        self
    }
}
