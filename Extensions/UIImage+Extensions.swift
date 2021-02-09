// Copyright © 2021 Metabolist. All rights reserved.

import UIKit

extension UIImage {
    var withProperOrientation: UIImage? {
        guard imageOrientation != .up else { return self }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)

        draw(in: .init(origin: .zero, size: size))

        let image = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return image
    }
}
