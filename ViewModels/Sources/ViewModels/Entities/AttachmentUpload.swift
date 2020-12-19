// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct AttachmentUpload: Hashable {
    public let progress: Progress
    public let data: Data
    public let mimeType: String
}
