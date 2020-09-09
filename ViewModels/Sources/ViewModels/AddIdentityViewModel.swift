// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public final class AddIdentityViewModel: ObservableObject {
    @Published public var urlFieldText = ""
    @Published public var alertItem: AlertItem?
    @Published public private(set) var loading = false
    public let addedIdentityID: AnyPublisher<UUID, Never>

    private let allIdentitiesService: AllIdentitiesService
    private let addedIdentityIDSubject = PassthroughSubject<UUID, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(allIdentitiesService: AllIdentitiesService) {
        self.allIdentitiesService = allIdentitiesService
        addedIdentityID = addedIdentityIDSubject.eraseToAnyPublisher()
    }
}

public extension AddIdentityViewModel {
    func logInTapped() {
        let identityID = UUID()
        let instanceURL: URL

        do {
            instanceURL = try checkedURL()
        } catch {
            alertItem = AlertItem(error: error)

            return
        }

        allIdentitiesService.authorizeAndCreateIdentity(id: identityID, url: instanceURL)
            .receive(on: DispatchQueue.main)
            .catch { [weak self] error -> Empty<Never, Never> in
                if case AuthenticationError.canceled = error {
                    // no-op
                } else {
                    self?.alertItem = AlertItem(error: error)
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

    func browseAnonymouslyTapped() {
        let identityID = UUID()
        let instanceURL: URL

        do {
            instanceURL = try checkedURL()
        } catch {
            alertItem = AlertItem(error: error)

            return
        }

        // TODO: Ensure instance has not disabled public preview
        allIdentitiesService.createIdentity(id: identityID, instanceURL: instanceURL)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { [weak self] in
                guard let self = self, case .finished = $0 else { return }

                self.addedIdentityIDSubject.send(identityID)
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func refreshFilter() {
        allIdentitiesService.instanceFilterService.updateFilter()
            .sink { _ in }
            .store(in: &cancellables)
    }
}

private extension AddIdentityViewModel {
    private static let filteredURL = URL(string: "https://filtered")!
    private static let HTTPSPrefix = "https://"

    func checkedURL() throws -> URL {
        let url: URL

        if urlFieldText.hasPrefix(Self.HTTPSPrefix), let prefixedURL = URL(string: urlFieldText) {
            url = prefixedURL
        } else if let unprefixedURL = URL(string: Self.HTTPSPrefix + urlFieldText) {
            url = unprefixedURL
        } else {
            throw URLError(.badURL)
        }

        if allIdentitiesService.instanceFilterService.isFiltered(url: url) {
            return Self.filteredURL
        }

        return url
    }
}
