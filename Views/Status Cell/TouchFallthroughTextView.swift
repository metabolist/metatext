// Copyright © 2020 Metabolist. All rights reserved.

import UIKit

class TouchFallthroughTextView: UITextView {
    var shouldFallthrough: Bool = true

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        initializationActions()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initializationActions()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        shouldFallthrough ? urlAndRect(at: point) != nil : super.point(inside: point, with: event)
    }

    override var selectedTextRange: UITextRange? {
        get { shouldFallthrough ? nil : super.selectedTextRange }
        set {
            if !shouldFallthrough {
                super.selectedTextRange = newValue
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        return text == "" ? .zero : super.intrinsicContentSize
    }

    func urlAndRect(at point: CGPoint) -> (URL, CGRect)? {
        guard
            let pos = closestPosition(to: point),
            let range = tokenizer.rangeEnclosingPosition(
                pos, with: .character,
                inDirection: UITextDirection.layout(.left))
            else { return nil }

        let urlAtPointIndex = offset(from: beginningOfDocument, to: range.start)

        guard let url = attributedText.attribute(
                .link, at: offset(from: beginningOfDocument, to: range.start),
                effectiveRange: nil) as? URL
        else { return nil }

        let maxLength = attributedText.length
        var min = urlAtPointIndex
        var max = urlAtPointIndex

        attributedText.enumerateAttribute(
            .link,
            in: NSRange(location: 0, length: urlAtPointIndex),
            options: .reverse) { attribute, range, stop in
                if let attributeURL = attribute as? URL, attributeURL == url, min > 0 {
                    min = range.location
                } else {
                    stop.pointee = true
                }
        }

        attributedText.enumerateAttribute(
            .link,
            in: NSRange(location: urlAtPointIndex, length: maxLength - urlAtPointIndex),
            options: []) { attribute, range, stop in
                if let attributeURL = attribute as? URL, attributeURL == url, max < maxLength {
                    max = range.location + range.length
                } else {
                    stop.pointee = true
                }
        }

        var urlRect = CGRect.zero

        layoutManager.enumerateEnclosingRects(
            forGlyphRange: NSRange(location: min, length: max - min),
            withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0),
            in: textContainer) { rect, _ in
                if urlRect.origin == .zero {
                    urlRect.origin = rect.origin
                }

                urlRect = urlRect.union(rect)
        }

        return (url, urlRect)
    }
}

private extension TouchFallthroughTextView {
    private func initializationActions() {
        textDragInteraction?.isEnabled = false
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        linkTextAttributes = [.foregroundColor: tintColor as Any, .underlineColor: UIColor.clear]
    }
}
