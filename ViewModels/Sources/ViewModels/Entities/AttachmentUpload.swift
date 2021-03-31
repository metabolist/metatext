// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public class AttachmentUploadViewModel: ObservableObject {
    public let id = Id()
    public let progress = Progress(totalUnitCount: 1)
    public let parentViewModel: NewStatusViewModel

    let data: Data
    let mimeType: String
    var cancellable: AnyCancellable?

    init(data: Data, mimeType: String, parentViewModel: NewStatusViewModel) {
        self.data = data
        self.mimeType = mimeType
        self.parentViewModel = parentViewModel
    }
}

public extension AttachmentUploadViewModel {
    typealias Id = UUID

    func upload() -> AnyPublisher<Attachment, Error> {
        parentViewModel.identityContext.service.uploadAttachment(
            data: data,
            mimeType: mimeType,
            progress: progress)
    }

    func cancel() {
        cancellable?.cancel()
    }
}
