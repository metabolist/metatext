// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public enum AddIdentityError: Error {
    case unableToConnectToInstance
    case instanceNotSupported
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

        let url = $urlFieldText
            .throttle(for: .seconds(Self.textFieldThrottleInterval), scheduler: DispatchQueue.global(), latest: true)
            .removeDuplicates()
            .flatMap {
                instanceURLService.url(text: $0.trimmingCharacters(in: .whitespacesAndNewlines)).publisher
                    .map { $0 as URL? }
                    .replaceError(with: nil)
            }
            .share()

        url.receive(on: DispatchQueue.main).assign(to: &$url)

        url.flatMap { url -> AnyPublisher<Instance?, Never> in
            guard let url = url else {
                return Just(nil).eraseToAnyPublisher()
            }

            return instanceURLService.instance(url: url)
                .map { $0 as Instance? }
                .replaceError(with: nil)
                .eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$instance)

        url.flatMap { url -> AnyPublisher<Bool, Never> in
            guard let url = url else {
                return Just(false).eraseToAnyPublisher()
            }

            return instanceURLService.isPublicTimelineAvailable(url: url)
                .replaceError(with: false)
                .eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$isPublicTimelineAvailable)
    }
}

public extension AddIdentityViewModel {
    func logInTapped() {
        addIdentity(kind: .authentication)
    }

    func browseTapped() {
        addIdentity(kind: .browsing)
    }

    func registrationViewModel(instance: Instance, url: URL) -> RegistrationViewModel {
        RegistrationViewModel(instance: instance, url: url, allIdentitiesService: allIdentitiesService)
    }
}

private extension AddIdentityViewModel {
    private static let textFieldThrottleInterval: TimeInterval = 0.5
    func addIdentity(kind: AllIdentitiesService.IdentityCreation) {
        instanceURLService.url(text: urlFieldText.trimmingCharacters(in: .whitespacesAndNewlines)).publisher
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

                    let displayedError: Error

                    if case InstanceURLError.instanceNotSupported = error {
                        displayedError = AddIdentityError.instanceNotSupported
                    } else if error is URLError {
                        displayedError = AddIdentityError.unableToConnectToInstance
                    } else {
                        displayedError = error
                    }

                    self.alertItem = AlertItem(error: displayedError)
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}
