// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class AddIdentityViewModel: ObservableObject {
    @Published var urlFieldText = ""
    @Published var alertItem: AlertItem?
    @Published private(set) var loading = false
    let addedIdentityID: AnyPublisher<UUID, Never>

    private let authenticationService: AuthenticationService
    private let addedIdentityIDInput = PassthroughSubject<UUID, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(authenticationService: AuthenticationService) {
        self.authenticationService = authenticationService
        addedIdentityID = addedIdentityIDInput.eraseToAnyPublisher()
    }

    func goTapped() {
        Just(urlFieldText)
            .tryMap { try $0.url() }
            .flatMap(authenticationService.authenticate(instanceURL:))
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .receive(on: RunLoop.main)
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.loading = true },
                receiveCompletion: { [weak self] _ in self?.loading = false  })
            .sink(receiveValue: addedIdentityIDInput.send)
            .store(in: &cancellables)
    }
}
