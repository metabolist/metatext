// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class AddIdentityViewModel: ObservableObject {
    @Published var urlFieldText = ""
    @Published var alertItem: AlertItem?
    @Published private(set) var loading = false
    let addedIdentityIDAndURL: AnyPublisher<(UUID, URL), Never>

    private let identitiesService: IdentitiesService
    private let addedIdentityIDAndURLInput = PassthroughSubject<(UUID, URL), Never>()
    private var cancellables = Set<AnyCancellable>()

    init(identitiesService: IdentitiesService) {
        self.identitiesService = identitiesService
        addedIdentityIDAndURL = addedIdentityIDAndURLInput.eraseToAnyPublisher()
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
            .map { (identityID, instanceURL) }
            .flatMap(identitiesService.createIdentity(id:instanceURL:))
            .map { (identityID, instanceURL) }
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .receive(on: RunLoop.main)
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.loading = true },
                receiveCompletion: { [weak self] _ in self?.loading = false  })
            .sink(receiveValue: addedIdentityIDAndURLInput.send)
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
            .map { (identityID, instanceURL) }
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink(receiveValue: addedIdentityIDAndURLInput.send)
            .store(in: &cancellables)
    }
}
