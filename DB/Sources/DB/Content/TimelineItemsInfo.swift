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

    static func addingIncludes<T: DerivableRequest>( _ request: T,
                                                     ordered: Bool) -> T where T.RowDecoder == TimelineRecord {
        let statusesAssociation = ordered ? TimelineRecord.orderedStatuses : TimelineRecord.statuses

        return request.including(all: StatusInfo.addingIncludes(statusesAssociation).forKey(CodingKeys.statusInfos))
            .including(all: TimelineRecord.loadMores.forKey(CodingKeys.loadMoreRecords))
            .including(optional: PinnedStatusesInfo.addingIncludes(TimelineRecord.account)
                        .forKey(CodingKeys.pinnedStatusesInfo))
    }

    static func request(_ request: QueryInterfaceRequest<TimelineRecord>,
                        ordered: Bool) -> QueryInterfaceRequest<Self> {
        addingIncludes(request, ordered: ordered).asRequest(of: self)
    }

    func items(filters: [Filter]) -> [CollectionSection] {
        let timeline = Timeline(record: timelineRecord)!
        let filterRegularExpression = filters.regularExpression(context: timeline.filterContext)
        var timelineItems = statusInfos.filtered(regularExpression: filterRegularExpression)
            .map {
                CollectionItem.status(
                    .init(info: $0),
                    .init(showContentToggled: $0.showContentToggled,
                          showAttachmentsToggled: $0.showAttachmentsToggled,
                          isReplyOutOfContext: ($0.reblogRecord ?? $0.record).inReplyToId != nil),
                    $0.reblogRelationship ?? $0.relationship)
            }

        for loadMoreRecord in loadMoreRecords {
            guard let index = timelineItems.firstIndex(where: {
                guard case let .status(status, _, _) = $0 else { return false }

                return loadMoreRecord.afterStatusId > status.id
            }) else { continue }

            timelineItems.insert(
                .loadMore(LoadMore(
                            timeline: timeline,
                            afterStatusId: loadMoreRecord.afterStatusId,
                            beforeStatusId: loadMoreRecord.beforeStatusId)),
                at: index)
        }

        if timelineRecord.profileCollection == .statuses,
           let pinnedStatusInfos = pinnedStatusesInfo?.pinnedStatusInfos {
            return [.init(items: pinnedStatusInfos.filtered(regularExpression: filterRegularExpression)
                        .map {
                            CollectionItem.status(
                                .init(info: $0),
                                .init(showContentToggled: $0.showContentToggled,
                                      showAttachmentsToggled: $0.showAttachmentsToggled,
                                      isPinned: true,
                                      isReplyOutOfContext: ($0.reblogRecord ?? $0.record).inReplyToId != nil),
                                $0.reblogRelationship ?? $0.relationship)
                        }),
                    .init(items: timelineItems)]
        } else {
            return [.init(items: timelineItems)]
        }
    }
}

extension TimelineItemsInfo.PinnedStatusesInfo {
    static func addingIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == AccountRecord {
        request.including(all: StatusInfo.addingIncludes(AccountRecord.pinnedStatuses)
                            .forKey(CodingKeys.pinnedStatusInfos))
    }
}
