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
                    self?.refreshPreferences()
                }
            })
            .assign(to: &$preferences)

        let id = environment.identity.id

        $preferences.dropFirst()
            .map { ($0, id) }
            .flatMap(environment.appEnvironment.identityDatabase.updatePreferences)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink(receiveValue: {})
            .store(in: &cancellables)
    }
}

extension PostingReadingPreferencesViewModel {
    func refreshPreferences() {
        let id = environment.identity.id
        let capturedPreferences = preferences

        environment.networkClient.request(PreferencesEndpoint.preferences)
            .map { (capturedPreferences.updated(from: $0), id) }
            .flatMap(environment.appEnvironment.identityDatabase.updatePreferences)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink(receiveValue: {})
            .store(in: &cancellables)
    }
}
