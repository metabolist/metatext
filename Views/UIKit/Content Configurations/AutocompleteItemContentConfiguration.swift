// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

struct AutocompleteItemContentConfiguration {
    let item: AutocompleteItem
    let identityContext: IdentityContext
}

extension AutocompleteItemContentConfiguration: UIContentConfiguration {
    func makeContentView() -> UIView & UIContentView {
        AutocompleteItemView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> AutocompleteItemContentConfiguration {
        self
    }
}
