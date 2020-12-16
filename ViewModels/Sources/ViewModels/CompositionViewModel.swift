// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class CompositionViewModel: ObservableObject {
    public let composition: Composition
    @Published public private(set) var isPostable = false
    @Published public private(set) var identification: Identification

    private let eventsSubject: PassthroughSubject<Event, Never>

    init(composition: Composition,
         identification: Identification,
         identificationPublisher: AnyPublisher<Identification, Never>,
         eventsSubject: PassthroughSubject<Event, Never>) {
        self.composition = composition
        self.identification = identification
        self.eventsSubject = eventsSubject
        identificationPublisher.assign(to: &$identification)
        composition.$text.map { !$0.isEmpty }.removeDuplicates().assign(to: &$isPostable)
    }
}

public extension CompositionViewModel {
    enum Event {
        case insertAfter(CompositionViewModel)
        case presentMediaPicker(CompositionViewModel)
        case attach(itemProvider: NSItemProvider, viewModel: CompositionViewModel)
    }

    func presentMediaPicker() {
        eventsSubject.send(.presentMediaPicker(self))
    }

    func insert() {
        eventsSubject.send(.insertAfter(self))
    }

    func attach(itemProvider: NSItemProvider) {
        eventsSubject.send(.attach(itemProvider: itemProvider, viewModel: self))
    }
}
