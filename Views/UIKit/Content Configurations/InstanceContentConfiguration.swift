// Copyright © 2021 Metabolist. All rights reserved.

import UIKit
import ViewModels

struct InstanceContentConfiguration {
    let viewModel: InstanceViewModel
}

extension InstanceContentConfiguration: UIContentConfiguration {
    func makeContentView() -> UIView & UIContentView {
        InstanceView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> InstanceContentConfiguration {
        self
    }
}
