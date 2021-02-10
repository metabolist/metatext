// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public final class MuteViewModel: ObservableObject {
    @Published public var notifications = true
    @Published public var duration = Duration.indefinite
    @Published public private(set) var loading = false
    @Published public var alertItem: AlertItem?
    public let events: AnyPublisher<Event, Never>
    public let identityContext: IdentityContext

    private let accountService: AccountService
    private let eventsSubject = PassthroughSubject<Event, Never>()
    private var cancellables = Set<AnyCancellable>()

    public init(accountService: AccountService, identityContext: IdentityContext) {
        self.accountService = accountService
        self.identityContext = identityContext
        events = eventsSubject.eraseToAnyPublisher()
    }
}

public extension MuteViewModel {
    enum Event {
        case muted
    }

    enum Duration: Int, CaseIterable {
        case indefinite = 0
        case fiveMinutes = 300
        case thirtyMinutes = 1800
        case oneHour = 3600
        case sixHours = 21600
        case oneDay = 86400
        case threeDays = 259200
        case sevenDays = 604800
    }

    var accountName: String { "@".appending(accountService.account.acct) }

    func mute() {
        accountService.mute(notifications: notifications, duration: duration.rawValue)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in self?.loading = true })
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { [weak self] in
                guard let self = self else { return }

                self.loading = false

                if $0 == .finished {
                    self.eventsSubject.send(.muted)
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}

extension MuteViewModel.Duration: Identifiable {
    public var id: Int { rawValue }
}
