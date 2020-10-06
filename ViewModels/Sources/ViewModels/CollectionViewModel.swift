// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation

public protocol CollectionViewModel {
    var sections: AnyPublisher<[[CollectionItemIdentifier]], Never> { get }
    var title: AnyPublisher<String, Never> { get }
    var alertItems: AnyPublisher<AlertItem, Never> { get }
    var loading: AnyPublisher<Bool, Never> { get }
    var navigationEvents: AnyPublisher<NavigationEvent, Never> { get }
    var nextPageMaxId: String? { get }
    var maintainScrollPositionOfItem: CollectionItemIdentifier? { get }
    func request(maxId: String?, minId: String?)
    func viewedAtTop(indexPath: IndexPath)
    func select(indexPath: IndexPath)
    func canSelect(indexPath: IndexPath) -> Bool
    func viewModel(indexPath: IndexPath) -> CollectionItemViewModel
}
