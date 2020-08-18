// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct Attachment: Codable, Hashable {
    enum AttachmentType: String, Codable, Hashable, Unknowable {
        case image, video, gifv, audio, unknown

        static var unknownCase: Self { .unknown }
    }

    // swiftlint:disable nesting
    struct Meta: Codable, Hashable {
        struct Info: Codable, Hashable {
            let width: Int?
            let height: Int?
            let size: String?
            let aspect: Double?
            let frameRate: String?
            let duration: Double?
            let bitrate: Int?
        }

        struct Focus: Codable, Hashable {
            let x: Double
            let y: Double
        }

        let original: Info?
        let small: Info?
        let focus: Focus?
    }
    // swiftlint:enable nesting

    let id: String
    let type: AttachmentType
    let url: URL
    let remoteUrl: URL?
    let previewUrl: URL
    let textUrl: URL?
    let meta: Meta?
    let description: String?
}
