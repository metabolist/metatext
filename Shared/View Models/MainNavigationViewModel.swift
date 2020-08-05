// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class MainNavigationViewModel: ObservableObject {
    @Published private(set) var identity: Identity
    @Published private(set) var recentIdentities = [Identity]()
    @Published var presentingSettings = false
    @Published var alertItem: AlertItem?
    var selectedTab: Tab? = .timelines

    private let environment: AppEnvironment
    private let networkClient: MastodonClient
    private var cancellables = Set<AnyCancellable>()

    init(identityID: String, environment: AppEnvironment) throws {
        self.environment = environment
        networkClient = MastodonClient(configuration: environment.URLSessionConfiguration)

        let observation = environment.identityDatabase.identityObservation(id: identityID).share()
        var initialIdentity: Identity?

        observation.first().sink(
            receiveCompletion: { _ in },
            receiveValue: { initialIdentity = $0 })
            .store(in: &cancellables)

        guard let identity = initialIdentity else { throw IdentityDatabaseError.identityNotFound }

        self.identity = identity
        networkClient.instanceURL = identity.url

        do {
            networkClient.accessToken = try environment.secrets.item(.accessToken, forIdentityID: identity.id)
        } catch {
            alertItem = AlertItem(error: error)
        }

        observation.assignErrorsToAlertItem(to: \.alertItem, on: self).assign(to: &$identity)
        environment.identityDatabase.recentIdentitiesObservation(excluding: identityID)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$recentIdentities)

        environment.identityDatabase.updateLastUsedAt(identityID: identityID)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink(receiveValue: {})
            .store(in: &cancellables)
    }
}

extension MainNavigationViewModel {
    func refreshIdentity() {
        let id = identity.id

        if networkClient.accessToken != nil {
            networkClient.request(AccountEndpoint.verifyCredentials)
                .map { ($0, id) }
                .flatMap(environment.identityDatabase.updateAccount)
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink(receiveValue: {})
                .store(in: &cancellables)
        }

        networkClient.request(InstanceEndpoint.instance)
            .map { ($0, id) }
            .flatMap(environment.identityDatabase.updateInstance)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink(receiveValue: {})
            .store(in: &cancellables)
    }

    func settingsViewModel() -> SettingsViewModel {
        SettingsViewModel(identity: _identity, environment: environment)
    }
}

extension MainNavigationViewModel {
    enum Tab: CaseIterable {
        case timelines
        case search
        case notifications
        case messages
    }
}

extension MainNavigationViewModel.Tab {
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

extension MainNavigationViewModel.Tab: Identifiable {
    var id: Self { self }
}
