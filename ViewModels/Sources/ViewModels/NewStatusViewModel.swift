// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class NewStatusViewModel: ObservableObject {
    @Published public private(set) var compositionViewModels = [CompositionViewModel]()
    @Published public private(set) var identification: Identification
    @Published public private(set) var authenticatedIdentities = [Identity]()
    @Published public var canChangeIdentity = true
    @Published public var alertItem: AlertItem?

    private let allIdentitiesService: AllIdentitiesService
    private let environment: AppEnvironment
    private var cancellables = Set<AnyCancellable>()

    public init(allIdentitiesService: AllIdentitiesService,
                identification: Identification,
                environment: AppEnvironment) {
        self.allIdentitiesService = allIdentitiesService
        self.identification = identification
        self.environment = environment
        compositionViewModels = [CompositionViewModel(
                                    composition: .init(id: environment.uuid(), text: ""),
                                    identification: identification,
                                    identificationPublisher: $identification.eraseToAnyPublisher())]
        allIdentitiesService.authenticatedIdentitiesPublisher()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$authenticatedIdentities)
    }
}

public extension NewStatusViewModel {
    func viewModel(indexPath: IndexPath) -> CompositionViewModel {
        compositionViewModels[indexPath.row]
    }

    func setIdentity(_ identity: Identity) {
        let identityService: IdentityService

        do {
            identityService = try allIdentitiesService.identityService(id: identity.id)
        } catch {
            alertItem = AlertItem(error: error)

            return
        }

        identification = Identification(
            identity: identity,
            publisher: identityService.identityPublisher(immediate: false)
                .assignErrorsToAlertItem(to: \.alertItem, on: self),
            service: identityService,
            environment: environment)
    }
}
