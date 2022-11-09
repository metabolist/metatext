// Copyright © 2020 Metabolist. All rights reserved.

import UIKit

final class ZoomDismissalInteractionController: NSObject {
    var transitionContext: UIViewControllerContextTransitioning?
    var animator: UIViewControllerAnimatedTransitioning?

    var fromReferenceViewFrame: CGRect?
    var toReferenceViewFrame: CGRect?

    // swiftlint:disable:next function_body_length
    func didPanWith(gestureRecognizer: UIPanGestureRecognizer) {
        guard let transitionContext = self.transitionContext,
            let animator = self.animator as? ZoomAnimator,
            let transitionView = animator.transitionView,
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to),
            let fromReferenceView = animator.fromDelegate?.referenceView(for: animator),
            let fromReferenceViewFrame = self.fromReferenceViewFrame
            else { return }

        let toReferenceView = animator.toDelegate?.referenceView(for: animator)

        fromReferenceView.isHidden = true

        let anchorPoint = CGPoint(x: fromReferenceViewFrame.midX, y: fromReferenceViewFrame.midY)
        let dismissThreshold = fromReferenceViewFrame.height / 10
        let translatedPoint = gestureRecognizer.translation(in: fromReferenceView)

        let backgroundAlpha = backgroundAlphaFor(view: fromVC.view, withPanningVerticalDelta: translatedPoint.y)
        let scale = scaleFor(view: fromVC.view, withPanningVerticalDelta: translatedPoint.y)

        fromVC.view.alpha = backgroundAlpha

        transitionView.transform = CGAffineTransform(scaleX: scale, y: scale)
        let newCenter = CGPoint(
            x: anchorPoint.x + translatedPoint.x,
            y: anchorPoint.y + translatedPoint.y - transitionView.frame.height * (1 - scale) / 2.0)
        transitionView.center = newCenter

        toReferenceView?.isHidden = true

        transitionContext.updateInteractiveTransition(1 - scale)

        toVC.tabBarController?.tabBar.alpha = 1 - backgroundAlpha

        if gestureRecognizer.state == .ended {
            if abs(anchorPoint.y - newCenter.y) < dismissThreshold {
                // cancel
                UIView.animate(
                    withDuration: 0.5,
                    delay: 0,
                    usingSpringWithDamping: 0.9,
                    initialSpringVelocity: 0,
                    options: []) {
                    transitionView.frame = fromReferenceViewFrame
                    fromVC.view.alpha = 1.0
                    toVC.tabBarController?.tabBar.alpha = 0
                } completion: { _ in
                    toReferenceView?.isHidden = false
                    fromReferenceView.isHidden = false
                    transitionView.removeFromSuperview()
                    animator.transitionView = nil
                    transitionContext.cancelInteractiveTransition()
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                    animator.toDelegate?.transitionDidEndWith(zoomAnimator: animator)
                    animator.fromDelegate?.transitionDidEndWith(zoomAnimator: animator)
                    self.transitionContext = nil
                }

                return
            }

            // start animation
            UIView.animate(
                withDuration: .shortAnimationDuration) {
                fromVC.view.alpha = 0

                if let toReferenceViewFrame = self.toReferenceViewFrame {
                    transitionView.frame = toReferenceViewFrame
                } else {
                    transitionView.alpha = 0
                }

                transitionView.layer.contentsRect = toReferenceView?.layer.contentsRect ?? .defaultContentsRect
                transitionView.layer.cornerRadius = toReferenceView?.layer.cornerRadius ?? 0

                toVC.tabBarController?.tabBar.alpha = 1
            } completion: { _ in
                transitionView.removeFromSuperview()
                toReferenceView?.isHidden = false
                fromReferenceView.isHidden = false

                self.transitionContext?.finishInteractiveTransition()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                animator.toDelegate?.transitionDidEndWith(zoomAnimator: animator)
                animator.fromDelegate?.transitionDidEndWith(zoomAnimator: animator)
                self.transitionContext = nil
            }
        }
    }

    func backgroundAlphaFor(view: UIView, withPanningVerticalDelta verticalDelta: CGFloat) -> CGFloat {
        let startingAlpha: CGFloat = 1.0
        let finalAlpha: CGFloat = 0.0
        let totalAvailableAlpha = startingAlpha - finalAlpha

        let maximumDelta = view.bounds.height / 4.0
        let deltaAsPercentageOfMaximum = min(abs(verticalDelta) / maximumDelta, 1.0)

        return startingAlpha - (deltaAsPercentageOfMaximum * totalAvailableAlpha)
    }

    func scaleFor(view: UIView, withPanningVerticalDelta verticalDelta: CGFloat) -> CGFloat {
        let startingScale: CGFloat = 1.0
        let finalScale: CGFloat = 0.5
        let totalAvailableScale = startingScale - finalScale

        let maximumDelta = view.bounds.height / 2.0
        let deltaAsPercentageOfMaximum = min(abs(verticalDelta) / maximumDelta, 1.0)

        return startingScale - (deltaAsPercentageOfMaximum * totalAvailableScale)
    }
}

extension ZoomDismissalInteractionController: UIViewControllerInteractiveTransitioning {
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let animator = animator as? ZoomAnimator else { return }

        animator.fromDelegate?.transitionWillStartWith(zoomAnimator: animator)
        animator.toDelegate?.transitionWillStartWith(zoomAnimator: animator)

        self.transitionContext = transitionContext

        let containerView = transitionContext.containerView

        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to),
            var fromReferenceViewFrame = animator.fromDelegate?.referenceViewFrameInTransitioningView(for: animator),
            let fromReferenceView = animator.fromDelegate?.referenceView(for: animator)
            else { return }

        fromReferenceViewFrame = fromReferenceViewFrame.containsNaN ? .zero : fromReferenceViewFrame
        self.fromReferenceViewFrame = fromReferenceViewFrame
        toReferenceViewFrame = animator.toDelegate?.referenceViewFrameInTransitioningView(for: animator)

        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)

        if animator.transitionView == nil,
           let transitionView = (fromReferenceView as? ZoomAnimatableView)?.transitionView() {
            transitionView.frame = fromReferenceViewFrame
            animator.transitionView = transitionView
            containerView.addSubview(transitionView)
        }
    }
}
