// Copyright © 2021 Metabolist. All rights reserved.

import UIKit

extension UITextInput {
    var textToSelectedRange: String? {
        guard let selectedRange = selectedTextRange,
              let range = textRange(from: beginningOfDocument, to: selectedRange.end)
        else { return nil }

        return text(in: range)
    }
}
