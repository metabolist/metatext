// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class SceneViewModel: ObservableObject {
    @Published private(set) var identity: Identity? {
        didSet {
            if let identity = identity {
                recentIdentityID = identity.id
                networkClient.instanceURL = identity.url

                do {
                    networkClient.accessToken = try secrets.item(.accessToken, forIdentityID: identity.id)
                } catch {
                    alertItem = AlertItem(error: error)
                }
            }
        }
    }

    @Published var alertItem: AlertItem?
    @Published var presentingSettings = false
    var selectedTopLevelNavigation: TopLevelNavigation? = .timelines

    private let networkClient: MastodonClient
    private let identityDatabase: IdentityDatabase
    private let secrets: Secrets
    private let userDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

    init(networkClient: MastodonClient,
         identityDatabase: IdentityDatabase,
         secrets: Secrets,
         userDefaults: UserDefaults = .standard) {
        self.networkClient = networkClient
        self.identityDatabase = identityDatabase
        self.secrets = secrets
        self.userDefaults = userDefaults

        if let recentIdentityID = recentIdentityID {
            identity = try? identityDatabase.identity(id: recentIdentityID)
            refreshIdentity()
        }
    }
}

extension SceneViewModel {
    func refreshIdentity() {
        guard let identity = identity else { return }

        if networkClient.accessToken != nil {
            networkClient.request(AccountEndpoint.verifyCredentials)
                .map { ($0, identity.id) }
                .flatMap(identityDatabase.updateAccount)
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .assign(to: \.identity, on: self)
                .store(in: &cancellables)
        }

        networkClient.request(InstanceEndpoint.instance)
            .map { ($0, identity.id) }
            .flatMap(identityDatabase.updateInstance)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: \.identity, on: self)
            .store(in: &cancellables)
    }

    func addIdentityViewModel() -> AddIdentityViewModel {
        let addAccountViewModel = AddIdentityViewModel(
            networkClient: networkClient,
            identityDatabase: identityDatabase,
            secrets: secrets)

        addAccountViewModel.addedIdentity
            .sink(receiveValue: addIdentity(_:))
            .store(in: &cancellables)

        return addAccountViewModel
    }
}

private extension SceneViewModel {
    private static let recentIdentityIDKey = "recentIdentityID"

    private var recentIdentityID: String? {
        get { userDefaults.value(forKey: Self.recentIdentityIDKey) as? String }
        set { userDefaults.set(newValue, forKey: Self.recentIdentityIDKey) }
    }

    private func addIdentity(_ identity: Identity) {
        self.identity = identity
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
