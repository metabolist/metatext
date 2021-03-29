// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Attachment: Codable, Hashable {
    public enum AttachmentType: String, Codable, Hashable, Unknowable {
        case image, video, gifv, audio, unknown

        public static var unknownCase: Self { .unknown }
    }

    // swiftlint:disable nesting
    public struct Meta: Codable, Hashable {
        public struct Info: Codable, Hashable {
            public let width: Int?
            public let height: Int?
            public let size: String?
            public let aspect: Double?
            public let frameRate: String?
            public let duration: Double?
            public let bitrate: Int?
        }

        public struct Focus: Codable, Hashable {
            public var x: Double
            public var y: Double
        }

        public let original: Info?
        public let small: Info?
        public let focus: Focus?
    }
    // swiftlint:enable nesting

    public let id: Id
    public let type: AttachmentType
    public let url: UnicodeURL
    public let remoteUrl: UnicodeURL?
    public let previewUrl: UnicodeURL?
    public let meta: Meta?
    public let description: String?
    public let blurhash: String?
}

public extension Attachment {
    typealias Id = String

    var aspectRatio: Double? {
        if
            let info = meta?.original,
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

public extension Attachment.Meta.Focus {
    static let `default` = Self(x: 0, y: 0)
}
