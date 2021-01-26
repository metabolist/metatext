// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public final class PostingReadingPreferencesViewModel: ObservableObject {
    @Published public var preferences: Identity.Preferences
    @Published public var alertItem: AlertItem?

    private let identityContext: IdentityContext
    private var cancellables = Set<AnyCancellable>()

    public init(identityContext: IdentityContext) {
        self.identityContext = identityContext
        preferences = identityContext.identity.preferences

        identityContext.$identity
            .map(\.preferences)
            .dropFirst()
            .removeDuplicates()
            .assign(to: &$preferences)

        $preferences
            .dropFirst()
            .flatMap(identityContext.service.updatePreferences)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }
}
