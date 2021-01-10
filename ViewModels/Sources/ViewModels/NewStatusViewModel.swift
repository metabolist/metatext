// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class NewStatusViewModel: ObservableObject {
    @Published public var visibility: Status.Visibility
    @Published public private(set) var compositionViewModels: [CompositionViewModel]
    @Published public private(set) var identification: Identification
    @Published public private(set) var authenticatedIdentities = [Identity]()
    @Published public var canPost = false
    @Published public var canChangeIdentity = true
    @Published public var alertItem: AlertItem?
    @Published public private(set) var postingState = PostingState.composing
    public let events: AnyPublisher<Event, Never>

    private let allIdentitiesService: AllIdentitiesService
    private let environment: AppEnvironment
    private let eventsSubject = PassthroughSubject<Event, Never>()
    private let compositionEventsSubject = PassthroughSubject<CompositionViewModel.Event, Never>()
    private var cancellables = Set<AnyCancellable>()

    public init(allIdentitiesService: AllIdentitiesService,
                identification: Identification,
                environment: AppEnvironment) {
        self.allIdentitiesService = allIdentitiesService
        self.identification = identification
        self.environment = environment
        compositionViewModels = [CompositionViewModel(eventsSubject: compositionEventsSubject)]
        events = eventsSubject.eraseToAnyPublisher()
        visibility = identification.identity.preferences.postingDefaultVisibility
        allIdentitiesService.authenticatedIdentitiesPublisher()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$authenticatedIdentities)
        $compositionViewModels.flatMap { Publishers.MergeMany($0.map(\.$isPostable)) }
            .receive(on: DispatchQueue.main) // hack to punt to next run loop, consider refactoring
            .compactMap { [weak self] _ in self?.compositionViewModels.allSatisfy(\.isPostable) }
            .combineLatest($postingState)
            .map { $0 && $1 == .composing }
            .assign(to: &$canPost)
        compositionEventsSubject
            .sink { [weak self] in self?.handle(event: $0) }
            .store(in: &cancellables)
    }
}

public extension NewStatusViewModel {
    enum Event {
        case presentMediaPicker(CompositionViewModel)
        case presentCamera(CompositionViewModel)
        case editAttachment(AttachmentViewModel, CompositionViewModel)
    }

    enum PostingState {
        case composing
        case posting
        case done
    }

    func setIdentity(_ identity: Identity) {
        let identityService: IdentityService

        do {
            identityService = try allIdentitiesService.identityService(id: identity.id)
        } catch {
            alertItem = AlertItem(error: error)

            return
        }

        identification = Identification(
            identity: identity,
            publisher: identityService.identityPublisher(immediate: false)
                .assignErrorsToAlertItem(to: \.alertItem, on: self),
            service: identityService,
            environment: environment)
    }

    func presentMediaPicker(viewModel: CompositionViewModel) {
        eventsSubject.send(.presentMediaPicker(viewModel))
    }

    func presentCamera(viewModel: CompositionViewModel) {
        eventsSubject.send(.presentCamera(viewModel))
    }

    func insert(after: CompositionViewModel) {
        guard let index = compositionViewModels.firstIndex(where: { $0 === after })
        else { return }

        let newViewModel = CompositionViewModel(eventsSubject: compositionEventsSubject)

        newViewModel.contentWarning = after.contentWarning
        newViewModel.displayContentWarning = after.displayContentWarning

        if index >= compositionViewModels.count - 1 {
            compositionViewModels.append(newViewModel)
        } else {
            compositionViewModels.insert(newViewModel, at: index + 1)
        }
    }

    func attach(itemProvider: NSItemProvider, to compositionViewModel: CompositionViewModel) {
        compositionViewModel.attach(itemProvider: itemProvider, parentViewModel: self)
    }

    func post() {
        guard let unposted = compositionViewModels.first(where: { !$0.isPosted }) else { return }

        post(viewModel: unposted, inReplyToId: nil)
    }
}

private extension NewStatusViewModel {
    func handle(event: CompositionViewModel.Event) {
        switch event {
        case let .editAttachment(attachmentViewModel, compositionViewModel):
            eventsSubject.send(.editAttachment(attachmentViewModel, compositionViewModel))
        case let .updateAttachment(publisher):
            publisher.assignErrorsToAlertItem(to: \.alertItem, on: self).sink { _ in }.store(in: &cancellables)
        }
    }
    func post(viewModel: CompositionViewModel, inReplyToId: Status.Id?) {
        postingState = .posting
        identification.service.post(statusComponents: viewModel.components(
                                        inReplyToId: inReplyToId,
                                        visibility: visibility))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }

                switch $0 {
                case .finished:
                    if self.compositionViewModels.allSatisfy(\.isPosted) {
                        self.postingState = .done
                    }
                case let .failure(error):
                    self.alertItem = AlertItem(error: error)
                    self.postingState = .composing
                }
            } receiveValue: { [weak self] in
                guard let self = self else { return }

                viewModel.isPosted = true

                if let unposted = self.compositionViewModels.first(where: { !$0.isPosted }) {
                    self.post(viewModel: unposted, inReplyToId: $0)
                }
            }
            .store(in: &cancellables)
    }
}
