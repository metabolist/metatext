// Copyright © 2020 Metabolist. All rights reserved.

import AVFoundation
import UIKit

protocol ZoomAnimatableView {
    func transitionView() -> UIView
    func frame(inView view: UIView) -> CGRect
}

extension UIImageView: ZoomAnimatableView {
    func transitionView() -> UIView {
        let transitionView = UIImageView(image: image)

        transitionView.contentMode = .scaleAspectFill
        transitionView.clipsToBounds = true

        return transitionView
    }

    func frame(inView view: UIView) -> CGRect {
        guard let image = image else { return .zero }

        return AVMakeRect(aspectRatio: image.size, insideRect: view.frame)
    }
}

extension PlayerView: ZoomAnimatableView {
    func transitionView() -> UIView {
        let transitionView = PlayerView()

        transitionView.videoGravity = .resizeAspectFill
        transitionView.player = player

        return transitionView
    }

    func frame(inView view: UIView) -> CGRect {
        guard let item = player?.currentItem else { return .zero }

        return AVMakeRect(aspectRatio: item.presentationSize, insideRect: view.frame)
    }
}
