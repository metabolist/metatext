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
    @Published public var textToSelectedRange = ""
    @Published public var contentWarning = ""
    @Published public var contentWarningTextToSelectedRange = ""
    @Published public var displayContentWarning = false
    @Published public var sensitive = false
    @Published public var displayPoll = false
    @Published public var pollMultipleChoice = false
    @Published public var pollExpiresIn = PollExpiry.oneDay
    @Published public private(set) var autocompleteQuery: String?
    @Published public private(set) var contentWarningAutocompleteQuery: String?
    @Published public private(set) var pollOptions = [PollOption(text: ""), PollOption(text: "")]
    @Published public private(set) var attachmentViewModels = [AttachmentViewModel]()
    @Published public private(set) var attachmentUploadViewModels = [AttachmentUploadViewModel]()
    @Published public private(set) var isPostable = false
    @Published public private(set) var canAddAttachment = true
    @Published public private(set) var canAddNonImageAttachment = true
    @Published public private(set) var remainingCharacters = CompositionViewModel.defaultMaxCharacters
    public let canRemoveAttachments = true

    private let eventsSubject: PassthroughSubject<Event, Never>
    private let maxCharacters: Int
    private var cancellables = Set<AnyCancellable>()

    init(eventsSubject: PassthroughSubject<Event, Never>, maxCharacters: Int?) {
        self.eventsSubject = eventsSubject
        self.maxCharacters = maxCharacters ?? Self.defaultMaxCharacters

        $text.map { !$0.isEmpty }
            .removeDuplicates()
            .combineLatest($attachmentViewModels.map { !$0.isEmpty })
            .map { textPresent, attachmentPresent in
                textPresent || attachmentPresent
            }
            .assign(to: &$isPostable)

        $attachmentViewModels
            .combineLatest($attachmentUploadViewModels, $displayPoll)
            .map { $0.count < Self.maxAttachmentCount && $1.isEmpty && !$2 }
            .assign(to: &$canAddAttachment)

        $attachmentViewModels.map(\.isEmpty).assign(to: &$canAddNonImageAttachment)

        $attachmentUploadViewModels
            .compactMap(\.first)
            .sink { [weak self] in self?.upload(viewModel: $0) }
            .store(in: &cancellables)

        $text.map {
            let tokens = $0.components(separatedBy: " ")

            return tokens.map(\.countShorteningIfURL).reduce(tokens.count - 1, +)
        }
        .combineLatest($displayContentWarning, $contentWarning)
        .map { (maxCharacters ?? Self.defaultMaxCharacters) - ($0 + ($1 ? $2.count : 0)) }
        .assign(to: &$remainingCharacters)

        $displayContentWarning.filter { $0 }.assign(to: &$sensitive)

        $textToSelectedRange
            .map { Self.extractAutocompleteQuery(textToSelectedRange: $0, emojiOnly: false) }
            .removeDuplicates()
            .assign(to: &$autocompleteQuery)

        $contentWarningTextToSelectedRange
            .map { Self.extractAutocompleteQuery(textToSelectedRange: $0, emojiOnly: true) }
            .removeDuplicates()
            .assign(to: &$contentWarningAutocompleteQuery)
    }

    public func attachmentSelected(viewModel: AttachmentViewModel) {
        eventsSubject.send(.editAttachment(viewModel, self))
    }

    public func removeAttachment(viewModel: AttachmentViewModel) {
        attachmentViewModels.removeAll { $0 === viewModel }
    }
}

public extension CompositionViewModel {
    static let defaultMaxCharacters = 500
    static let maxAttachmentCount = 4
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
        @Published public var textToSelectedRange = ""
        @Published public private(set) var remainingCharacters = PollOption.maxCharacters
        @Published public private(set) var autocompleteQuery: String?

        public init(text: String) {
            self.text = text
            $text.map { Self.maxCharacters - $0.count }.assign(to: &$remainingCharacters)
            $textToSelectedRange
                .map { CompositionViewModel.extractAutocompleteQuery(textToSelectedRange: $0, emojiOnly: true) }
                .removeDuplicates()
                .assign(to: &$autocompleteQuery)
        }
    }

    typealias Id = UUID

    convenience init(eventsSubject: PassthroughSubject<Event, Never>,
                     redraft: Status,
                     identityContext: IdentityContext) {
        self.init(eventsSubject: eventsSubject,
                  maxCharacters: identityContext.identity.instance?.maxTootChars)

        if let text = redraft.text {
            self.text = text
        }

        contentWarning = redraft.spoilerText
        displayContentWarning = !redraft.spoilerText.isEmpty
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
        self.init(eventsSubject: eventsSubject,
                  maxCharacters: parentViewModel.identityContext.identity.instance?.maxTootChars)

        guard let inputItem = extensionContext.inputItems.first as? NSExtensionItem else { return }

        if let urlItemProvider = inputItem.attachments?.first(where: {
            $0.hasItemConformingToTypeIdentifier(UTType.url.identifier)
        }) {
            urlItemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { result, _ in
                guard let url = result as? URL else { return }

                if let contentText = inputItem.attributedContentText?.string, !contentText.isEmpty {
                    self.text.append(contentText)
                    self.text.append("\n\n")
                }

                self.text.append(url.absoluteString)
            }
        } else if let plainTextItemProvider = inputItem.attachments?.first(where: {
            $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
        }) {
            plainTextItemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { result, _ in
                guard let text = result as? String else { return }

                self.text = text
            }
        } else if let itemProvider = inputItem.attachments?.first {
            attach(itemProviders: [itemProvider], parentViewModel: parentViewModel)
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

    func attach(itemProviders: [NSItemProvider], parentViewModel: NewStatusViewModel) {
        Publishers.MergeMany(itemProviders.map {
            MediaProcessingService.dataAndMimeType(itemProvider: $0)
                .receive(on: DispatchQueue.main)
                .assignErrorsToAlertItem(to: \.alertItem, on: parentViewModel)
                .map { result in
                    AttachmentUploadViewModel(
                        data: result.data,
                        mimeType: result.mimeType,
                        parentViewModel: parentViewModel)
                }
        })
        .collect()
        .assign(to: &$attachmentUploadViewModels)
    }

    func upload(viewModel: AttachmentUploadViewModel) {
        viewModel.cancellable = viewModel.upload()
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: viewModel.parentViewModel)
            .handleEvents(receiveCancel: { [weak self] in
                self?.attachmentUploadViewModels.removeAll { $0 === viewModel }
            })
            .sink { [weak self] _ in
                self?.attachmentUploadViewModels.removeAll { $0 === viewModel }
            } receiveValue: { [weak self] in
                self?.attachmentViewModels.append(
                    AttachmentViewModel(
                        attachment: $0,
                        identityContext: viewModel.parentViewModel.identityContext))
            }
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

    func discardAttachments() {
        attachmentViewModels = []
    }
}

public extension CompositionViewModel.PollOption {
    static let maxCharacters = 25

    typealias Id = UUID
}

private extension CompositionViewModel {
    static let autocompleteQueryRegularExpression = #"([@#:]\S+)\z"#
    static let emojiOnlyAutocompleteQueryRegularExpression = #"(:\S+)\z"#

    static func extractAutocompleteQuery(textToSelectedRange: String, emojiOnly: Bool) -> String? {
        guard let range = textToSelectedRange.range(
                of: emojiOnly ? emojiOnlyAutocompleteQueryRegularExpression: autocompleteQueryRegularExpression,
                options: .regularExpression,
                locale: .current)
        else { return nil }

        return String(textToSelectedRange[range])
    }
}

private extension String {
    static let urlCharacterCount = 23

    var countShorteningIfURL: Int {
        starts(with: "http://") || starts(with: "https://") ? Self.urlCharacterCount : count
    }
}
