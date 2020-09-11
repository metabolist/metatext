// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import MastodonAPI
import ServiceLayer

public enum RegistrationError: Error {
    case passwordConfirmationMismatch
}

public final class RegistrationViewModel: ObservableObject {
    public let instance: Instance
    public let serverRulesURL: URL
    public let termsOfServiceURL: URL
    @Published public var alertItem: AlertItem?
    @Published public var username = ""
    @Published public var email = ""
    @Published public var password = ""
    @Published public var passwordConfirmation = ""
    @Published public var reason = ""
    @Published public var passwordsMatch = false
    @Published public var agreement = false
    @Published public private(set) var registerButtonEnabled = false
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

        Publishers.CombineLatest4($username, $email, $password, $reason)
            .map { username, email, password, reason in
                !username.isEmpty
                    && !email.isEmpty
                    && !password.isEmpty
                    && (!instance.approvalRequired || !reason.isEmpty)
            }
            .combineLatest($agreement)
            .map { $0 && $1 }
            .assign(to: &$registerButtonEnabled)
    }
}

public extension RegistrationViewModel {
    func registerTapped() {
        guard password == passwordConfirmation else {
            alertItem = AlertItem(error: RegistrationError.passwordConfirmationMismatch)

            return
        }

        allIdentitiesService.createIdentity(
            id: UUID(),
            url: url,
            username: username,
            email: email,
            password: password,
            reason: reason)
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
