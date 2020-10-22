// Copyright © 2020 Metabolist. All rights reserved.

import UIKit

class ZoomTransitionController: NSObject {
    var isInteractive = false

    weak var fromDelegate: ZoomAnimatorDelegate?
    weak var toDelegate: ZoomAnimatorDelegate?

    private let animator = ZoomAnimator()
    private let interactionController = ZoomDismissalInteractionController()

    func didPanWith(gestureRecognizer: UIPanGestureRecognizer) {
        interactionController.didPanWith(gestureRecognizer: gestureRecognizer)
    }
}

extension ZoomTransitionController: UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentingAnimator()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        dismissingAnimator()
    }

    func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        interactionController(animator: animator)
    }

}

extension ZoomTransitionController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        operation == .push ? presentingAnimator() : dismissingAnimator()
    }

    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning)
    -> UIViewControllerInteractiveTransitioning? {
        interactionController(animator: animator)
    }
}

private extension ZoomTransitionController {
    private func presentingAnimator() -> UIViewControllerAnimatedTransitioning {
        animator.isPresenting = true
        animator.fromDelegate = fromDelegate
        animator.toDelegate = toDelegate

        return animator
    }

    private func dismissingAnimator() -> UIViewControllerAnimatedTransitioning {
        animator.isPresenting = false
        let tmp = fromDelegate
        animator.fromDelegate = toDelegate
        animator.toDelegate = tmp

        return animator
    }

    private func interactionController(
        animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard isInteractive else { return nil }

        interactionController.animator = animator

        return interactionController
    }
}
