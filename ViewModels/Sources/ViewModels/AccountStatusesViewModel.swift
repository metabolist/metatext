// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public class AccountStatusesViewModel: StatusListViewModel {
    @Published var collection: AccountStatusCollection
    private let accountStatusesService: AccountStatusesService
    private var cancellables = Set<AnyCancellable>()

    init(accountStatusesService: AccountStatusesService) {
        self.accountStatusesService = accountStatusesService

        var collection = Published(initialValue: AccountStatusCollection.statuses)

        _collection = collection

        super.init(
            statusListService: accountStatusesService.statusListService(
                    collectionPublisher: collection.projectedValue.eraseToAnyPublisher()))
    }

    public override func request(maxID: String? = nil, minID: String? = nil) {
        if case .statuses = collection, maxID == nil {
            accountStatusesService.fetchPinnedStatuses()
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { _ in }
                .store(in: &cancellables)
        }

        super.request(maxID: maxID, minID: minID)
    }

    override func isPinned(status: Status) -> Bool {
        collection == .statuses && statusIDs.first?.contains(status.id) ?? false
    }
}
