// Copyright © 2020 Metabolist. All rights reserved.

import AVKit

final class PlayerCache {
    private let cache = NSCache<NSURL, AVPlayer>()
    private var allURLsCached = Set<URL>()

    private init() {
        cache.countLimit = 4
    }
}

extension PlayerCache {
    static let shared = PlayerCache()

    func player(url: URL) -> AVPlayer {
        if let player = cache.object(forKey: url as NSURL) {
            return player
        }

        let player = AVPlayer(url: url)

        cache.setObject(player, forKey: url as NSURL)
        allURLsCached.insert(url)

        return player
    }
}
