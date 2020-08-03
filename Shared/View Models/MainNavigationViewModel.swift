// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class MainNavigationViewModel: ObservableObject {
    var selectedTab: Tab? = .timelines
    @Published var presentingSettings = false
    @Published private(set) var alertItem: AlertItem?
    @Published private(set) var handle: String
    @Published private(set) var image: URL?

    private let environment: AppEnvironment
    private let identity: CurrentValuePublisher<Identity>
    private let networkClient: MastodonClient
    private var cancellables = Set<AnyCancellable>()

    init(identity: CurrentValuePublisher<Identity>, environment: AppEnvironment) {
        self.identity = identity
        self.environment = environment
        networkClient = MastodonClient(configuration: environment.URLSessionConfiguration)

        networkClient.instanceURL = identity.value.url

        do {
            networkClient.accessToken = try environment.secrets.item(.accessToken, forIdentityID: identity.value.id)
        } catch {
            alertItem = AlertItem(error: error)
        }

        handle = identity.value.handle
        identity.map(\.handle).assign(to: &$handle)

        image = identity.value.image
        identity.map(\.image).assign(to: &$image)
    }
}

extension MainNavigationViewModel {
    func refreshIdentity() {
        let id = identity.value.id

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
        SettingsViewModel(identity: identity, environment: environment)
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
