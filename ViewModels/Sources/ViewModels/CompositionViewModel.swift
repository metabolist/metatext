// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class CompositionViewModel: ObservableObject {
    public let composition: Composition
    @Published public private(set) var identification: Identification

    init(composition: Composition,
         identification: Identification,
         identificationPublisher: AnyPublisher<Identification, Never>) {
        self.composition = composition
        self.identification = identification
        identificationPublisher.assign(to: &$identification)
    }
}
