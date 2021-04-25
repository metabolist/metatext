// Copyright © 2021 Metabolist. All rights reserved.

import UIKit
import ViewModels

struct AnnouncementReactionContentConfiguration {
    let viewModel: AnnouncementReactionViewModel
}

extension AnnouncementReactionContentConfiguration: UIContentConfiguration {
    func makeContentView() -> UIView & UIContentView {
        AnnouncementReactionView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> AnnouncementReactionContentConfiguration {
        self
    }
}
