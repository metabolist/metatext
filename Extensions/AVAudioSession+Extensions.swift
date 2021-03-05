// Copyright © 2021 Metabolist. All rights reserved.

import AVKit

extension AVAudioSession {
    static func incrementPresentedPlayerViewControllerCount() {
        presentedPlayerViewControllerCount += 1
    }

    static func decrementPresentedPlayerViewControllerCount() {
        presentedPlayerViewControllerCount -= 1
    }
}

private extension AVAudioSession {
    static var presentedPlayerViewControllerCount = 0 {
        didSet {
            let instance = sharedInstance()

            if presentedPlayerViewControllerCount > 0, instance.category != .playback {
                try? instance.setCategory(.playback, mode: .default)
            } else if instance.category != .ambient {
                try? instance.setCategory(.ambient, mode: .default)
            }
        }
    }
}
