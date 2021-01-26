// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class ListsViewModel: ObservableObject {
    @Published public private(set) var lists = [List]()
    @Published public private(set) var creatingList = false
    @Published public var alertItem: AlertItem?
    public let identityContext: IdentityContext

    private var cancellables = Set<AnyCancellable>()

    public init(identityContext: IdentityContext) {
        self.identityContext = identityContext

        identityContext.service.listsPublisher()
            .map {
                $0.compactMap {
                    guard case let .list(list) = $0 else { return nil }

                    return list
                }
            }
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$lists)
    }
}

public extension ListsViewModel {
    func refreshLists() {
        identityContext.service.refreshLists()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }

    func createList(title: String) {
        identityContext.service.createList(title: title)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.creatingList = true },
                receiveCompletion: { [weak self] _ in self?.creatingList = false })
            .sink { _ in }
            .store(in: &cancellables)
    }

    func delete(list: List) {
        identityContext.service.deleteList(id: list.id)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }
}
