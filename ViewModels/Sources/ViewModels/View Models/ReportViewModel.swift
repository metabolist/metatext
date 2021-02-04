// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class ReportViewModel: ObservableObject {
    @Published public var elements: ReportElements
    public let events: AnyPublisher<Event, Never>
    public let statusViewModel: StatusViewModel?
    @Published public private(set) var loading = false
    @Published public var alertItem: AlertItem?

    private let accountService: AccountService
    private let eventsSubject = PassthroughSubject<Event, Never>()
    private var cancellables = Set<AnyCancellable>()

    public init(accountService: AccountService, statusService: StatusService? = nil, identityContext: IdentityContext) {
        self.accountService = accountService
        elements = ReportElements(accountId: accountService.account.id)
        events = eventsSubject.eraseToAnyPublisher()

        if let statusService = statusService {
            statusViewModel = StatusViewModel(statusService: statusService,
                                              identityContext: identityContext,
                                              eventsSubject: .init())
            elements.statusIds.insert(statusService.status.displayStatus.id)
        } else {
            statusViewModel = nil
        }
    }
}

public extension ReportViewModel {
    enum Event {
        case reported
    }

    var accountName: String { "@".appending(accountService.account.acct) }

    var accountHost: String {
        URL(string: accountService.account.url)?.host ?? ""
    }

    var isLocalAccount: Bool { accountService.isLocal }

    func report() {
        accountService.report(elements)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in self?.loading = true })
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { [weak self] in
                guard let self = self else { return }

                self.loading = false

                if $0 == .finished {
                    self.eventsSubject.send(.reported)
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}
