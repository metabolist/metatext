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
    @Published public private(set) var url: URL?
    @Published public private(set) var instance: Instance?
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
        setupURLObservation()
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
    func setupURLObservation() {
        let url = $urlFieldText
            .debounce(for: 0.5, scheduler: DispatchQueue.global())
            .removeDuplicates()
            .map(instanceURLService.url(text:))
            .share()

        url.receive(on: DispatchQueue.main).assign(to: &$url)

        url.compactMap { $0 }
            .flatMap(instanceURLService.isPublicTimelineAvailable(url:))
            .replaceError(with: false)
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPublicTimelineAvailable)

        url.flatMap { [weak self] url -> AnyPublisher<Instance?, Never> in
            guard let self = self, let url = url else {
                return Just(nil).eraseToAnyPublisher()
            }

            return self.instanceURLService.instance(url: url)
                .map { $0 as Instance? }
                .replaceError(with: nil)
                .eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$instance)
    }

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
}
