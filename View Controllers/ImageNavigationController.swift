// Copyright © 2020 Metabolist. All rights reserved.

import AVFoundation
import UIKit

final class ImageNavigationController: UINavigationController {
    let transitionController = ZoomTransitionController()

    private let imagePageViewController: ImagePageViewController

    init(imagePageViewController: ImagePageViewController) {
        self.imagePageViewController = imagePageViewController

        super.init(rootViewController: imagePageViewController)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        hidesBarsOnTap = true
        modalPresentationStyle = .fullScreen

        let panGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(didPanWith(gestureRecognizer:)))

        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)

        transitioningDelegate = transitionController
        transitionController.toDelegate = self
    }
}

extension ImageNavigationController {
    var currentViewController: ImageViewController? {
        imagePageViewController.viewControllers?.first as? ImageViewController
    }

    @objc func didPanWith(gestureRecognizer: UIPanGestureRecognizer) {
        guard let currentViewController = currentViewController else { return }

        switch gestureRecognizer.state {
        case .began:
            currentViewController.scrollView.isScrollEnabled = false
            transitionController.isInteractive = true

            presentingViewController?.dismiss(animated: true)
        case .ended:
            if transitionController.isInteractive {
                currentViewController.scrollView.isScrollEnabled = true
                transitionController.isInteractive = false
                transitionController.didPanWith(gestureRecognizer: gestureRecognizer)
            }
        default:
            if transitionController.isInteractive {
                transitionController.didPanWith(gestureRecognizer: gestureRecognizer)
            }
        }
    }
}

extension ImageNavigationController: ZoomAnimatorDelegate {
    func transitionWillStartWith(zoomAnimator: ZoomAnimator) {

    }

    func transitionDidEndWith(zoomAnimator: ZoomAnimator) {

    }

    func referenceView(for zoomAnimator: ZoomAnimator) -> UIView? {
        if currentViewController?.playerView.player != nil {
            return currentViewController?.playerView
        } else {
            return currentViewController?.imageView
        }
    }

    func referenceViewFrameInTransitioningView(for zoomAnimator: ZoomAnimator) -> CGRect? {
        guard let currentViewController = currentViewController else { return .zero }

        let rect: CGRect

        if let image = currentViewController.imageView.image {
            rect = AVMakeRect(aspectRatio: image.size, insideRect: currentViewController.imageView.frame)
        } else if let item = currentViewController.playerView.player?.currentItem {
            rect = AVMakeRect(aspectRatio: item.presentationSize, insideRect: currentViewController.playerView.frame)
        } else {
            return .zero
        }

        return currentViewController.scrollView.convert(rect, to: currentViewController.view)
    }
}

extension ImageNavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if
            let currentViewController = currentViewController,
            otherGestureRecognizer == currentViewController.scrollView.panGestureRecognizer,
            currentViewController.scrollView.contentOffset.y == 0 {
            return true
        }

        return false
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer === barHideOnTapGestureRecognizer
            && (otherGestureRecognizer as? UITapGestureRecognizer)?.numberOfTapsRequired == 2
    }
}
