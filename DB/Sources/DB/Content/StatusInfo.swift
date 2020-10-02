// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct StatusInfo: Codable, Hashable, FetchableRecord {
    let record: StatusRecord
    let accountInfo: AccountInfo
    let reblogAccountInfo: AccountInfo?
    let reblogRecord: StatusRecord?
}

extension StatusInfo {
    static func addingIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == StatusRecord {
        request.including(required: AccountInfo.addingIncludes(StatusRecord.account).forKey(CodingKeys.accountInfo))
            .including(optional: AccountInfo.addingIncludes(StatusRecord.reblogAccount)
                        .forKey(CodingKeys.reblogAccountInfo))
            .including(optional: StatusRecord.reblog.forKey(CodingKeys.reblogRecord))
    }

    static func request(_ request: QueryInterfaceRequest<StatusRecord>) -> QueryInterfaceRequest<Self> {
        addingIncludes(request).asRequest(of: self)
    }

    var filterableContent: String {
        (record.filterableContent + (reblogRecord?.filterableContent ?? [])).joined(separator: " ")
    }
}
