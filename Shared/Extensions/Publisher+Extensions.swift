// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

extension Publisher {
    func assignErrorsToAlertItem<Root: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<Root, AlertItem?>,
        on object: Root) -> AnyPublisher<Output, Never> {
        self.catch { [weak object] error -> Empty<Output, Never> in
            DispatchQueue.main.async {
                object?[keyPath: keyPath] = AlertItem(error: error)
            }

            return Empty()
        }
        .eraseToAnyPublisher()
    }

    func continuingIfWeakReferenceIsStillAlive<T: AnyObject>(to object: T) -> AnyPublisher<(Output, T), Error> {
        tryMap { [weak object] in
            guard let object = object else { throw WeakReferenceError.deallocated }

            return ($0, object)
        }
        .tryCatch { error -> Empty<(Output, T), Never> in
            if case WeakReferenceError.deallocated = error {
                return Empty()
            }

            throw error
        }
        .eraseToAnyPublisher()
    }
}

private enum WeakReferenceError: Error {
    case deallocated
}
