// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

protocol StatusListService {
    var statusSections: AnyPublisher<[[Status]], Error> { get }
    var contextParent: Status? { get }
    func request(maxID: String?, minID: String?) -> AnyPublisher<Void, Error>
    func contextService(status: Status) -> ContextService
}

extension StatusListService {
    var contextParent: Status? { nil }
}
