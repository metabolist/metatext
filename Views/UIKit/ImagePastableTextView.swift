// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import UIKit

final class ImagePastableTextView: UITextView {
    var canPasteImage = true
    private(set) lazy var pastedImagesPublisher: AnyPublisher<UIImage, Never> =
        pastedImagesSubject.eraseToAnyPublisher()

    private let pastedImagesSubject = PassthroughSubject<UIImage, Never>()

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)) {
            return UIPasteboard.general.hasStrings || (UIPasteboard.general.hasImages && canPasteImage)
        }

        return super.canPerformAction(action, withSender: sender)
    }

    override func paste(_ sender: Any?) {
        if UIPasteboard.general.hasImages, let image = UIPasteboard.general.image {
            pastedImagesSubject.send(image)
        } else {
            super.paste(sender)
        }
    }
}
