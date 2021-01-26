// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer
import UniformTypeIdentifiers

public final class CompositionViewModel: AttachmentsRenderingViewModel, ObservableObject, Identifiable {
    public let id = Id()
    public var isPosted = false
    @Published public var text = ""
    @Published public var contentWarning = ""
    @Published public var displayContentWarning = false
    @Published public var sensitive = false
    @Published public var displayPoll = false
    @Published public var pollMultipleChoice = false
    @Published public var pollExpiresIn = PollExpiry.oneDay
    @Published public private(set) var pollOptions = [PollOption(text: ""), PollOption(text: "")]
    @Published public private(set) var attachmentViewModels = [AttachmentViewModel]()
    @Published public private(set) var attachmentUpload: AttachmentUpload?
    @Published public private(set) var isPostable = false
    @Published public private(set) var canAddAttachment = true
    @Published public private(set) var canAddNonImageAttachment = true
    @Published public private(set) var remainingCharacters = CompositionViewModel.maxCharacters
    public let canRemoveAttachments = true

    private let eventsSubject: PassthroughSubject<Event, Never>
    private var attachmentUploadCancellable: AnyCancellable?

    init(eventsSubject: PassthroughSubject<Event, Never>) {
        self.eventsSubject = eventsSubject

        $text.map { !$0.isEmpty }
            .removeDuplicates()
            .combineLatest($attachmentViewModels.map { !$0.isEmpty })
            .map { textPresent, attachmentPresent in
                textPresent || attachmentPresent
            }
            .assign(to: &$isPostable)
        $attachmentViewModels
            .combineLatest($attachmentUpload, $displayPoll)
            .map { $0.count < Self.maxAttachmentCount && $1 == nil && !$2 }
            .assign(to: &$canAddAttachment)
        $attachmentViewModels.map(\.isEmpty).assign(to: &$canAddNonImageAttachment)
        $text.map {
            let tokens = $0.components(separatedBy: " ")

            return tokens.map(\.countShorteningIfURL).reduce(tokens.count - 1, +)
        }
        .combineLatest($displayContentWarning, $contentWarning)
        .map { Self.maxCharacters - ($0 + ($1 ? $2.count : 0)) }
        .assign(to: &$remainingCharacters)
        $displayContentWarning.filter { $0 }.assign(to: &$sensitive)
    }

    public func attachmentSelected(viewModel: AttachmentViewModel) {
        eventsSubject.send(.editAttachment(viewModel, self))
    }

    public func removeAttachment(viewModel: AttachmentViewModel) {
        attachmentViewModels.removeAll { $0 === viewModel }
    }
}

public extension CompositionViewModel {
    static let maxCharacters = 500
    static let minPollOptionCount = 2
    static let maxPollOptionCount = 4

    enum Event {
        case editAttachment(AttachmentViewModel, CompositionViewModel)
        case updateAttachment(AnyPublisher<Never, Error>)
    }

    enum PollExpiry: Int, CaseIterable {
        case fiveMinutes = 300
        case thirtyMinutes = 1800
        case oneHour = 3600
        case sixHours = 21600
        case oneDay = 86400
        case threeDays = 259200
        case sevenDays = 604800
    }

    class PollOption: ObservableObject {
        public let id = Id()
        @Published public var text: String
        @Published public private(set) var remainingCharacters = CompositionViewModel.maxCharacters

        public init(text: String) {
            self.text = text
            $text.map { Self.maxCharacters - $0.count }.assign(to: &$remainingCharacters)
        }
    }

    typealias Id = UUID

    convenience init(eventsSubject: PassthroughSubject<Event, Never>,
                     redraft: Status,
                     identityContext: IdentityContext) {
        self.init(eventsSubject: eventsSubject)

        if let text = redraft.text {
            self.text = text
        }

        contentWarning = redraft.spoilerText
        displayContentWarning = redraft.spoilerText.isEmpty
        sensitive = redraft.sensitive
        displayPoll = redraft.poll != nil
        attachmentViewModels = redraft.mediaAttachments.map {
            AttachmentViewModel(attachment: $0, identityContext: identityContext)
        }

        if let poll = redraft.poll {
            pollMultipleChoice = poll.multiple
            pollOptions = poll.options.map { PollOption(text: $0.title) }
        }
    }

    convenience init(eventsSubject: PassthroughSubject<Event, Never>,
                     extensionContext: NSExtensionContext,
                     parentViewModel: NewStatusViewModel) {
        self.init(eventsSubject: eventsSubject)

        guard let inputItem = extensionContext.inputItems.first as? NSExtensionItem,
              let itemProvider = inputItem.attachments?.first
        else { return }

        if itemProvider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { result, _ in
                guard let text = result as? String else { return }

                self.text = text
            }
        } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { result, _ in
                guard let url = result as? URL else { return }

                if let contentText = inputItem.attributedContentText?.string {
                    self.text.append(contentText)
                    self.text.append("\n\n")
                }

                self.text.append(url.absoluteString)
            }
        } else {
            attach(itemProvider: itemProvider, parentViewModel: parentViewModel)
        }
    }

    func components(inReplyToId: Status.Id?, visibility: Status.Visibility) -> StatusComponents {
        StatusComponents(
            inReplyToId: inReplyToId,
            text: text,
            spoilerText: displayContentWarning ? contentWarning : "",
            mediaIds: attachmentViewModels.map(\.attachment.id),
            visibility: visibility,
            sensitive: sensitive,
            pollOptions: displayPoll ? pollOptions.map(\.text) : [],
            pollExpiresIn: pollExpiresIn.rawValue,
            pollMultipleChoice: pollMultipleChoice)
    }

    func addPollOption() {
        pollOptions.append(PollOption(text: ""))
    }

    func remove(pollOption: PollOption) {
        pollOptions.removeAll { $0 === pollOption }
    }

    func cancelUpload() {
        attachmentUploadCancellable?.cancel()
    }

    func update(attachmentViewModel: AttachmentViewModel) {
        let publisher = attachmentViewModel.updated()
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] updatedAttachmentViewModel in
                guard let self = self,
                      let index = self.attachmentViewModels.firstIndex(
                        where: { $0.attachment.id == updatedAttachmentViewModel.attachment.id })
                else { return }

                self.attachmentViewModels[index] = updatedAttachmentViewModel
            })
            .ignoreOutput()
            .eraseToAnyPublisher()

        eventsSubject.send(.updateAttachment(publisher))
    }
}

public extension CompositionViewModel.PollOption {
    static let maxCharacters = 25

    typealias Id = UUID
}

extension CompositionViewModel {
    func attach(itemProvider: NSItemProvider, parentViewModel: NewStatusViewModel) {
        attachmentUploadCancellable = MediaProcessingService.dataAndMimeType(itemProvider: itemProvider)
            .flatMap { [weak self] data, mimeType -> AnyPublisher<Attachment, Error> in
                guard let self = self else { return Empty().eraseToAnyPublisher() }

                let progress = Progress(totalUnitCount: 1)

                DispatchQueue.main.async {
                    self.attachmentUpload = AttachmentUpload(progress: progress, data: data, mimeType: mimeType)
                }

                return parentViewModel.identityContext.service.uploadAttachment(
                    data: data,
                    mimeType: mimeType,
                    progress: progress)
            }
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: parentViewModel)
            .handleEvents(receiveCancel: { [weak self] in self?.attachmentUpload = nil })
            .sink { [weak self] _ in
                self?.attachmentUpload = nil
            } receiveValue: { [weak self] in
                self?.attachmentViewModels.append(
                    AttachmentViewModel(
                        attachment: $0,
                        identityContext: parentViewModel.identityContext))
            }
    }
}

private extension CompositionViewModel {
    static let maxAttachmentCount = 4
}

private extension String {
    static let urlCharacterCount = 23

    var countShorteningIfURL: Int {
        starts(with: "http://") || starts(with: "https://") ? Self.urlCharacterCount : count
    }
}
