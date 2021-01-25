// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import Network

public final class AttachmentViewModel: ObservableObject {
    public let attachment: Attachment
    @Published public var editingDescription: String
    @Published public var editingFocus: Attachment.Meta.Focus
    @Published public private(set) var descriptionRemainingCharacters = AttachmentViewModel.descriptionMaxCharacters

    private let identification: Identification
    private let status: Status?

    init(attachment: Attachment, identification: Identification, status: Status? = nil) {
        self.attachment = attachment
        self.identification = identification
        self.status = status
        editingDescription = attachment.description ?? ""
        editingFocus = attachment.meta?.focus ?? .default
        $editingDescription
            .map { Self.descriptionMaxCharacters - $0.count }
            .assign(to: &$descriptionRemainingCharacters)
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

extension AttachmentViewModel {
    func updated() -> AnyPublisher<AttachmentViewModel, Error> {
        identification.service.updateAttachment(id: attachment.id, description: editingDescription, focus: editingFocus)
            .compactMap { [weak self] in
                guard let self = self else { return nil }

                return AttachmentViewModel(attachment: $0, identification: self.identification, status: self.status)
            }
            .eraseToAnyPublisher()
    }
}

private extension AttachmentViewModel {
    static let descriptionMaxCharacters = 1500

    static var wifiMonitor: NWPathMonitor = {
        let monitor = NWPathMonitor(requiredInterfaceType: .wifi)

        monitor.start(queue: .main)

        return monitor
    }()
}
