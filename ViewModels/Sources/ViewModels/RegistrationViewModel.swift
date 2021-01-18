// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public enum RegistrationError: Error {
    case passwordConfirmationMismatch
}

public final class RegistrationViewModel: ObservableObject {
    public let instance: Instance
    public let serverRulesURL: URL
    public let termsOfServiceURL: URL
    @Published public var alertItem: AlertItem?
    @Published public var registration = Registration(
        locale: (Locale.preferred ?? Locale.current).languageCodeWithCoercedRegionCodeIfNecessary
            ?? Locale.fallbackLanguageCode)
    @Published public var passwordConfirmation = ""
    @Published public private(set) var registerDisabled = true
    @Published public private(set) var registering = false

    private let url: URL
    private let allIdentitiesService: AllIdentitiesService
    private var cancellables = Set<AnyCancellable>()

    init(instance: Instance, url: URL, allIdentitiesService: AllIdentitiesService) {
        self.instance = instance
        self.url = url
        self.serverRulesURL = url.appendingPathComponent("about").appendingPathComponent("more")
        self.termsOfServiceURL = url.appendingPathComponent("terms")
        self.allIdentitiesService = allIdentitiesService

        $registration
            .map {
                $0.username.isEmpty
                    || $0.email.isEmpty
                    || $0.password.isEmpty
                    || ($0.reason.isEmpty && instance.approvalRequired)
                    || !$0.agreement
            }
            .assign(to: &$registerDisabled)
    }
}

public extension RegistrationViewModel {
    func registerTapped() {
        guard registration.password == passwordConfirmation else {
            alertItem = AlertItem(error: RegistrationError.passwordConfirmationMismatch)

            return
        }

        allIdentitiesService.createIdentity(url: url, kind: .registration(registration))
            .handleEvents(receiveSubscription: { [weak self] _ in self?.registering = true })
            .mapError { error -> Error in
                if error is URLError {
                    return AddIdentityError.unableToConnectToInstance
                } else {
                    return error
                }
            }
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { [weak self] _ in
                self?.registering = false
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}
