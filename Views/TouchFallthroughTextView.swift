// Copyright © 2020 Metabolist. All rights reserved.

import UIKit

final class TouchFallthroughTextView: UITextView {
    var shouldFallthrough: Bool = true

    private var linkHighlightView: UIView?

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)

        clipsToBounds = false
        textDragInteraction?.isEnabled = false
        isEditable = false
        textContainerInset = .zero
        self.textContainer.lineFragmentPadding = 0
        linkTextAttributes = [.foregroundColor: tintColor as Any, .underlineColor: UIColor.clear]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        shouldFallthrough ? urlAndRect(at: point) != nil : super.point(inside: point, with: event)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard let touch = touches.first,
              let (_, rect) = urlAndRect(at: touch.location(in: self)) else {
            return
        }

        let linkHighlightView = UIView(frame: rect)

        self.linkHighlightView = linkHighlightView
        linkHighlightView.transform = Self.linkHighlightViewTransform
        linkHighlightView.layer.cornerRadius = .defaultCornerRadius
        linkHighlightView.backgroundColor = .secondarySystemBackground
        insertSubview(linkHighlightView, at: 0)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        removeLinkHighlightView()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)

        removeLinkHighlightView()
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
        return text.isEmpty ? .zero : super.intrinsicContentSize
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
    static let linkHighlightViewTransform = CGAffineTransform(scaleX: 1.1, y: 1.1)

    func removeLinkHighlightView() {
        UIView.animate(withDuration: .defaultAnimationDuration) {
            self.linkHighlightView?.alpha = 0
        } completion: { _ in
            self.linkHighlightView?.removeFromSuperview()
            self.linkHighlightView = nil
        }
    }
}
