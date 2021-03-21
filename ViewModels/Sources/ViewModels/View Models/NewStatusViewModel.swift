// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class NewStatusViewModel: ObservableObject {
    @Published public var visibility: Status.Visibility
    @Published public private(set) var compositionViewModels = [CompositionViewModel]()
    @Published public private(set) var identityContext: IdentityContext
    @Published public var canPost = false
    @Published public var alertItem: AlertItem?
    @Published public private(set) var postingState = PostingState.composing
    public let canChangeIdentity: Bool
    public let inReplyToViewModel: StatusViewModel?
    public let events: AnyPublisher<Event, Never>

    private let allIdentitiesService: AllIdentitiesService
    private let environment: AppEnvironment
    private let eventsSubject = PassthroughSubject<Event, Never>()
    private let compositionEventsSubject = PassthroughSubject<CompositionViewModel.Event, Never>()
    private var cancellables = Set<AnyCancellable>()

    // swiftlint:disable:next function_body_length
    public init(allIdentitiesService: AllIdentitiesService,
                identityContext: IdentityContext,
                environment: AppEnvironment,
                identity: Identity?,
                inReplyTo: StatusViewModel?,
                redraft: Status?,
                directMessageTo: AccountViewModel?,
                extensionContext: NSExtensionContext?) {
        self.allIdentitiesService = allIdentitiesService
        self.identityContext = identityContext
        self.environment = environment
        inReplyToViewModel = inReplyTo
        events = eventsSubject.eraseToAnyPublisher()
        visibility = redraft?.visibility
            ?? inReplyTo?.visibility
            ?? (identity ?? identityContext.identity).preferences.postingDefaultVisibility

        if let inReplyTo = inReplyTo {
            switch inReplyTo.visibility {
            case .public, .unlisted:
                canChangeIdentity = true
            default:
                canChangeIdentity = false
            }
        } else {
            canChangeIdentity = true
        }

        let compositionViewModel: CompositionViewModel

        if let redraft = redraft {
            compositionViewModel = CompositionViewModel(
                eventsSubject: compositionEventsSubject,
                redraft: redraft,
                identityContext: identityContext)
        } else if let extensionContext = extensionContext {
            compositionViewModel = CompositionViewModel(
                eventsSubject: compositionEventsSubject,
                extensionContext: extensionContext,
                parentViewModel: self)
        } else {
            compositionViewModel = CompositionViewModel(eventsSubject: compositionEventsSubject)
        }

        if let inReplyTo = inReplyTo, redraft == nil {
            var mentions = Set<String>()

            if !inReplyTo.isMine {
                mentions.insert(inReplyTo.accountName)
            }

            mentions.formUnion(inReplyTo.mentions.map(\.acct)
                                .filter { $0 != (identity ?? identityContext.identity).account?.username }
                                .map("@".appending))

            compositionViewModel.text = mentions.joined(separator: " ").appending(" ")
            compositionViewModel.contentWarning = inReplyTo.spoilerText
            compositionViewModel.displayContentWarning = !inReplyTo.spoilerText.isEmpty
        } else if let directMessageTo = directMessageTo {
            compositionViewModel.text = directMessageTo.accountName.appending(" ")
            visibility = .direct
        }

        compositionViewModels = [compositionViewModel]
        $compositionViewModels.flatMap { Publishers.MergeMany($0.map(\.$isPostable)) }
            .receive(on: DispatchQueue.main) // hack to punt to next run loop, consider refactoring
            .compactMap { [weak self] _ in self?.compositionViewModels.allSatisfy(\.isPostable) }
            .combineLatest($postingState)
            .map { $0 && $1 == .composing }
            .assign(to: &$canPost)
        compositionEventsSubject
            .sink { [weak self] in self?.handle(event: $0) }
            .store(in: &cancellables)

        if let identity = identity {
            setIdentity(identity)
        }
    }
}

public extension NewStatusViewModel {
    enum Event {
        case presentMediaPicker(CompositionViewModel)
        case presentCamera(CompositionViewModel)
        case presentDocumentPicker(CompositionViewModel)
        case presentEmojiPicker(Int)
        case editAttachment(AttachmentViewModel, CompositionViewModel)
        case changeIdentity(Identity)
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

        identityContext = IdentityContext(
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

    func presentDocumentPicker(viewModel: CompositionViewModel) {
        eventsSubject.send(.presentDocumentPicker(viewModel))
    }

    func presentEmojiPicker(tag: Int) {
        eventsSubject.send(.presentEmojiPicker(tag))
    }

    func remove(viewModel: CompositionViewModel) {
        compositionViewModels.removeAll { $0 === viewModel }
    }

    func insert(after: CompositionViewModel) {
        guard let index = compositionViewModels.firstIndex(where: { $0 === after })
        else { return }

        let newViewModel = CompositionViewModel(eventsSubject: compositionEventsSubject)

        newViewModel.contentWarning = after.contentWarning
        newViewModel.displayContentWarning = after.displayContentWarning

        let mentions = Self.mentionsRegularExpression.matches(
            in: after.text,
            range: NSRange(location: 0, length: after.text.count))
            .compactMap { result -> String? in
                guard let range = Range(result.range, in: after.text) else { return nil }

                return String(after.text[range])
            }

        if !mentions.isEmpty {
            newViewModel.text = mentions.joined(separator: " ").appending(" ")
        }

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

        post(viewModel: unposted, inReplyToId: inReplyToViewModel?.id)
    }

    func changeIdentity(_ identity: Identity) {
        eventsSubject.send(.changeIdentity(identity))
    }
}

private extension NewStatusViewModel {
    // swiftlint:disable:next force_try
    static let mentionsRegularExpression = try! NSRegularExpression(pattern: #"@\S+"#)

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
        identityContext.service.post(statusComponents: viewModel.components(
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
