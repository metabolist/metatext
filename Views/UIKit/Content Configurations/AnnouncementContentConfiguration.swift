// Copyright © 2021 Metabolist. All rights reserved.

import UIKit
import ViewModels

struct AnnouncementContentConfiguration {
    let viewModel: AnnouncementViewModel
}

extension AnnouncementContentConfiguration: UIContentConfiguration {
    func makeContentView() -> UIView & UIContentView {
        AnnouncementView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> AnnouncementContentConfiguration {
        self
    }
}
