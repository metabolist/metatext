// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class PostingReadingPreferencesViewModel: ObservableObject {
    @Published var preferences: Identity.Preferences {
        didSet {
            if preferences.useServerPostingReadingPreferences {
                identityService.refreshServerPreferences()
                    .assignErrorsToAlertItem(to: \.alertItem, on: self)
                    .sink(receiveValue: {})
                    .store(in: &cancellables)
            }
        }
    }

    @Published var alertItem: AlertItem?
    let handle: String

    private let identityService: IdentityService
    private var cancellables = Set<AnyCancellable>()

    init(identityService: IdentityService) {
        self.identityService = identityService
        preferences = identityService.identity.preferences
        handle = identityService.identity.handle

        identityService.$identity.map(\.preferences)
            .dropFirst()
            .removeDuplicates()
            .assign(to: &$preferences)

        $preferences.dropFirst()
            .flatMap(identityService.updatePreferences)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink(receiveValue: {})
            .store(in: &cancellables)
    }
}
