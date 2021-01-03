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
