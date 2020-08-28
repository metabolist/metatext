// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct AttachmentViewModel {
    let attachment: Attachment

    init(attachment: Attachment) {
        self.attachment = attachment
    }
}

extension AttachmentViewModel {
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
