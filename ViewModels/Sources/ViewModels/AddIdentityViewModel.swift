// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public enum AddIdentityError: Error {
    case unableToConnectToInstance
}

public final class AddIdentityViewModel: ObservableObject {
    @Published public var urlFieldText = ""
    @Published public var alertItem: AlertItem?
    @Published public private(set) var loading = false
    public let addedIdentityID: AnyPublisher<UUID, Never>

    private let allIdentitiesService: AllIdentitiesService
    private let instanceURLService: InstanceURLService
    private let addedIdentityIDSubject = PassthroughSubject<UUID, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(allIdentitiesService: AllIdentitiesService, instanceURLService: InstanceURLService) {
        self.allIdentitiesService = allIdentitiesService
        self.instanceURLService = instanceURLService
        addedIdentityID = addedIdentityIDSubject.eraseToAnyPublisher()
    }
}

public extension AddIdentityViewModel {
    func logInTapped() {
        addIdentity(authenticated: true)
    }

    func browseAnonymouslyTapped() {
        addIdentity(authenticated: false)
    }

    func refreshFilter() {
        instanceURLService.updateFilter()
            .sink { _ in }
            .store(in: &cancellables)
    }
}

private extension AddIdentityViewModel {
    private static let filteredURL = URL(string: "https://filtered")!
    private static let HTTPSPrefix = "https://"

    static func url(fieldText: String) -> URL? {
        if fieldText.hasPrefix(HTTPSPrefix), let prefixedURL = URL(string: fieldText) {
            return prefixedURL
        } else if let unprefixedURL = URL(string: HTTPSPrefix + fieldText) {
            return unprefixedURL
        }

        return nil
    }

    func addIdentity(authenticated: Bool) {
        let identityID = UUID()

        guard let url = Self.url(fieldText: urlFieldText) else {
            alertItem = AlertItem(error: AddIdentityError.unableToConnectToInstance)

            return
        }

        if instanceURLService.isFiltered(url: url) {
            loading = true

            DispatchQueue.main.asyncAfter(deadline: .now() + .random(in: 0.01...0.1)) {
                self.alertItem = AlertItem(error: AddIdentityError.unableToConnectToInstance)
                self.loading = false
            }

            return
        }

        allIdentitiesService.createIdentity(
            id: identityID,
            url: url,
            authenticated: authenticated)
            .receive(on: DispatchQueue.main)
            .catch { [weak self] error -> Empty<Never, Never> in
                if case AuthenticationError.canceled = error {
                    // no-op
                } else {
                    let displayedError = error is URLError ? AddIdentityError.unableToConnectToInstance : error

                    self?.alertItem = AlertItem(error: displayedError)
                }

                return Empty()
            }
            .handleEvents(receiveSubscription: { [weak self] _ in self?.loading = true })
            .sink { [weak self] in
                guard let self = self else { return }

                self.loading = false

                if case .finished = $0 {
                    self.addedIdentityIDSubject.send(identityID)
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}
