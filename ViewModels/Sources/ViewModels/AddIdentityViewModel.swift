// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public enum AddIdentityError: Error {
    case unableToConnectToInstance
}

public final class AddIdentityViewModel: ObservableObject {
    @Published public var urlFieldText = ""
    @Published public var alertItem: AlertItem?
    @Published public private(set) var loading = false
    @Published public private(set) var instanceAndURL: (Instance, URL)?
    @Published public private(set) var isPublicTimelineAvailable = false
    public let addedIdentityID: AnyPublisher<UUID, Never>

    private let allIdentitiesService: AllIdentitiesService
    private let instanceURLService: InstanceURLService
    private let addedIdentityIDSubject = PassthroughSubject<UUID, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(allIdentitiesService: AllIdentitiesService, instanceURLService: InstanceURLService) {
        self.allIdentitiesService = allIdentitiesService
        self.instanceURLService = instanceURLService
        addedIdentityID = addedIdentityIDSubject.eraseToAnyPublisher()

        let url = $urlFieldText
            .debounce(for: 0.5, scheduler: DispatchQueue.global())
            .removeDuplicates()
            .map(instanceURLService.url(text:))
            .share()

        url.compactMap { $0 }
            .flatMap(instanceURLService.instance(url:))
            .combineLatest(url)
            .map {
                if let instance = $0, let url = $1 {
                    return (instance, url)
                }

                return nil
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$instanceAndURL)

        url.compactMap { $0 }
            .flatMap(instanceURLService.isPublicTimelineAvailable(url:))
            .combineLatest(url.map { $0 != nil })
            .map { $0 && $1 }
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPublicTimelineAvailable)
    }
}

public extension AddIdentityViewModel {
    func logInTapped() {
        addIdentity(authenticated: true)
    }

    func browseTapped() {
        addIdentity(authenticated: false)
    }

    func refreshFilter() {
        instanceURLService.updateFilter()
            .sink { _ in }
            .store(in: &cancellables)
    }

    func registrationViewModel(instance: Instance, url: URL) -> RegistrationViewModel {
        RegistrationViewModel(instance: instance, url: url, allIdentitiesService: allIdentitiesService)
    }
}

private extension AddIdentityViewModel {
    func addIdentity(authenticated: Bool) {
        let identityID = UUID()

        guard let url = instanceURLService.url(text: urlFieldText) else {
            alertItem = AlertItem(error: AddIdentityError.unableToConnectToInstance)

            return
        }

        allIdentitiesService.createIdentity(
            id: identityID,
            url: url,
            authenticated: authenticated)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in self?.loading = true })
            .sink { [weak self] in
                guard let self = self else { return }

                self.loading = false

                switch $0 {
                case .finished:
                    self.addedIdentityIDSubject.send(identityID)
                case let .failure(error):
                    if case AuthenticationError.canceled = error {
                        return
                    }

                    let displayedError = error is URLError ? AddIdentityError.unableToConnectToInstance : error

                    self.alertItem = AlertItem(error: displayedError)
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func checkIfPublicTimelineAvailable(url: URL) -> AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
    }
}
