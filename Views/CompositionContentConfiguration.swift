// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

struct CompositionContentConfiguration {
    let viewModel: CompositionViewModel
}

extension CompositionContentConfiguration: UIContentConfiguration {
    func makeContentView() -> UIView & UIContentView {
        CompositionView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> CompositionContentConfiguration {
        self
    }
}
