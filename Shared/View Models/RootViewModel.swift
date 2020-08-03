// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class RootViewModel: ObservableObject {
    @Published private(set) var identityID: String?
    @Published var alertItem: AlertItem?

    private let environment: AppEnvironment
    private var cancellables = Set<AnyCancellable>()

    init(environment: AppEnvironment) {
        self.environment = environment
        identityID = environment.preferences[.recentIdentityID]
    }
}

extension RootViewModel {
    func addIdentityViewModel() -> AddIdentityViewModel {
        let addAccountViewModel = AddIdentityViewModel(environment: environment)

        addAccountViewModel.addedIdentityID.map { $0 as String? }.assign(to: &$identityID)

        return addAccountViewModel
    }

    func mainNavigationViewModel(identityID: String) -> MainNavigationViewModel? {
        environment.preferences[.recentIdentityID] = identityID

        let identityObservation = environment.identityDatabase.identityObservation(id: identityID)
            .share()
        var initialIdentity: Identity?

        // setting `initialIdentity` works because of immediate scheduling
        identityObservation.sink(receiveCompletion: { _ in }, receiveValue: { initialIdentity = $0 })
            .store(in: &cancellables)
        identityObservation.map { $0.id }
            .catch { [weak self] _ -> AnyPublisher<String?, Never> in
                Just(self?.environment.preferences[.recentIdentityID]).eraseToAnyPublisher()
            }
            .assign(to: &$identityID)

        guard let presentIdentity = initialIdentity else { return nil }

        return MainNavigationViewModel(
            identity: CurrentValuePublisher(
                initial: presentIdentity,
                then: identityObservation.assignErrorsToAlertItem(to: \.alertItem, on: self)),
            environment: environment)
    }
}
