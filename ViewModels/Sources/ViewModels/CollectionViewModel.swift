// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation

public protocol CollectionViewModel {
    var collectionItems: AnyPublisher<[[CollectionItem]], Never> { get }
    var title: AnyPublisher<String?, Never> { get }
    var alertItems: AnyPublisher<AlertItem, Never> { get }
    var loading: AnyPublisher<Bool, Never> { get }
    var navigationEvents: AnyPublisher<NavigationEvent, Never> { get }
    var nextPageMaxID: String? { get }
    var maintainScrollPositionOfItem: CollectionItem? { get }
    func request(maxID: String?, minID: String?)
    func itemSelected(_ item: CollectionItem)
    func canSelect(item: CollectionItem) -> Bool
    func viewModel(item: CollectionItem) -> Any?
}
