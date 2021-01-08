// Copyright © 2020 Metabolist. All rights reserved.

import Kingfisher
import SwiftUI

extension KingfisherOptionsInfo {
    static func downsampled(size: CGSize, scaleFactor: CGFloat, rounded: Bool = true) -> Self {
        var processor: ImageProcessor = DownsamplingImageProcessor(size: size)

        if rounded {
            processor = processor.append(another: RoundCornerImageProcessor(radius: .widthFraction(0.5)))
        }

        return [
            .processor(processor),
            .scaleFactor(scaleFactor),
            .cacheOriginalImage,
            .cacheSerializer(FormatIndicatedCacheSerializer.png)
        ]
    }

    static func downsampled(dimension: CGFloat, scaleFactor: CGFloat, rounded: Bool = true) -> Self {
        downsampled(size: CGSize(width: dimension, height: dimension), scaleFactor: scaleFactor, rounded: rounded)
    }
}

extension KFOptionSetter {
    func downsampled(size: CGSize, scaleFactor: CGFloat, rounded: Bool = true) -> Self {
        var processor: ImageProcessor = DownsamplingImageProcessor(size: size)

        if rounded {
            processor = processor.append(another: RoundCornerImageProcessor(radius: .widthFraction(0.5)))
        }
        options.processor = processor
        options.scaleFactor = scaleFactor
        options.cacheOriginalImage = true
        options.cacheSerializer = FormatIndicatedCacheSerializer.png

        return self
    }

    func downsampled(dimension: CGFloat, scaleFactor: CGFloat, rounded: Bool = true) -> Self {
        downsampled(size: CGSize(width: dimension, height: dimension), scaleFactor: scaleFactor, rounded: rounded)
    }
}
