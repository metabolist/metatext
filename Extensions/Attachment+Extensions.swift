// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import Mastodon

extension Attachment.AttachmentType {
    var accessibilityName: String {
        switch self {
        case .image, .gifv:
            return NSLocalizedString("attachment.type.image", comment: "")
        case .video:
            return NSLocalizedString("attachment.type.video", comment: "")
        case .audio:
            return NSLocalizedString("attachment.type.audio", comment: "")
        case .unknown:
            return NSLocalizedString("attachment.type.unknown", comment: "")
        }
    }

    func accessibilityNames(count: Int) -> String {
        let format: String

        switch self {
        case .image, .gifv:
            format = NSLocalizedString("attachment.type.images-%ld", comment: "")
        case .video:
            format = NSLocalizedString("attachment.type.videos-%ld", comment: "")
        case .audio:
            format = NSLocalizedString("attachment.type.audios-%ld", comment: "")
        case .unknown:
            format = NSLocalizedString("attachment.type.unknowns-%ld", comment: "")
        }

        return String.localizedStringWithFormat(format, count)
    }
}
