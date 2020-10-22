// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

public struct AttachmentViewModel {
    public let attachment: Attachment

    private let status: Status

    init(attachment: Attachment, status: Status) {
        self.attachment = attachment
        self.status = status
    }
}

public extension AttachmentViewModel {
    var tag: Int {
        attachment.id.appending(status.id).hashValue
    }

    var aspectRatio: Double? {
        if
            let info = attachment.meta?.original,
            let width = info.width,
            let height = info.height,
            width != 0,
            height != 0 {
            let aspectRatio = Double(width) / Double(height)

            return aspectRatio.isNaN ? nil : aspectRatio
        }

        return nil
    }
}
