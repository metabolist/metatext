// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon

final public class AddRemoveFromListsViewModel: ObservableObject {
    public let accountViewModel: AccountViewModel
    @Published public private(set) var lists = [List]()
    @Published public private(set) var listIdsWithAccount = Set<List.Id>()
    @Published public private(set) var loaded = false
    @Published public var alertItem: AlertItem?

    private let listsViewModel: ListsViewModel
    private var cancellables = Set<AnyCancellable>()

    public init(accountViewModel: AccountViewModel) {
        self.accountViewModel = accountViewModel
        listsViewModel = ListsViewModel(identityContext: accountViewModel.identityContext)

        listsViewModel.$lists.assign(to: &$lists)
        listsViewModel.$alertItem.assign(to: &$alertItem)
    }
}

public extension AddRemoveFromListsViewModel {
    func refreshLists() {
        listsViewModel.refreshLists()
    }

    func fetchListsWithAccount() {
        accountViewModel.lists()
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { [weak self] in
                self?.listIdsWithAccount = Set($0.map(\.id))
                self?.loaded = true
            }
            .store(in: &cancellables)
    }

    func addToList(id: List.Id) {
        accountViewModel.addToList(id: id)
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { [weak self] in
                if case .finished = $0 {
                    self?.listIdsWithAccount.insert(id)
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func removeFromList(id: List.Id) {
        accountViewModel.removeFromList(id: id)
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { [weak self] in
                if case .finished = $0 {
                    self?.listIdsWithAccount.remove(id)
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}
