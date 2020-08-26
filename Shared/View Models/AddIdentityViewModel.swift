// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class AddIdentityViewModel: ObservableObject {
    @Published var urlFieldText = ""
    @Published var alertItem: AlertItem?
    @Published private(set) var loading = false
    let addedIdentityID: AnyPublisher<UUID, Never>

    private let identitiesService: IdentitiesService
    private let addedIdentityIDInput = PassthroughSubject<UUID, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(identitiesService: IdentitiesService) {
        self.identitiesService = identitiesService
        addedIdentityID = addedIdentityIDInput.eraseToAnyPublisher()
    }

    func logInTapped() {
        let identityID = UUID()
        let instanceURL: URL

        do {
            try instanceURL = urlFieldText.url()
        } catch {
            alertItem = AlertItem(error: error)

            return
        }

        identitiesService.authorizeIdentity(id: identityID, instanceURL: instanceURL)
            .collect()
            .map { _ in (identityID, instanceURL) }
            .flatMap(identitiesService.createIdentity(id:instanceURL:))
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .receive(on: RunLoop.main)
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.loading = true },
                receiveCompletion: { [weak self] _ in self?.loading = false  })
            .sink { [weak self] in
                guard let self = self, case .finished = $0 else { return }

                self.addedIdentityIDInput.send(identityID)
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func browseAnonymouslyTapped() {
        let identityID = UUID()
        let instanceURL: URL

        do {
            try instanceURL = urlFieldText.url()
        } catch {
            alertItem = AlertItem(error: error)

            return
        }

        // TODO: Ensure instance has not disabled public preview
        identitiesService.createIdentity(id: identityID, instanceURL: instanceURL)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { [weak self] in
                guard let self = self, case .finished = $0 else { return }

                self.addedIdentityIDInput.send(identityID)
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}
