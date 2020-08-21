// Copyright © 2020 Metabolist. All rights reserved.

import UIKit

extension UIColor {
    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            self.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
