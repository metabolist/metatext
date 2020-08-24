// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

protocol StatusListService {
    var statusSections: AnyPublisher<[[Status]], Error> { get }
    var contextParentID: String? { get }
    func isPinned(status: Status) -> Bool
    func isReplyInContext(status: Status) -> Bool
    func hasReplyFollowing(status: Status) -> Bool
    func request(maxID: String?, minID: String?) -> AnyPublisher<Void, Error>
    func statusService(status: Status) -> StatusService
    func contextService(status: Status) -> ContextService
}

extension StatusListService {
    var contextParentID: String? { nil }

    func isPinned(status: Status) -> Bool { false }

    func isReplyInContext(status: Status) -> Bool { false }

    func hasReplyFollowing(status: Status) -> Bool { false }
}
