// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class DomainBlocksViewModel: ObservableObject {
    @Published public private(set) var domainBlocks = [String]()
    @Published public var alertItem: AlertItem?
    @Published public private(set) var loading = false

    private let service: DomainBlocksService
    private var nextPageMaxId: String?
    private var cancellables = Set<AnyCancellable>()

    public init(service: DomainBlocksService) {
        self.service = service

        service.nextPageMaxId
            .sink { [weak self] in self?.nextPageMaxId = $0 }
            .store(in: &cancellables)
    }
}

public extension DomainBlocksViewModel {
    func request() {
        service.request(maxId: nextPageMaxId)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in self?.loading = true })
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { [weak self] in
                guard let self = self else { return }

                self.loading = false
                self.domainBlocks.append(contentsOf: Set($0).subtracting(Set(self.domainBlocks)))
            }
            .store(in: &cancellables)
    }

    func delete(domain: String) {
        service.delete(domain: domain)
            .collect()
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { [weak self] in
                if case .finished = $0 {
                    self?.domainBlocks.removeAll { $0 == domain }
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}
