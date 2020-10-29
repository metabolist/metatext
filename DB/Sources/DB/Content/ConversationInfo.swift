// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct ConversationInfo: Codable, Hashable, FetchableRecord {
    let record: ConversationRecord
    let accountInfos: [AccountInfo]
    let lastStatusInfo: StatusInfo
}

extension ConversationInfo {
    static func addingIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == ConversationRecord {
        request.including(all: AccountInfo.addingIncludes(ConversationRecord.accounts).forKey(CodingKeys.accountInfos))
            .including(required: StatusInfo.addingIncludes(ConversationRecord.lastStatus)
                        .forKey(CodingKeys.lastStatusInfo))
    }

    static func request(_ request: QueryInterfaceRequest<ConversationRecord>) -> QueryInterfaceRequest<Self> {
        addingIncludes(request).asRequest(of: self)
    }
}
