// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class NotificationTypesPreferencesViewModel: ObservableObject {
    @Published public var pushSubscriptionAlerts: PushSubscription.Alerts
    @Published public var alertItem: AlertItem?
    public let identityContext: IdentityContext

    private var cancellables = Set<AnyCancellable>()

    public init(identityContext: IdentityContext) {
        self.identityContext = identityContext
        pushSubscriptionAlerts = identityContext.identity.pushSubscriptionAlerts

        identityContext.$identity
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
        guard alerts != identityContext.identity.pushSubscriptionAlerts else { return }

        identityContext.service.updatePushSubscription(alerts: alerts)
            .sink { [weak self] in
                guard let self = self, case let .failure(error) = $0 else { return }

                self.alertItem = AlertItem(error: error)
                self.pushSubscriptionAlerts = self.identityContext.identity.pushSubscriptionAlerts
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}
