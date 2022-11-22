// Copyright © 2022 Metabolist. All rights reserved.

import UIKit

// ref: https://stackoverflow.com/a/60598558/3797903
class SwipeableNavigationController: UINavigationController {
    private lazy var fullWidthBackGestureRecognizer = UIPanGestureRecognizer()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFullWidthBackGesture()
    }

    private func setupFullWidthBackGesture() {
        guard let targets = interactivePopGestureRecognizer?.value(forKey: "targets") else { return }

        // have fullWidthBackGestureRecognizer execute the same handler as interactivePopGestureRecognizer
        fullWidthBackGestureRecognizer.setValue(targets, forKey: "targets")
        fullWidthBackGestureRecognizer.delegate = self

        view.addGestureRecognizer(fullWidthBackGestureRecognizer)
    }
}

extension SwipeableNavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        interactivePopGestureRecognizer?.isEnabled == true && viewControllers.count > 1
    }
}
