// Copyright © 2020 Metabolist. All rights reserved.

import AVKit
import UIKit

class PlayerView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var player: AVPlayer? {
        get { (layer as? AVPlayerLayer)?.player }
        set { (layer as? AVPlayerLayer)?.player = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        (layer as? AVPlayerLayer)?.videoGravity = .resizeAspectFill
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
