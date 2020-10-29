// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

struct ConversationContentConfiguration {
    let viewModel: ConversationViewModel
}

extension ConversationContentConfiguration: UIContentConfiguration {
    func makeContentView() -> UIView & UIContentView {
        ConversationView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> ConversationContentConfiguration {
        self
    }
}
