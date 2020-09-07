// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public class PostingReadingPreferencesViewModel: ObservableObject {
    @Published public var preferences: Identity.Preferences
    @Published public var alertItem: AlertItem?

    private let environment: IdentifiedEnvironment
    private var cancellables = Set<AnyCancellable>()

    init(environment: IdentifiedEnvironment) {
        self.environment = environment
        preferences = environment.identity.preferences

        environment.$identity
            .map(\.preferences)
            .dropFirst()
            .removeDuplicates()
            .assign(to: &$preferences)

        $preferences
            .dropFirst()
            .flatMap(environment.identityService.updatePreferences)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }
}
