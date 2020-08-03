// Copyright © 2020 Metabolist. All rights reserved.

import Combine

// This publisher acts as a `@Published private var` inside ObservableObjects that doesn't trigger `objectWillChange`

class CurrentValuePublisher<Output> {
    @Published private(set) var value: Output
    private let internalPublisher: AnyPublisher<Output, Never>

    init<P>(initial: Output, then: P) where P: Publisher, P.Output == Output, P.Failure == Never {
        value = initial
        internalPublisher = then.eraseToAnyPublisher()
        then.assign(to: &$value)
    }
}

extension CurrentValuePublisher: Publisher {
    typealias Failure = Never

    func receive<S>(subscriber: S) where S: Subscriber, Output == S.Input, S.Failure == Never {
        internalPublisher.receive(subscriber: subscriber)
    }
}
