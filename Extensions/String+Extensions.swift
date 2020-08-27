// Copyright © 2020 Metabolist. All rights reserved.

import UIKit

extension String {
    private static let HTTPSPrefix = "https://"

    func url() throws -> URL {
        let url: URL?

        if hasPrefix(Self.HTTPSPrefix) {
            url = URL(string: self)
        } else {
            url = URL(string: Self.HTTPSPrefix + self)
        }

        guard let validURL = url else { throw URLError(.badURL) }

        return validURL
    }

    func countEmphasizedAttributedString(count: Int, highlighted: Bool = false) -> NSAttributedString {
        let countRange = (self as NSString).range(of: String.localizedStringWithFormat("%ld", count))

        let attributed = NSMutableAttributedString(
            string: self,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: highlighted ? UIColor.tertiaryLabel : UIColor.secondaryLabel
        ])
        attributed.addAttributes(
            [
                .font: UIFont.preferredFont(forTextStyle: .headline),
                .foregroundColor: highlighted ? UIColor.secondaryLabel : UIColor.label
            ],
            range: countRange)

        return attributed
    }
}
