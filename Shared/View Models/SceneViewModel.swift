// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class SceneViewModel: ObservableObject {
    @Published private(set) var identity: Identity?
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
                .flatMap(identityDatabase.updateAccount)
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink(receiveValue: {})
                .store(in: &cancellables)
        }

        networkClient.request(InstanceEndpoint.instance)
            .map { ($0, identity.id) }
            .flatMap(identityDatabase.updateInstance)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink(receiveValue: {})
            .store(in: &cancellables)
    }

    func addIdentityViewModel() -> AddIdentityViewModel {
        let addAccountViewModel = AddIdentityViewModel(
            networkClient: networkClient,
            identityDatabase: identityDatabase,
            secrets: secrets)

        addAccountViewModel.$addedIdentityID
            .compactMap { $0 }
            .sink(receiveValue: changeIdentity(id:))
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

    private func changeIdentity(id: String) {
        identityDatabase.identityObservation(id: id)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .handleEvents(receiveOutput: { [weak self] in
                guard let self = self, let identity = $0 else { return }

                self.recentIdentityID = identity.id
                self.networkClient.instanceURL = identity.url

                do {
                    self.networkClient.accessToken = try self.secrets.item(.accessToken, forIdentityID: identity.id)
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
