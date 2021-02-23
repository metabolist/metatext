// Copyright © 2021 Metabolist. All rights reserved.

import UIKit
import ViewModels

struct EmojiContentConfiguration {
    let viewModel: EmojiViewModel
}

extension EmojiContentConfiguration: UIContentConfiguration {
    func makeContentView() -> UIView & UIContentView {
        EmojiView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> EmojiContentConfiguration {
        self
    }
}
