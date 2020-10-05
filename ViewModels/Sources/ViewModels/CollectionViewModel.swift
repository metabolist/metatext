// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation

public protocol CollectionViewModel {
    var sections: AnyPublisher<[[CollectionItemIdentifier]], Never> { get }
    var title: AnyPublisher<String?, Never> { get }
    var alertItems: AnyPublisher<AlertItem, Never> { get }
    var loading: AnyPublisher<Bool, Never> { get }
    var navigationEvents: AnyPublisher<NavigationEvent, Never> { get }
    var nextPageMaxID: String? { get }
    var maintainScrollPositionOfItem: CollectionItemIdentifier? { get }
    func request(maxID: String?, minID: String?)
    func select(identifier: CollectionItemIdentifier)
    func canSelect(identifier: CollectionItemIdentifier) -> Bool
    func viewModel(identifier: CollectionItemIdentifier) -> CollectionItemViewModel?
}
