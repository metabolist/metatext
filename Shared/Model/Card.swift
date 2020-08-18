// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct Card: Codable, Hashable {
    enum CardType: String, Codable, Hashable, Unknowable {
        case link, photo, video, rich, unknown

        static var unknownCase: Self { .unknown }
    }

    let url: URL
    let title: String
    let description: String
    let type: CardType
    let authorName: String?
    let authorUrl: String?
    let providerName: String?
    let providerUrl: String?
    let html: String?
    let width: Int?
    let height: Int?
    let image: URL?
    let embedUrl: String?
}
