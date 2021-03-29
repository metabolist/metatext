// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

public struct CardViewModel {
    private let card: Card

    init(card: Card) {
        self.card = card
    }
}

public extension CardViewModel {
    var url: URL { card.url.url }

    var title: String { card.title }

    var description: String { card.description }

    var imageURL: URL? { card.image?.url }
}
