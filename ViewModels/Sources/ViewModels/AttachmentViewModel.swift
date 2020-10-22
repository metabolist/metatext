// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon
import Network

public struct AttachmentViewModel {
    public let attachment: Attachment

    private let status: Status
    private let identification: Identification

    init(attachment: Attachment, status: Status, identification: Identification) {
        self.attachment = attachment
        self.status = status
        self.identification = identification
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

    var shouldAutoplay: Bool {
        switch attachment.type {
        case .video:
            return identification.appPreferences.autoplayVideos == .always
                || (identification.appPreferences.autoplayVideos == .wifi
                        && Self.wifiMonitor.currentPath.status == .satisfied)
        case .gifv:
            return identification.appPreferences.autoplayGIFs == .always
                || (identification.appPreferences.autoplayGIFs == .wifi
                        && Self.wifiMonitor.currentPath.status == .satisfied)
        default: return false
        }
    }
}

private extension AttachmentViewModel {
    static let wifiMonitor = NWPathMonitor(requiredInterfaceType: .wifi)
}
