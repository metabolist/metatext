// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

extension NSError {
    public convenience init(status: OSStatus) {
        var userInfo: [String: Any]?

        if let errorMessage = SecCopyErrorMessageString(status, nil) {
            userInfo = [NSLocalizedDescriptionKey: errorMessage]
        }

        self.init(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: userInfo)
    }
}
