// Copyright © 2020 Metabolist. All rights reserved.

import Combine

class CurrentValuePublisher<Output> {
    @Published private var wrappedValue: Output

    init<P>(initial: Output, then: P) where P: Publisher, P.Output == Output, P.Failure == Never {
        wrappedValue = initial
        then.assign(to: &$wrappedValue)
    }
}

extension CurrentValuePublisher {
    var value: Output { wrappedValue }
}

extension CurrentValuePublisher: Publisher {
    typealias Failure = Never

    func receive<S>(subscriber: S) where S: Subscriber, S.Input == Output, S.Failure == Never {
        $wrappedValue.receive(subscriber: subscriber)
    }
}
