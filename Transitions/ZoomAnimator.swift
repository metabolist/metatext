// Copyright © 2020 Metabolist. All rights reserved.

import UIKit

protocol ZoomAnimatorDelegate: class {
    func transitionWillStartWith(zoomAnimator: ZoomAnimator)
    func transitionDidEndWith(zoomAnimator: ZoomAnimator)
    func referenceView(for zoomAnimator: ZoomAnimator) -> UIView?
    func referenceViewFrameInTransitioningView(for zoomAnimator: ZoomAnimator) -> CGRect?
}

final class ZoomAnimator: NSObject {
    weak var fromDelegate: ZoomAnimatorDelegate?
    weak var toDelegate: ZoomAnimatorDelegate?

    var transitionView: UIView?
    var isPresenting = true
}

extension ZoomAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        isPresenting ? .defaultAnimationDuration : .shortAnimationDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        fromDelegate?.transitionWillStartWith(zoomAnimator: self)
        toDelegate?.transitionWillStartWith(zoomAnimator: self)

        if isPresenting {
            animateZoomInTransition(using: transitionContext)
        } else {
            animateZoomOutTransition(using: transitionContext)
        }
    }
}

private extension ZoomAnimator {
    private func animateZoomInTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toVC = transitionContext.viewController(forKey: .to),
            let fromVC = transitionContext.viewController(forKey: .from),
            let fromReferenceView = fromDelegate?.referenceView(for: self),
            let toReferenceView = toDelegate?.referenceView(for: self),
            let fromReferenceViewFrame = fromDelegate?.referenceViewFrameInTransitioningView(for: self)
            else { return }

        toVC.view.alpha = 0
        toReferenceView.isHidden = true
        transitionContext.containerView.addSubview(toVC.view)

        if transitionView == nil, let transitionView = (fromReferenceView as? ZoomAnimatableView)?.transitionView() {
            transitionView.frame = fromReferenceViewFrame
            transitionView.layer.contentsRect = fromReferenceView.layer.contentsRect
            self.transitionView = transitionView
            transitionContext.containerView.addSubview(transitionView)
        }

        fromReferenceView.isHidden = true

        let finalTransitionSize = (fromReferenceView as? ZoomAnimatableView)?.frame(inView: toVC.view) ?? .zero

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: [.transitionCrossDissolve]) {
            self.transitionView?.frame = finalTransitionSize
            self.transitionView?.layer.contentsRect = .defaultContentsRect
            toVC.view.alpha = 1.0
            fromVC.tabBarController?.tabBar.alpha = 0
        } completion: { _ in
            self.transitionView?.removeFromSuperview()
            toReferenceView.isHidden = false
            fromReferenceView.isHidden = false

            self.transitionView = nil

            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            self.toDelegate?.transitionDidEndWith(zoomAnimator: self)
            self.fromDelegate?.transitionDidEndWith(zoomAnimator: self)
        }
    }

    private func animateZoomOutTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let fromReferenceView = fromDelegate?.referenceView(for: self),
            let fromReferenceViewFrame = fromDelegate?.referenceViewFrameInTransitioningView(for: self)
            else { return }

        let toReferenceView = toDelegate?.referenceView(for: self)
        let toReferenceViewFrame = toDelegate?.referenceViewFrameInTransitioningView(for: self)

        toReferenceView?.isHidden = true

        if transitionView == nil, let transitionView = (fromReferenceView as? ZoomAnimatableView)?.transitionView() {
            transitionView.frame = fromReferenceViewFrame
            self.transitionView = transitionView
            containerView.addSubview(transitionView)
        }

        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        fromReferenceView.isHidden = true

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext)) {
            fromVC.view.alpha = 0

            if let toReferenceViewFrame = toReferenceViewFrame {
                self.transitionView?.frame = toReferenceViewFrame
            } else {
                self.transitionView?.alpha = 0
            }

            self.transitionView?.layer.contentsRect = toReferenceView?.layer.contentsRect ?? .defaultContentsRect

            toVC.tabBarController?.tabBar.alpha = 1
        } completion: { _ in
            self.transitionView?.removeFromSuperview()
            toReferenceView?.isHidden = false
            fromReferenceView.isHidden = false

            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            self.toDelegate?.transitionDidEndWith(zoomAnimator: self)
            self.fromDelegate?.transitionDidEndWith(zoomAnimator: self)
        }
    }
}
