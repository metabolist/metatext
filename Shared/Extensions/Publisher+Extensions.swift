// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

extension Publisher {
    func assignErrorsToAlertItem<Root>(
        to keyPath: ReferenceWritableKeyPath<Root, AlertItem?>,
        on object: Root) -> AnyPublisher<Output, Never> {
        self.catch { error -> AnyPublisher<Output, Never> in
            DispatchQueue.main.async {
                object[keyPath: keyPath] = AlertItem(error: error)
            }

            return Empty().eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}
