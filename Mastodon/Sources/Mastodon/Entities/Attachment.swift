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
            public let x: Double
            public let y: Double
        }

        public let original: Info?
        public let small: Info?
        public let focus: Focus?
    }
    // swiftlint:enable nesting

    public let id: String
    public let type: AttachmentType
    public let url: URL
    public let remoteUrl: URL?
    public let previewUrl: URL?
    public let textUrl: URL?
    public let meta: Meta?
    public let description: String?
}
