// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class RootViewModel: ObservableObject {
    @Published private(set) var mainNavigationViewModel: MainNavigationViewModel?

    private let identitiesService: IdentitiesService
    private var cancellables = Set<AnyCancellable>()

    init(identitiesService: IdentitiesService) {
        self.identitiesService = identitiesService

        newIdentitySelected(id: identitiesService.mostRecentlyUsedIdentityID)
    }
}

extension RootViewModel {
    func newIdentitySelected(id: UUID?) {
        guard let id = id else {
            mainNavigationViewModel = nil

            return
        }

        let identityService: IdentityService

        do {
            identityService = try identitiesService.identityService(id: id)
        } catch {
            return
        }

        identityService.observationErrors
            .receive(on: RunLoop.main)
            .map { [weak self] _ in self?.identitiesService.mostRecentlyUsedIdentityID }
            .sink(receiveValue: newIdentitySelected(id:))
            .store(in: &cancellables)

        identityService.updateLastUse()
            .sink(receiveCompletion: { _ in }, receiveValue: {})
            .store(in: &cancellables)

        mainNavigationViewModel = MainNavigationViewModel(identityService: identityService)
    }

    func deleteIdentity(id: UUID) {
        identitiesService.deleteIdentity(id: id)
            .sink(receiveCompletion: { _ in }, receiveValue: {})
            .store(in: &cancellables)
    }

    func addIdentityViewModel() -> AddIdentityViewModel {
        AddIdentityViewModel(authenticationService: identitiesService.authenticationService())
    }
}
