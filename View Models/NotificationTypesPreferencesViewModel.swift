// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import Mastodon
import ServiceLayer

class NotificationTypesPreferencesViewModel: ObservableObject {
    @Published var pushSubscriptionAlerts: PushSubscription.Alerts
    @Published var alertItem: AlertItem?

    private let identityService: IdentityService
    private var cancellables = Set<AnyCancellable>()

    init(identityService: IdentityService) {
        self.identityService = identityService
        pushSubscriptionAlerts = identityService.identity.pushSubscriptionAlerts

        identityService.$identity
            .map(\.pushSubscriptionAlerts)
            .dropFirst()
            .removeDuplicates()
            .assign(to: &$pushSubscriptionAlerts)

        $pushSubscriptionAlerts
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] in self?.update(alerts: $0) }
            .store(in: &cancellables)
    }
}

private extension NotificationTypesPreferencesViewModel {
    func update(alerts: PushSubscription.Alerts) {
        guard alerts != identityService.identity.pushSubscriptionAlerts else { return }

        identityService.updatePushSubscription(alerts: alerts)
            .sink { [weak self] in
                guard let self = self, case let .failure(error) = $0 else { return }

                self.alertItem = AlertItem(error: error)
                self.pushSubscriptionAlerts = self.identityService.identity.pushSubscriptionAlerts
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}
