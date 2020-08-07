// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class PostingReadingPreferencesViewModel: ObservableObject {
    @Published var preferences: Identity.Preferences
    @Published var alertItem: AlertItem?
    let handle: String

    private let environment: IdentifiedEnvironment
    private var cancellables = Set<AnyCancellable>()

    init(environment: IdentifiedEnvironment) {
        self.environment = environment
        preferences = environment.identity.preferences
        handle = environment.identity.handle

        environment.$identity.map(\.preferences)
            .dropFirst()
            .removeDuplicates()
            .handleEvents(receiveOutput: { [weak self] in
                if $0.useServerPostingReadingPreferences {
                    self?.refreshServerPreferences()
                }
            })
            .assign(to: &$preferences)

        $preferences.dropFirst()
            .flatMap(environment.updatePreferences)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink(receiveValue: {})
            .store(in: &cancellables)
    }
}

extension PostingReadingPreferencesViewModel {
    private func refreshServerPreferences() {
        environment.refreshServerPreferences()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink(receiveValue: {})
            .store(in: &cancellables)
    }
}
