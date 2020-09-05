// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public class ListsViewModel: ObservableObject {
    @Published public private(set) var lists = [MastodonList]()
    @Published public private(set) var creatingList = false
    @Published public var alertItem: AlertItem?

    private let identityService: IdentityService
    private var cancellables = Set<AnyCancellable>()

    init(identityService: IdentityService) {
        self.identityService = identityService

        identityService.listsObservation()
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
        identityService.refreshLists()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }

    func createList(title: String) {
        identityService.createList(title: title)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.creatingList = true },
                receiveCompletion: { [weak self] _ in self?.creatingList = false })
            .sink { _ in }
            .store(in: &cancellables)
    }

    func delete(list: MastodonList) {
        identityService.deleteList(id: list.id)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }
}
