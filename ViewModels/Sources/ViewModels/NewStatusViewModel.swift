// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class NewStatusViewModel: ObservableObject {
    @Published public private(set) var compositionViewModels = [CompositionViewModel]()
    @Published public private(set) var identification: Identification
    @Published public private(set) var authenticatedIdentities = [Identity]()
    @Published public var canPost = false
    @Published public var canChangeIdentity = true
    @Published public var alertItem: AlertItem?
    @Published public private(set) var loading = false
    public let events: AnyPublisher<CompositionViewModel.Event, Never>

    private let allIdentitiesService: AllIdentitiesService
    private let environment: AppEnvironment
    private let eventsSubject = PassthroughSubject<CompositionViewModel.Event, Never>()
    private let itemEventsSubject = PassthroughSubject<CompositionViewModel.Event, Never>()
    private var cancellables = Set<AnyCancellable>()

    public init(allIdentitiesService: AllIdentitiesService,
                identification: Identification,
                environment: AppEnvironment) {
        self.allIdentitiesService = allIdentitiesService
        self.identification = identification
        self.environment = environment
        events = eventsSubject.eraseToAnyPublisher()
        compositionViewModels = [newCompositionViewModel()]
        itemEventsSubject.sink { [weak self] in self?.handle(event: $0) }.store(in: &cancellables)
        allIdentitiesService.authenticatedIdentitiesPublisher()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$authenticatedIdentities)
        $compositionViewModels.flatMap { Publishers.MergeMany($0.map(\.$isPostable)) }
            .receive(on: DispatchQueue.main) // hack to punt to next run loop, consider refactoring
            .compactMap { [weak self] _ in self?.compositionViewModels.allSatisfy(\.isPostable) }
            .combineLatest($loading)
            .map { $0 && !$1 }
            .assign(to: &$canPost)
    }
}

public extension NewStatusViewModel {
    func viewModel(indexPath: IndexPath) -> CompositionViewModel {
        compositionViewModels[indexPath.row]
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

    func post() {
        guard let unposted = compositionViewModels.first(where: { !$0.isPosted }) else { return }

        post(viewModel: unposted, inReplyToId: nil)
    }
}

private extension NewStatusViewModel {
    func newCompositionViewModel() -> CompositionViewModel {
        CompositionViewModel(
            identification: identification,
            identificationPublisher: $identification.eraseToAnyPublisher(),
            eventsSubject: itemEventsSubject)
    }

    func handle(event: CompositionViewModel.Event) {
        switch event {
        case let .insertAfter(viewModel):
            guard let index = compositionViewModels.firstIndex(where: { $0 === viewModel }) else { return }

            let newViewModel = newCompositionViewModel()

            if index >= compositionViewModels.count - 1 {
                compositionViewModels.append(newViewModel)
            } else {
                compositionViewModels.insert(newViewModel, at: index + 1)
            }
        case let .error(error):
            alertItem = AlertItem(error: error)
        default:
            eventsSubject.send(event)
        }
    }

    func post(viewModel: CompositionViewModel, inReplyToId: Status.Id?) {
        loading = true
        identification.service.post(statusComponents: viewModel.components(inReplyToId: inReplyToId))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }

                switch $0 {
                case .finished:
                    self.loading = self.compositionViewModels.allSatisfy(\.isPosted)
                case let .failure(error):
                    self.alertItem = AlertItem(error: error)
                    self.loading = false
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
