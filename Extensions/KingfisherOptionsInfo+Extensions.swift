// Copyright © 2020 Metabolist. All rights reserved.

import struct Kingfisher.DownsamplingImageProcessor
import struct Kingfisher.FormatIndicatedCacheSerializer
import protocol Kingfisher.ImageProcessor
import struct Kingfisher.KingfisherOptionsInfo
import struct Kingfisher.RoundCornerImageProcessor
import KingfisherSwiftUI
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
