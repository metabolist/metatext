// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct ContextItemsInfo: Codable, Hashable, FetchableRecord {
    let parent: StatusInfo
    let ancestors: [StatusInfo]
    let descendants: [StatusInfo]
}

extension ContextItemsInfo {
    static func addingIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == StatusRecord {
        StatusInfo.addingIncludes(request)
            .including(all: StatusInfo.addingIncludes(StatusRecord.ancestors).forKey(CodingKeys.ancestors))
            .including(all: StatusInfo.addingIncludes(StatusRecord.descendants).forKey(CodingKeys.descendants))
    }

    static func request(_ request: QueryInterfaceRequest<StatusRecord>) -> QueryInterfaceRequest<Self> {
        addingIncludes(request).asRequest(of: self)
    }

    func items(filters: [Filter]) -> [[CollectionItem]] {
        let regularExpression = filters.regularExpression(context: .thread)

        return [ancestors, [parent], descendants].map { section in
            section.filtered(regularExpression: regularExpression)
                .enumerated()
                .map { index, statusInfo in
                    let isReplyInContext = index > 0
                        && section[index - 1].record.id == statusInfo.record.inReplyToId
                    let hasReplyFollowing = section.count > index + 1
                        && section[index + 1].record.inReplyToId == statusInfo.record.id

                    return .status(.init(status: .init(info: statusInfo),
                                         isContextParent: statusInfo.record.id == parent.record.id,
                                         isReplyInContext: isReplyInContext,
                                         hasReplyFollowing: hasReplyFollowing))
                }
        }
    }
}
