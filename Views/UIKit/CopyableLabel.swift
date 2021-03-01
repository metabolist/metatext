// Copyright © 2021 Metabolist. All rights reserved.

import UIKit

final class CopyableLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(showCopyMenu(sender:))))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeFirstResponder: Bool { true }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        action == #selector(UIResponderStandardEditActions.copy(_:))
    }

    override func copy(_ sender: Any?) {
        UIPasteboard.general.string = text
    }
}

private extension CopyableLabel {
    @objc func showCopyMenu(sender: Any) {
        becomeFirstResponder()

        let menuController = UIMenuController.shared

        if !menuController.isMenuVisible {
            menuController.showMenu(from: self, rect: bounds)
        }
    }
}
