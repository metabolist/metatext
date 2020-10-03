// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct TimelineItemsInfo: Codable, Hashable, FetchableRecord {
    let timelineRecord: TimelineRecord
    let statusInfos: [StatusInfo]
    let pinnedStatusesInfo: PinnedStatusesInfo?
    let loadMoreRecords: [LoadMoreRecord]
}

extension TimelineItemsInfo {
    struct PinnedStatusesInfo: Codable, Hashable, FetchableRecord {
        let accountRecord: AccountRecord
        let pinnedStatusInfos: [StatusInfo]
    }

    static func addingIncludes<T: DerivableRequest>( _ request: T) -> T where T.RowDecoder == TimelineRecord {
        request.including(all: StatusInfo.addingIncludes(TimelineRecord.statuses).forKey(CodingKeys.statusInfos))
            .including(all: TimelineRecord.loadMores.forKey(CodingKeys.loadMoreRecords))
            .including(optional: PinnedStatusesInfo.addingIncludes(TimelineRecord.account)
                        .forKey(CodingKeys.pinnedStatusesInfo))
    }

    static func request(_ request: QueryInterfaceRequest<TimelineRecord>) -> QueryInterfaceRequest<Self> {
        addingIncludes(request).asRequest(of: self)
    }

    func items(filters: [Filter]) -> [[Timeline.Item]] {
        let timeline = Timeline(record: timelineRecord)!
        let filterRegularExpression = filters.regularExpression(context: timeline.filterContext)
        var timelineItems = statusInfos.filtered(regularExpression: filterRegularExpression)
            .map { Timeline.Item.status(.init(status: .init(info: $0))) }

        for loadMoreRecord in loadMoreRecords {
            guard let index = timelineItems.firstIndex(where: {
                guard case let .status(configuration) = $0 else { return false }

                return loadMoreRecord.afterStatusId > configuration.status.id
            }) else { continue }

            timelineItems.insert(
                .loadMore(LoadMore(timeline: timeline, afterStatusId: loadMoreRecord.afterStatusId)),
                at: index)
        }

        if let pinnedStatusInfos = pinnedStatusesInfo?.pinnedStatusInfos {
            return [pinnedStatusInfos.filtered(regularExpression: filterRegularExpression)
                        .map { Timeline.Item.status(.init(status: .init(info: $0), pinned: true)) },
                    timelineItems]
        } else {
            return [timelineItems]
        }
    }
}

extension TimelineItemsInfo.PinnedStatusesInfo {
    static func addingIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == AccountRecord {
        request.including(all: StatusInfo.addingIncludes(AccountRecord.pinnedStatuses)
                            .forKey(CodingKeys.pinnedStatusInfos))
    }
}
