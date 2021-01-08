// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class CompositionViewModel: AttachmentsRenderingViewModel, ObservableObject, Identifiable {
    public let id = Id()
    public var isPosted = false
    @Published public var text = ""
    @Published public var contentWarning = ""
    @Published public var displayContentWarning = false
    @Published public private(set) var attachmentViewModels = [AttachmentViewModel]()
    @Published public private(set) var attachmentUpload: AttachmentUpload?
    @Published public private(set) var isPostable = false
    @Published public private(set) var canAddAttachment = true
    @Published public private(set) var canAddNonImageAttachment = true
    @Published public private(set) var remainingCharacters = CompositionViewModel.maxCharacters
    public let canRemoveAttachments = true

    private var attachmentUploadCancellable: AnyCancellable?

    init() {
        $text.map { !$0.isEmpty }
            .removeDuplicates()
            .combineLatest($attachmentViewModels.map { !$0.isEmpty })
            .map { textPresent, attachmentPresent in
                textPresent || attachmentPresent
            }
            .assign(to: &$isPostable)
        $attachmentViewModels
            .combineLatest($attachmentUpload)
            .map { $0.count < Self.maxAttachmentCount && $1 == nil }
            .assign(to: &$canAddAttachment)
        $attachmentViewModels.map(\.isEmpty).assign(to: &$canAddNonImageAttachment)
        $text.map {
            let tokens = $0.components(separatedBy: " ")

            return tokens.map(\.countShorteningIfURL).reduce(tokens.count - 1, +)
        }
        .combineLatest($displayContentWarning, $contentWarning)
        .map { Self.maxCharacters - ($0 + ($1 ? $2.count : 0)) }
        .assign(to: &$remainingCharacters)
    }

    public func attachmentSelected(viewModel: AttachmentViewModel) {
        
    }

    public func removeAttachment(viewModel: AttachmentViewModel) {
        attachmentViewModels.removeAll { $0 === viewModel }
    }
}

public extension CompositionViewModel {
    static let maxCharacters = 500

    typealias Id = UUID

    enum Event {
        case insertAfter(CompositionViewModel)
        case presentMediaPicker(CompositionViewModel)
        case error(Error)
    }

    func components(inReplyToId: Status.Id?, visibility: Status.Visibility) -> StatusComponents {
        StatusComponents(
            inReplyToId: inReplyToId,
            text: text,
            spoilerText: displayContentWarning ? contentWarning : "",
            mediaIds: attachmentViewModels.map(\.attachment.id),
            visibility: visibility)
    }

    func cancelUpload() {
        attachmentUploadCancellable?.cancel()
    }
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

                return parentViewModel.identification.service.uploadAttachment(
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
                        identification: parentViewModel.identification))
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
