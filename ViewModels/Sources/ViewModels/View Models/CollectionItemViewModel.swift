// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation

public protocol CollectionItemViewModel {
    var events: AnyPublisher<AnyPublisher<CollectionItemEvent, Error>, Never> { get }
}
