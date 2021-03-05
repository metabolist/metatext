// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

final public class ProfileViewModel {
    @Published public private(set) var accountViewModel: AccountViewModel?
    @Published public var collection = ProfileCollection.statuses
    @Published public var alertItem: AlertItem?
    public let imagePresentations: AnyPublisher<URL, Never>

    private let profileService: ProfileService
    private let collectionViewModel: CurrentValueSubject<CollectionItemsViewModel, Never>
    private let accountEventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>
    private let imagePresentationsSubject = PassthroughSubject<URL, Never>()
    private var cancellables = Set<AnyCancellable>()

    public init(profileService: ProfileService, identityContext: IdentityContext) {
        self.profileService = profileService
        imagePresentations = imagePresentationsSubject.eraseToAnyPublisher()

        collectionViewModel = CurrentValueSubject(
            CollectionItemsViewModel(
                collectionService: profileService.timelineService(profileCollection: .statuses),
                identityContext: identityContext))

        let accountEventsSubject = PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>()

        self.accountEventsSubject = accountEventsSubject

        profileService.profilePublisher
            .map {
                let vm = AccountViewModel(accountService: identityContext.service
                                    .navigationService
                                    .accountService(account: $0.account),
                                 identityContext: identityContext,
                                 eventsSubject: accountEventsSubject)

                vm.relationship = $0.relationship
                vm.identityProofs = $0.identityProofs
                vm.featuredTags = $0.featuredTags

                return vm
            }
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$accountViewModel)

        $collection.dropFirst()
            .map(profileService.timelineService(profileCollection:))
            .map { CollectionItemsViewModel(collectionService: $0, identityContext: identityContext) }
            .sink { [weak self] in
                guard let self = self else { return }

                self.collectionViewModel.send($0)
                $0.$alertItem.assign(to: &self.$alertItem)
            }
            .store(in: &cancellables)
    }
}

public extension ProfileViewModel {
    func presentHeader() {
        guard let accountViewModel = accountViewModel else { return }

        imagePresentationsSubject.send(accountViewModel.headerURL)
    }

    func presentAvatar() {
        guard let accountViewModel = accountViewModel else { return }

        imagePresentationsSubject.send(accountViewModel.avatarURL(profile: true))
    }

    func fetchProfile() -> AnyPublisher<Never, Never> {
        profileService.fetchProfile().assignErrorsToAlertItem(to: \.alertItem, on: self)
    }

    func sendDirectMessage() {
        guard let accountViewModel = accountViewModel else { return }

        collectionViewModel.value.sendDirectMessage(accountViewModel: accountViewModel)
    }
}

extension ProfileViewModel: CollectionViewModel {
    public var identityContext: IdentityContext {
        collectionViewModel.value.identityContext
    }

    public var updates: AnyPublisher<CollectionUpdate, Never> {
        collectionViewModel.flatMap(\.updates)
            .combineLatest($accountViewModel.map { $0?.relationship })
            .map {
                let (updates, relationship) = $0

                if let relationship = relationship, relationship.blockedBy {
                    return .empty
                } else {
                    return updates
                }
            }
            .eraseToAnyPublisher()
    }

    public var title: AnyPublisher<String, Never> {
        $accountViewModel.compactMap { $0?.accountName }.eraseToAnyPublisher()
    }

    public var titleLocalizationComponents: AnyPublisher<[String], Never> {
        collectionViewModel.flatMap(\.titleLocalizationComponents).eraseToAnyPublisher()
    }

    public var expandAll: AnyPublisher<ExpandAllState, Never> {
        Empty().eraseToAnyPublisher()
    }

    public var alertItems: AnyPublisher<AlertItem, Never> {
        collectionViewModel.flatMap(\.alertItems).eraseToAnyPublisher()
    }

    public var loading: AnyPublisher<Bool, Never> {
        collectionViewModel.flatMap(\.loading).eraseToAnyPublisher()
    }

    public var events: AnyPublisher<CollectionItemEvent, Never> {
        accountEventsSubject
            .flatMap { [weak self] eventPublisher -> AnyPublisher<CollectionItemEvent, Never> in
                guard let self = self else { return Empty().eraseToAnyPublisher() }

                return eventPublisher.assignErrorsToAlertItem(to: \.alertItem, on: self).eraseToAnyPublisher()
            }
            .merge(with: collectionViewModel.flatMap(\.events))
            .eraseToAnyPublisher()
    }

    public var searchScopeChanges: AnyPublisher<SearchScope, Never> {
        collectionViewModel.flatMap(\.searchScopeChanges).eraseToAnyPublisher()
    }

    public var nextPageMaxId: String? {
        collectionViewModel.value.nextPageMaxId
    }

    public var canRefresh: Bool { collectionViewModel.value.canRefresh }

    public var announcesNewItems: Bool { collectionViewModel.value.canRefresh }

    public func request(maxId: String?, minId: String?, search: Search?) {
        if case .statuses = collection, maxId == nil {
            profileService.fetchPinnedStatuses()
                .assignErrorsToAlertItem(to: \.alertItem, on: self)
                .sink { _ in }
                .store(in: &cancellables)
        }

        collectionViewModel.value.request(maxId: maxId, minId: minId, search: nil)
    }

    public func cancelRequests() {
        collectionViewModel.value.cancelRequests()
    }

    public func requestNextPage(fromIndexPath indexPath: IndexPath) {
        collectionViewModel.value.requestNextPage(fromIndexPath: indexPath)
    }

    public func viewedAtTop(indexPath: IndexPath) {
        collectionViewModel.value.viewedAtTop(indexPath: indexPath)
    }

    public func select(indexPath: IndexPath) {
        collectionViewModel.value.select(indexPath: indexPath)
    }

    public func canSelect(indexPath: IndexPath) -> Bool {
        collectionViewModel.value.canSelect(indexPath: indexPath)
    }

    public func viewModel(indexPath: IndexPath) -> Any {
        collectionViewModel.value.viewModel(indexPath: indexPath)
    }

    public func toggleExpandAll() {
        collectionViewModel.value.toggleExpandAll()
    }

    public func applyAccountListEdit(viewModel: AccountViewModel, edit: CollectionItemEvent.AccountListEdit) {
        collectionViewModel.value.applyAccountListEdit(viewModel: viewModel, edit: edit)
    }
}
