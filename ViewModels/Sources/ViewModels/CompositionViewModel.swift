// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class CompositionViewModel: ObservableObject {
    public let id = Id()
    public var isPosted = false
    @Published public var text = ""
    @Published public private(set) var attachmentViewModels = [CompositionAttachmentViewModel]()
    @Published public private(set) var isPostable = false
    @Published public private(set) var identification: Identification
    @Published public private(set) var attachmentUpload: AttachmentUpload?

    private let eventsSubject: PassthroughSubject<Event, Never>
    private var cancellables = Set<AnyCancellable>()

    init(identification: Identification,
         identificationPublisher: AnyPublisher<Identification, Never>,
         eventsSubject: PassthroughSubject<Event, Never>) {
        self.identification = identification
        self.eventsSubject = eventsSubject
        identificationPublisher.assign(to: &$identification)
        $text.map { !$0.isEmpty }.removeDuplicates().assign(to: &$isPostable)
    }
}

public extension CompositionViewModel {
    typealias Id = UUID

    enum Event {
        case insertAfter(CompositionViewModel)
        case presentMediaPicker(CompositionViewModel)
        case error(Error)
    }

    func components(inReplyToId: Status.Id?) -> StatusComponents {
        StatusComponents(
            inReplyToId: inReplyToId,
            text: text,
            mediaIds: attachmentViewModels.map(\.attachment.id))
    }

    func presentMediaPicker() {
        eventsSubject.send(.presentMediaPicker(self))
    }

    func insert() {
        eventsSubject.send(.insertAfter(self))
    }

    func attach(itemProvider: NSItemProvider) {
        let progress = Progress(totalUnitCount: 1)

        MediaProcessingService.dataAndMimeType(itemProvider: itemProvider)
            .flatMap { [weak self] data, mimeType -> AnyPublisher<Attachment, Error> in
                guard let self = self else { return Empty().eraseToAnyPublisher() }

                DispatchQueue.main.async {
                    self.attachmentUpload = AttachmentUpload(progress: progress, data: data, mimeType: mimeType)
                }

                return self.identification.service.uploadAttachment(data: data, mimeType: mimeType, progress: progress)
            }
            .print()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.attachmentUpload = nil

                if case let .failure(error) = $0 {
                    self?.eventsSubject.send(.error(error))
                }
            } receiveValue: { [weak self] in
                self?.attachmentViewModels.append(CompositionAttachmentViewModel(attachment: $0))
            }
            .store(in: &cancellables)
    }

    func attachmentViewModel(indexPath: IndexPath) -> CompositionAttachmentViewModel {
        attachmentViewModels[indexPath.item]
    }
}
