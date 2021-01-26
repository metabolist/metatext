// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class EditFilterViewModel: ObservableObject {
    @Published public var filter: Filter
    @Published public var saving = false
    @Published public var alertItem: AlertItem?
    public let saveCompleted: AnyPublisher<Void, Never>
    public let identityContext: IdentityContext

    public var date: Date {
        didSet { filter.expiresAt = date }
    }

    private let saveCompletedSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    public init(filter: Filter, identityContext: IdentityContext) {
        self.filter = filter
        self.identityContext = identityContext
        date = filter.expiresAt ?? Date()
        saveCompleted = saveCompletedSubject.eraseToAnyPublisher()
    }
}

public extension EditFilterViewModel {
    var isNew: Bool { filter.id == Filter.newFilterId }

    var isSaveDisabled: Bool { filter.phrase.isEmpty || filter.context.isEmpty }

    func toggleSelection(context: Filter.Context) {
        if filter.context.contains(context) {
            filter.context.removeAll { $0 == context }
        } else {
            filter.context.append(context)
        }
    }

    func save() {
        (isNew ? identityContext.service.createFilter(filter) : identityContext.service.updateFilter(filter))
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.saving = true },
                receiveCompletion: { [weak self] in
                    guard let self = self else { return }

                    self.saving = false

                    if case .finished = $0 {
                        self.saveCompletedSubject.send()
                    }
                })
            .sink { _ in }
            .store(in: &cancellables)
    }
}
