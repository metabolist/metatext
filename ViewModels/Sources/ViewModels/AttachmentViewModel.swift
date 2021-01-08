// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon
import Network

public final class AttachmentViewModel: ObservableObject {
    public let attachment: Attachment

    private let identification: Identification
    private let status: Status?

    init(attachment: Attachment, identification: Identification, status: Status? = nil) {
        self.attachment = attachment
        self.identification = identification
        self.status = status
    }
}

public extension AttachmentViewModel {
    var tag: Int {
        attachment.id.appending(status?.id ?? "").hashValue
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
    static var wifiMonitor: NWPathMonitor = {
        let monitor = NWPathMonitor(requiredInterfaceType: .wifi)

        monitor.start(queue: .main)

        return monitor
    }()
}
