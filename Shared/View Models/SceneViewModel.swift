// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class SceneViewModel: ObservableObject {
    @Published private(set) var identity: Identity?
    @Published var alertItem: AlertItem?
    @Published var presentingSettings = false
    var selectedTopLevelNavigation: TopLevelNavigation? = .timelines

    private let networkClient: MastodonClient
    private let environment: AppEnvironment
    private var cancellables = Set<AnyCancellable>()

    init(networkClient: MastodonClient, environment: AppEnvironment) {
        self.networkClient = networkClient
        self.environment = environment

        if let recentIdentityID = environment.preferences[.recentIdentityID] as String? {
            changeIdentity(id: recentIdentityID)
        }
    }
}

extension SceneViewModel {
    func refreshIdentity() {
        guard let identity = identity else { return }

        if networkClient.accessToken != nil {
            networkClient.request(AccountEndpoint.verifyCredentials)
                .map { ($0, identity.id) }
                .flatMap(environment.identityDatabase.updateAccount)
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink(receiveValue: {})
                .store(in: &cancellables)
        }

        networkClient.request(InstanceEndpoint.instance)
            .map { ($0, identity.id) }
            .flatMap(environment.identityDatabase.updateInstance)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink(receiveValue: {})
            .store(in: &cancellables)
    }

    func addIdentityViewModel() -> AddIdentityViewModel {
        let addAccountViewModel = AddIdentityViewModel(networkClient: networkClient, environment: environment)

        addAccountViewModel.$addedIdentityID
            .compactMap { $0 }
            .sink(receiveValue: changeIdentity(id:))
            .store(in: &cancellables)

        return addAccountViewModel
    }
}

private extension SceneViewModel {
    private func changeIdentity(id: String) {
        environment.identityDatabase.identityObservation(id: id)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .handleEvents(receiveOutput: { [weak self] in
                guard let self = self, let identity = $0 else { return }

                self.networkClient.instanceURL = identity.url

                do {
                    self.networkClient.accessToken =
                        try self.environment.secrets.item(.accessToken, forIdentityID: identity.id)
                } catch {
                    self.alertItem = AlertItem(error: error)
                }
            })
            .assign(to: &$identity)

        refreshIdentity()
    }
}

extension SceneViewModel {
    enum TopLevelNavigation: CaseIterable {
        case timelines
        case search
        case notifications
        case messages
    }
}

extension SceneViewModel.TopLevelNavigation {
    var title: String {
        switch self {
        case .timelines: return "Timelines"
        case .search: return "Search"
        case .notifications: return "Notifications"
        case .messages: return "Messages"
        }
    }

    var systemImageName: String {
        switch self {
        case .timelines: return "house"
        case .search: return "magnifyingglass"
        case .notifications: return "bell"
        case .messages: return "envelope"
        }
    }
}

extension SceneViewModel.TopLevelNavigation: Identifiable {
    var id: Self { self }
}
