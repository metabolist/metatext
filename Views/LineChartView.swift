// Copyright © 2021 Metabolist. All rights reserved.

import UIKit

final class LineChartView: UIView {
    var values = [Int]() {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        UIView.layoutFittingExpandedSize
    }

    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()

        path.lineWidth = Self.lineWidth
        path.lineCapStyle = .round

        let valueCount = values.count

        guard valueCount > 0, let maxValue = values.max() else { return }

        for (index, value) in values.enumerated() {
            let x = CGFloat(index) / CGFloat(valueCount) * rect.width
            let y = rect.height - CGFloat(value) / max(CGFloat(maxValue), CGFloat(0).nextUp) * rect.height
            let point = CGPoint(
                x: min(max(x, Self.lineWidth / 2), rect.width - Self.lineWidth / 2),
                y: min(max(y, Self.lineWidth / 2), rect.height - Self.lineWidth / 2))

            if index > 0 {
                path.addLine(to: point)
            }

            path.move(to: point)
        }

        path.close()
        UIColor.link.setStroke()
        path.stroke()
    }
}

private extension LineChartView {
    static let lineWidth: CGFloat = 2
}
