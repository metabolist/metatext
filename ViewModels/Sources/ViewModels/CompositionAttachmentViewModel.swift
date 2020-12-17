// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class CompositionAttachmentViewModel: ObservableObject {
    public var attachment: Attachment

    init(attachment: Attachment) {
        self.attachment = attachment
    }
}
