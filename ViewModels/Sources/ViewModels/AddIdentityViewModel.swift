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

    private let allIdentitiesService: AllIdentitiesService
    private let instanceURLService: InstanceURLService
    private var cancellables = Set<AnyCancellable>()

    init(allIdentitiesService: AllIdentitiesService, instanceURLService: InstanceURLService) {
        self.allIdentitiesService = allIdentitiesService
        self.instanceURLService = instanceURLService
        setupURLObservation()
    }
}

public extension AddIdentityViewModel {
    func logInTapped() {
        addIdentity(kind: .authentication)
    }

    func browseTapped() {
        addIdentity(kind: .browsing)
    }

    func refreshFilter() {
        instanceURLService.updateFilter()
            .sink { _ in } receiveValue: { _ in }
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
            .flatMap { [weak self] text -> AnyPublisher<URL?, Never> in
                guard let self = self else {
                    return Just(nil).eraseToAnyPublisher()
                }

                return self.instanceURLService.url(text: text).publisher
                    .map { $0 as URL? }
                    .replaceError(with: nil)
                    .eraseToAnyPublisher()
            }
            .share()

        url.receive(on: DispatchQueue.main).assign(to: &$url)

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

        url.flatMap { [weak self] url -> AnyPublisher<Bool, Never> in
            guard let self = self, let url = url else {
                return Just(false).eraseToAnyPublisher()
            }

            return self.instanceURLService.isPublicTimelineAvailable(url: url)
                .replaceError(with: false)
                .eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$isPublicTimelineAvailable)
    }

    func addIdentity(kind: AllIdentitiesService.IdentityCreation) {
        instanceURLService.url(text: urlFieldText).publisher
            .map { ($0, kind) }
            .flatMap(allIdentitiesService.createIdentity(url:kind:))
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in self?.loading = true })
            .sink { [weak self] in
                guard let self = self else { return }

                self.loading = false

                if case let .failure(error) = $0 {
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
