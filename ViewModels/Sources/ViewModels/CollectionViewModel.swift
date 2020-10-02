// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation

public protocol CollectionViewModel {
    var collectionItems: AnyPublisher<[[CollectionItemIdentifier]], Never> { get }
    var title: AnyPublisher<String?, Never> { get }
    var alertItems: AnyPublisher<AlertItem, Never> { get }
    var loading: AnyPublisher<Bool, Never> { get }
    var navigationEvents: AnyPublisher<NavigationEvent, Never> { get }
    var nextPageMaxID: String? { get }
    var maintainScrollPositionOfItem: CollectionItemIdentifier? { get }
    func request(maxID: String?, minID: String?)
    func itemSelected(_ item: CollectionItemIdentifier)
    func canSelect(item: CollectionItemIdentifier) -> Bool
    func viewModel(item: CollectionItemIdentifier) -> Any?
}
