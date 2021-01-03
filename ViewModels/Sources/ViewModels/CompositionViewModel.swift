// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class CompositionViewModel: ObservableObject, Identifiable {
    public let id = Id()
    public var isPosted = false
    @Published public var text = ""
    @Published public var contentWarning = ""
    @Published public var displayContentWarning = false
    @Published public private(set) var attachmentViewModels = [CompositionAttachmentViewModel]()
    @Published public private(set) var attachmentUpload: AttachmentUpload?
    @Published public private(set) var isPostable = false
    @Published public private(set) var canAddAttachment = true
    @Published public private(set) var canAddNonImageAttachment = true

    private var cancellables = Set<AnyCancellable>()

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
    }
}

public extension CompositionViewModel {
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

    func remove(attachmentViewModel: CompositionAttachmentViewModel) {
        attachmentViewModels.removeAll { $0 === attachmentViewModel }
    }
}

extension CompositionViewModel {
    func attach(itemProvider: NSItemProvider, service: IdentityService) -> AnyPublisher<Never, Error> {
        MediaProcessingService.dataAndMimeType(itemProvider: itemProvider)
            .flatMap { [weak self] data, mimeType -> AnyPublisher<Attachment, Error> in
                guard let self = self else { return Empty().eraseToAnyPublisher() }

                let progress = Progress(totalUnitCount: 1)

                DispatchQueue.main.async {
                    self.attachmentUpload = AttachmentUpload(progress: progress, data: data, mimeType: mimeType)
                }

                return service.uploadAttachment(data: data, mimeType: mimeType, progress: progress)
            }
            .receive(on: DispatchQueue.main)
            .handleEvents(
                receiveOutput: { [weak self] in
                    self?.attachmentViewModels.append(CompositionAttachmentViewModel(attachment: $0))
                },
                receiveCompletion: { [weak self] _ in self?.attachmentUpload = nil })
            .ignoreOutput()
            .eraseToAnyPublisher()
    }
}

private extension CompositionViewModel {
    static let maxAttachmentCount = 4
}
