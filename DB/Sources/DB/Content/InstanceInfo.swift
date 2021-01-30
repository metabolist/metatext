// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct InstanceInfo: Codable, Hashable, FetchableRecord {
    let record: InstanceRecord
    let contactAccountInfo: AccountInfo?
}

extension InstanceInfo {
    static func addingIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == InstanceRecord {
        request.including(optional: AccountInfo.addingIncludes(InstanceRecord.contactAccount)
                            .forKey(CodingKeys.contactAccountInfo))
    }

    static func request(_ request: QueryInterfaceRequest<InstanceRecord>) -> QueryInterfaceRequest<Self> {
        addingIncludes(request).asRequest(of: self)
    }
}
