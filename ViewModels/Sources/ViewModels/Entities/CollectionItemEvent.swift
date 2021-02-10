// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon
import ServiceLayer

public enum CollectionItemEvent {
    case ignorableOutput
    case refresh
    case navigation(Navigation)
    case attachment(AttachmentViewModel, StatusViewModel)
    case compose(inReplyTo: StatusViewModel?, redraft: Status?)
    case confirmDelete(StatusViewModel, redraft: Bool)
    case confirmMute(AccountViewModel)
    case confirmUnmute(AccountViewModel)
    case confirmBlock(AccountViewModel)
    case confirmUnblock(AccountViewModel)
    case confirmDomainBlock(AccountViewModel)
    case confirmDomainUnblock(AccountViewModel)
    case report(ReportViewModel)
    case share(URL)
    case accountListEdit(AccountViewModel, AccountListEdit)
}

public extension CollectionItemEvent {
    enum AccountListEdit {
        case acceptFollowRequest
        case rejectFollowRequest
    }
}
