// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class AccountListViewModel: ObservableObject {
    @Published public private(set) var items = [[CollectionItem]]()
    @Published public var alertItem: AlertItem?
    public let navigationEvents: AnyPublisher<NavigationEvent, Never>
    public private(set) var nextPageMaxID: String?

    private let accountListService: AccountListService
    private var accounts = [String: Account]()
    private var accountViewModelCache = [Account: (AccountViewModel, AnyCancellable)]()
    private let navigationEventsSubject = PassthroughSubject<NavigationEvent, Never>()
    private let loadingSubject = PassthroughSubject<Bool, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(accountListService: AccountListService) {
        self.accountListService = accountListService
        navigationEvents = navigationEventsSubject.eraseToAnyPublisher()

        accountListService.accountSections
            .handleEvents(receiveOutput: { [weak self] in
                self?.cleanViewModelCache(newAccountSections: $0)
                self?.accounts = Dictionary(uniqueKeysWithValues: Set($0.reduce([], +)).map { ($0.id, $0) })
            })
            .map { $0.map { $0.map { CollectionItem(id: $0.id, kind: .account) } } }
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$items)

        accountListService.nextPageMaxIDs
            .sink { [weak self] in self?.nextPageMaxID = $0 }
            .store(in: &cancellables)
    }
}

extension AccountListViewModel: CollectionViewModel {
    public var collectionItems: AnyPublisher<[[CollectionItem]], Never> { $items.eraseToAnyPublisher() }

    public var title: AnyPublisher<String?, Never> { Just(nil).eraseToAnyPublisher() }

    public var alertItems: AnyPublisher<AlertItem, Never> { $alertItem.compactMap { $0 }.eraseToAnyPublisher() }

    public var loading: AnyPublisher<Bool, Never> { loadingSubject.eraseToAnyPublisher() }

    public var maintainScrollPositionOfItem: CollectionItem? {
        nil
    }

    public func request(maxID: String?, minID: String?) {
        accountListService.request(maxID: maxID, minID: minID)
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.loadingSubject.send(true) },
                receiveCompletion: { [weak self] _ in self?.loadingSubject.send(false) })
            .sink { _ in }
            .store(in: &cancellables)
    }

    public func itemSelected(_ item: CollectionItem) {
        switch item.kind {
        case .account:
            let navigationService = accountListService.navigationService
            let profileService: ProfileService

            if let account = accounts[item.id] {
                profileService = navigationService.profileService(account: account)
            } else {
                profileService = navigationService.profileService(id: item.id)
            }

            navigationEventsSubject.send(.profileNavigation(ProfileViewModel(profileService: profileService)))
        default:
            break
        }
    }

    public func canSelect(item: CollectionItem) -> Bool {
        true
    }

    public func viewModel(item: CollectionItem) -> Any? {
        switch item.kind {
        case .account:
            return accountViewModel(id: item.id)
        default:
            return nil
        }
    }
}

private extension AccountListViewModel {
    func accountViewModel(id: String) -> AccountViewModel? {
        guard let account = accounts[id] else { return nil }

        var accountViewModel: AccountViewModel

        if let cachedViewModel = accountViewModelCache[account]?.0 {
            accountViewModel = cachedViewModel
        } else {
            accountViewModel = AccountViewModel(
                accountService: accountListService.navigationService.accountService(account: account))
            accountViewModelCache[account] = (accountViewModel,
                                            accountViewModel.events
                                                .flatMap { $0 }
                                                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                                                .sink { [weak self] in
                                                    guard
                                                        let self = self,
                                                        let event = NavigationEvent($0)
                                                    else { return }

                                                    self.navigationEventsSubject.send(event)
                                                })
        }

        return accountViewModel
    }

    func cleanViewModelCache(newAccountSections: [[Account]]) {
        let newAccounts = Set(newAccountSections.reduce([], +))

        accountViewModelCache = accountViewModelCache.filter { newAccounts.contains($0.key) }
    }
}
