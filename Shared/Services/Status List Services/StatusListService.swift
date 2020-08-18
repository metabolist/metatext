// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

protocol StatusListService {
    var statusSections: AnyPublisher<[[Status]], Error> { get }
    func request(maxID: String?, minID: String?) -> AnyPublisher<Void, Error>
}
