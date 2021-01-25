// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public final class PostingReadingPreferencesViewModel: ObservableObject {
    @Published public var preferences: Identity.Preferences
    @Published public var alertItem: AlertItem?

    private let identification: Identification
    private var cancellables = Set<AnyCancellable>()

    public init(identification: Identification) {
        self.identification = identification
        preferences = identification.identity.preferences

        identification.$identity
            .map(\.preferences)
            .dropFirst()
            .removeDuplicates()
            .assign(to: &$preferences)

        $preferences
            .dropFirst()
            .flatMap(identification.service.updatePreferences)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }
}
