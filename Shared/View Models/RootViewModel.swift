// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class RootViewModel: ObservableObject {
    @Published private(set) var identityID: UUID?
    private let environment: AppEnvironment
    private var cancellables = Set<AnyCancellable>()

    init(environment: AppEnvironment) {
        self.environment = environment
        identityID = environment.identityDatabase.mostRecentlyUsedIdentityID
    }
}

extension RootViewModel {
    func newIdentitySelected(id: UUID) {
        identityID = id

        environment.identityDatabase
            .updateLastUsedAt(identityID: id)
            .sink(receiveCompletion: { _ in }, receiveValue: {})
            .store(in: &cancellables)
    }

    func addIdentityViewModel() -> AddIdentityViewModel {
        AddIdentityViewModel(environment: environment)
    }

    func mainNavigationViewModel(identityID: UUID) -> MainNavigationViewModel? {
        let identityRepository: IdentityRepository

        do {
            identityRepository = try IdentityRepository(identityID: identityID, appEnvironment: environment)
        } catch {
            return nil
        }

        identityRepository.observationErrors
            .receive(on: RunLoop.main)
            .map { [weak self] _ in self?.environment.identityDatabase.mostRecentlyUsedIdentityID }
            .assign(to: &$identityID)

        return MainNavigationViewModel(identityRepository: identityRepository)
    }
}
