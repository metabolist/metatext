// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class PostingReadingPreferencesViewModel: ObservableObject {
    @Published var preferences: Identity.Preferences
    @Published var alertItem: AlertItem?
    let handle: String

    private let identityRepository: IdentityRepository
    private var cancellables = Set<AnyCancellable>()

    init(identityRepository: IdentityRepository) {
        self.identityRepository = identityRepository
        preferences = identityRepository.identity.preferences
        handle = identityRepository.identity.handle

        identityRepository.$identity.map(\.preferences)
            .dropFirst()
            .removeDuplicates()
            .handleEvents(receiveOutput: { [weak self] in
                if $0.useServerPostingReadingPreferences {
                    self?.refreshServerPreferences()
                }
            })
            .assign(to: &$preferences)

        $preferences.dropFirst()
            .flatMap(identityRepository.updatePreferences)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink(receiveValue: {})
            .store(in: &cancellables)
    }
}

extension PostingReadingPreferencesViewModel {
    private func refreshServerPreferences() {
        identityRepository.refreshServerPreferences()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink(receiveValue: {})
            .store(in: &cancellables)
    }
}
