// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation

extension Publisher {
    func assignErrorsToAlertItem<Root: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<Root, AlertItem?>,
        on object: Root) -> AnyPublisher<Output, Never> {
        self.catch { [weak object] error -> Empty<Output, Never> in
            if let object = object {
                DispatchQueue.main.async {
                    object[keyPath: keyPath] = AlertItem(error: error)
                }
            }

            return Empty()
        }
        .eraseToAnyPublisher()
    }
}
