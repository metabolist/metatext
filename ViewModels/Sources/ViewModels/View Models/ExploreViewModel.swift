// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class ExploreViewModel: ObservableObject {
    public let searchViewModel: SearchViewModel
    public let events: AnyPublisher<Event, Never>
    @Published public var instanceViewModel: InstanceViewModel?
    @Published public var trends = [Tag]()
    @Published public private(set) var loading = false
    @Published public var alertItem: AlertItem?
    public let identityContext: IdentityContext

    private let exploreService: ExploreService
    private let eventsSubject = PassthroughSubject<Event, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(service: ExploreService, identityContext: IdentityContext) {
        exploreService = service
        self.identityContext = identityContext
        searchViewModel = SearchViewModel(identityContext: identityContext)
        events = eventsSubject.eraseToAnyPublisher()

        identityContext.$identity
            .compactMap { $0.instance?.uri }
            .removeDuplicates()
            .flatMap { service.instanceServicePublisher(uri: $0) }
            .map { InstanceViewModel(instanceService: $0) }
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$instanceViewModel)
    }
}

public extension ExploreViewModel {
    enum Event {
        case navigation(Navigation)
    }

    enum Section: Hashable {
        case trending
        case instance
    }

    enum Item: Hashable {
        case tag(Tag)
        case instance
        case profileDirectory
    }

    func refresh() {
        exploreService.fetchTrends()
            .handleEvents(receiveOutput: { [weak self] trends in
                DispatchQueue.main.async {
                    self?.trends = trends
                }
            })
            .ignoreOutput()
            .merge(with: identityContext.service.refreshInstance())
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in self?.loading = true },
                          receiveCompletion: { [weak self] _ in self?.loading = false })
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func viewModel(tag: Tag) -> TagViewModel {
        .init(tag: tag, identityContext: identityContext)
    }

    func select(item: ExploreViewModel.Item) {
        switch item {
        case let .tag(tag):
            eventsSubject.send(
                .navigation(.collection(exploreService
                                            .navigationService
                                            .timelineService(timeline: .tag(tag.name)))))
        case .instance:
            break
        case .profileDirectory:
            eventsSubject.send(
                .navigation(.collection(identityContext
                                            .service
                                            .service(accountList: .directory(local: true),
                                                     titleComponents: ["explore.profile-directory"]))))
        }
    }
}
