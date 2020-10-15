// Copyright © 2020 Metabolist. All rights reserved.

import AVKit

final class PlayerCache {
    private let cache = NSCache<NSURL, AVQueuePlayer>()
    private var allURLsCached = Set<URL>()

    private init() {}
}

extension PlayerCache {
    static let shared = PlayerCache()

    func player(url: URL) -> AVQueuePlayer {
        if let player = cache.object(forKey: url as NSURL) {
            return player
        }

        let player = AVQueuePlayer(url: url)

        cache.setObject(player, forKey: url as NSURL)
        allURLsCached.insert(url)

        return player
    }
}
