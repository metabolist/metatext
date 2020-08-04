// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class RootViewModel: ObservableObject {
    @Published private(set) var mainNavigationViewModel: MainNavigationViewModel?

    @Published private var identityID: String?
    private let environment: AppEnvironment
    private var cancellables = Set<AnyCancellable>()

    init(environment: AppEnvironment) {
        self.environment = environment
        identityID = environment.identityDatabase.mostRecentlyUsedIdentityID

        $identityID
            .tryMap {
                guard let id = $0 else { return nil }

                return try MainNavigationViewModel(identityID: id, environment: environment)
            }
            .replaceError(with: nil)
            .assign(to: &$mainNavigationViewModel)
    }
}

extension RootViewModel {
    func newIdentitySelected(id: String) {
        identityID = id
    }

    func addIdentityViewModel() -> AddIdentityViewModel {
        let addAccountViewModel = AddIdentityViewModel(environment: environment)

        addAccountViewModel.addedIdentityID
            .sink(receiveValue: newIdentitySelected(id:))
            .store(in: &cancellables)

        return addAccountViewModel
    }
}
