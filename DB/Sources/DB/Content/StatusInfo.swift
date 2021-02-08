// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct StatusInfo: Codable, Hashable, FetchableRecord {
    let record: StatusRecord
    let accountInfo: AccountInfo
    let relationship: Relationship?
    let reblogAccountInfo: AccountInfo?
    let reblogRecord: StatusRecord?
    let reblogRelationship: Relationship?
    let showContentToggle: StatusShowContentToggle?
    let reblogShowContentToggle: StatusShowContentToggle?
    let showAttachmentsToggle: StatusShowAttachmentsToggle?
    let reblogShowAttachmentsToggle: StatusShowAttachmentsToggle?
}

extension StatusInfo {
    static func addingIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == StatusRecord {
        addingOptionalIncludes(
            request
                .including(required: AccountInfo.addingIncludes(StatusRecord.account).forKey(CodingKeys.accountInfo)))
    }

    // Hack, remove once GRDB supports chaining a required association behind an optional association
    static func addingIncludesForNotificationInfo<T: DerivableRequest>(
        _ request: T) -> T where T.RowDecoder == StatusRecord {
        addingOptionalIncludes(
            request
                .including(optional: AccountInfo.addingIncludes(StatusRecord.account).forKey(CodingKeys.accountInfo)))
    }

    static func request(_ request: QueryInterfaceRequest<StatusRecord>) -> QueryInterfaceRequest<Self> {
        addingIncludes(request).asRequest(of: self)
    }

    var filterableContent: String {
        (record.filterableContent + (reblogRecord?.filterableContent ?? [])).joined(separator: " ")
    }

    var showContentToggled: Bool {
        showContentToggle != nil || reblogShowContentToggle != nil
    }

    var showAttachmentsToggled: Bool {
        showAttachmentsToggle != nil || reblogShowAttachmentsToggle != nil
    }
}

private extension StatusInfo {
    static func addingOptionalIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == StatusRecord {
        request.including(optional: AccountInfo.addingIncludes(StatusRecord.reblogAccount)
                            .forKey(CodingKeys.reblogAccountInfo))
            .including(optional: StatusRecord.relationship.forKey(CodingKeys.relationship))
            .including(optional: StatusRecord.reblog.forKey(CodingKeys.reblogRecord))
            .including(optional: StatusRecord.reblogRelationship.forKey(CodingKeys.reblogRelationship))
            .including(optional: StatusRecord.showContentToggle.forKey(CodingKeys.showContentToggle))
            .including(optional: StatusRecord.reblogShowContentToggle.forKey(CodingKeys.reblogShowContentToggle))
            .including(optional: StatusRecord.showAttachmentsToggle.forKey(CodingKeys.showAttachmentsToggle))
            .including(optional: StatusRecord.reblogShowAttachmentsToggle
                        .forKey(CodingKeys.reblogShowAttachmentsToggle))
    }
}
