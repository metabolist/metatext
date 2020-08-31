// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import ServiceLayer

class PostingReadingPreferencesViewModel: ObservableObject {
    @Published var preferences: Identity.Preferences
    @Published var alertItem: AlertItem?

    private let identityService: IdentityService
    private var cancellables = Set<AnyCancellable>()

    init(identityService: IdentityService) {
        self.identityService = identityService
        preferences = identityService.identity.preferences

        identityService.$identity
            .map(\.preferences)
            .dropFirst()
            .removeDuplicates()
            .assign(to: &$preferences)

        $preferences
            .dropFirst()
            .flatMap(identityService.updatePreferences)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }
}
